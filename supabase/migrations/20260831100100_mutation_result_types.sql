-- P1-E2-S2 — Controlled Mutation & Transaction Boundary.
--
-- Composite return types for the controlled-mutation RPCs
-- (20260831100200_controlled_trip_mutations.sql). PostgREST serializes a
-- function's composite return type to a single JSON object automatically,
-- giving every mutation RPC a small, typed, self-documenting result
-- instead of an ad hoc jsonb blob — see docs/data/mutation-api.md for the
-- full contract.
--
-- `changed` is the idempotency signal every caller must check: false means
-- the call was a safe no-op (the requested end state already held), true
-- means this call actually performed the mutation.

create type public.trip_transition_result as (
  trip_id uuid,
  previous_state text,
  current_state text,
  changed boolean
);

comment on type public.trip_transition_result is
  'Return shape for every Trip lifecycle-transition RPC (the 6 driver_* functions, cancel_trip, record_no_show). previous_state/current_state describe the state actually observed at the end of the call, not merely the caller''s request — on an idempotent no-op they are equal.';

create type public.trip_assignment_result as (
  trip_id uuid,
  assignment_id uuid,
  driver_id uuid,
  vehicle_id uuid,
  changed boolean
);

comment on type public.trip_assignment_result is
  'Return shape for assign_trip and reassign_trip. assignment_id identifies the (possibly newly created) currently-active trip_assignments row.';
