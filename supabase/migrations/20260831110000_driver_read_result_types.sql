-- P1-E2-S3 — Secure Read Models & Driver Minimum-Necessary Projection.
--
-- Composite return types for the Driver read API
-- (20260831110100_driver_read_api.sql). Explicit named fields only — never
-- a canonical table rowtype (RETURNS trips / RETURNS passengers etc.),
-- because the whole point of this phase is that the projection's shape
-- IS the security boundary: a future column added to trips/passengers
-- must never automatically appear in a Driver-facing response.

create type public.driver_profile_result as (
  driver_id uuid,
  organization_id uuid,
  organization_name text,
  display_name text,
  phone text,
  status text
);

comment on type public.driver_profile_result is
  'Return shape for driver_get_profile. Own-data only (the calling Driver''s own row) — not a projection of anyone else''s data, so no Passenger-style minimization tension exists here beyond the usual explicit-field discipline.';

create type public.driver_active_trip_summary as (
  trip_id uuid,
  assignment_id uuid,
  state text,
  scheduled_pickup_at timestamptz,
  appointment_at timestamptz,
  pickup_description text,
  destination_description text,
  passenger_display_name text,
  vehicle_label text,
  vehicle_status text
);

comment on type public.driver_active_trip_summary is
  'Return shape for driver_list_active_trips — deliberately narrower than driver_trip_detail_result (docs/security/driver-data-minimization.md). No passenger phone, no notes, no assistance/instructions text.';

create type public.driver_trip_detail_result as (
  trip_id uuid,
  assignment_id uuid,
  state text,
  scheduled_pickup_at timestamptz,
  appointment_at timestamptz,
  pickup_description text,
  destination_description text,
  passenger_display_name text,
  passenger_phone text,
  assistance_notes text,
  instructions text,
  vehicle_label text,
  vehicle_status text,
  driver_notes jsonb
);

comment on type public.driver_trip_detail_result is
  'Return shape for driver_get_trip_detail — the controlled minimum-necessary projection for a Trip the caller CURRENTLY actively holds (docs/security/driver-data-minimization.md). driver_notes is a jsonb array of explicitly-constructed {id, body, created_at} objects (visibility=driver_visible only, via jsonb_build_object — never to_jsonb/row_to_json of the trip_notes row).';

create type public.driver_trip_history_entry as (
  trip_id uuid,
  scheduled_pickup_at timestamptz,
  assignment_started_at timestamptz,
  assignment_ended_at timestamptz,
  end_reason text,
  trip_outcome text
);

comment on type public.driver_trip_history_entry is
  'Return shape for driver_list_trip_history — materially more restricted than driver_trip_detail_result (docs/security/driver-data-minimization.md §History redaction). No passenger identity, no phone, no notes, no pickup/destination text, no requester data. trip_outcome is populated only when the Trip reached a terminal state (completed/cancelled/no_show); null otherwise, so a past assignment never reveals what a DIFFERENT, later Driver did on the same Trip after this one''s assignment ended.';
