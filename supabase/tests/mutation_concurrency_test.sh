#!/bin/bash
# Zenward Platform — genuine concurrent-mutation test (P1-E2-S2, work item
# concurrency requirement: "actually concurrent, not merely sequential").
#
# A single sequential .sql script cannot demonstrate real lock contention —
# every statement in it runs one after another on one connection. This
# script drives two SEPARATE psql connections (two OS processes) against
# the SAME Trip at overlapping wall-clock times, and proves genuine
# row-level serialization by timing, not just by inspecting the final
# state (which could look correct by coincidence even with a broken lock).
#
# Scenario: Trip E2 starts unassigned.
#   Session A: opens a transaction, locks the Trip row (FOR UPDATE), holds
#     it for ~2 seconds (simulating a real in-flight mutation), then calls
#     assign_trip(Driver A1) and commits.
#   Session B: launched ~0.3s after A (while A is still holding the lock),
#     calls assign_trip(Driver A2) on the SAME Trip.
#
# Expected: Session B's call BLOCKS on the Trip row lock until A commits
# (observable as B's wall-clock duration being close to A's hold time, not
# near-instant), and once unblocked, B's own read of the Trip's assignment
# state is up to date (sees A's just-committed assignment), so B correctly
# rejects with assignment_conflict (ZW005) rather than creating a second
# active assignment. Exactly one active trip_assignments row exists at the
# end, for Driver A1 — proving the row lock, not merely the partial unique
# index, is what prevented the race (the unique index is the documented,
# separately-tested last-resort backstop — see RLS test Y).
#
# Run with:
#   bash supabase/tests/mutation_concurrency_test.sh

set -euo pipefail

TRIP='90000000-0000-0000-0000-0000000000e2'
ORG='10000000-0000-0000-0000-0000000000a1'
PASSENGER='40000000-0000-0000-0000-0000000000a1'
DISPATCHER='20000000-0000-0000-0000-0000000000a2'
DRIVER_A1='30000000-0000-0000-0000-0000000000a1'
DRIVER_A2='30000000-0000-0000-0000-0000000000a2'

echo "=== Fixture: fresh unassigned Trip E2 (re-runnable: clears any assignment from a prior run) ==="
docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<SQL
insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description)
values ('$TRIP', '$ORG', '$PASSENGER', 'scheduled', 'Concurrency test E2', 'Concurrency test E2')
on conflict (id) do nothing;
delete from public.trip_assignments where trip_id = '$TRIP';
SQL

echo "=== Launching Session A (holds the Trip row lock ~2s, then assign_trip Driver A1) ==="
docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -v ON_ERROR_STOP=1 > /tmp/concurrency_session_a.log 2>&1 <<SQL &
SET ROLE authenticated;
SET request.jwt.claim.sub = '$DISPATCHER';
BEGIN;
SELECT id FROM public.trips WHERE id = '$TRIP' FOR UPDATE;
SELECT pg_sleep(2);
SELECT assign_trip('$TRIP', '$DRIVER_A1');
COMMIT;
SQL
PID_A=$!

sleep 0.3
echo "=== Launching Session B (should block on A's lock, then observe A's committed assignment) ==="
START_B=$(date +%s.%N)
set +e
docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -v ON_ERROR_STOP=1 > /tmp/concurrency_session_b.log 2>&1 <<SQL
SET ROLE authenticated;
SET request.jwt.claim.sub = '$DISPATCHER';
SELECT assign_trip('$TRIP', '$DRIVER_A2');
SQL
B_EXIT=$?
set -e
END_B=$(date +%s.%N)
ELAPSED_B=$(echo "$END_B - $START_B" | bc)

set +e
wait $PID_A
set -e

echo "--- Session A log ---"
cat /tmp/concurrency_session_a.log
echo "--- Session B log (exit=$B_EXIT, elapsed=${ELAPSED_B}s) ---"
cat /tmp/concurrency_session_b.log

echo "=== Verifying final state ==="
docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<SQL
select count(*) as active_assignments, string_agg(driver_id::text, ',') as drivers
from public.trip_assignments where trip_id = '$TRIP' and ended_at is null;
SQL

echo "=== Verdict ==="
ELAPSED_OK=$(echo "$ELAPSED_B > 1.0" | bc)
B_CONFLICT=$(grep -c "assignment_conflict" /tmp/concurrency_session_b.log || true)
if [ "$ELAPSED_OK" = "1" ] && [ "$B_CONFLICT" -ge "1" ]; then
  echo "TEST CONCURRENCY-1: PASS (Session B blocked for ${ELAPSED_B}s on the Trip row lock, then correctly saw Session A's already-committed assignment and rejected with assignment_conflict — genuine row-level serialization, not a lucky interleaving)"
else
  echo "TEST CONCURRENCY-1: FAIL (elapsed_B=${ELAPSED_B}s, B_conflict_lines=${B_CONFLICT} — expected elapsed > 1.0s and at least one assignment_conflict)"
fi
