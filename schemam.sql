-- Run this in Supabase SQL Editor using the project owner account.
-- Appointment details are private: only authenticated users with app_metadata.role = 'admin' can read/update.
create extension if not exists pgcrypto;

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_name text not null check (char_length(trim(patient_name)) between 2 and 100),
  phone text not null check (phone ~ '^[6-9][0-9]{9}$'),
  appointment_date date not null,
  appointment_time text not null check (appointment_time in ('09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30','15:00','15:30','16:00','16:30','17:00','17:30','18:00')),
  reason text check (reason is null or char_length(reason) <= 500),
  status text not null default 'pending' check (status in ('pending','accepted','rejected')),
  created_at timestamptz not null default now()
);

alter table public.appointments enable row level security;

drop policy if exists "Anyone can request appointment" on public.appointments;
create policy "Anyone can request appointment"
on public.appointments for insert to anon, authenticated
with check (
  status = 'pending'
  and appointment_date >= current_date
);

drop policy if exists "Admins can view appointments" on public.appointments;
create policy "Admins can view appointments"
on public.appointments for select to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Admins can update appointments" on public.appointments;
create policy "Admins can update appointments"
on public.appointments for update to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- IMPORTANT:
-- 1. In Supabase Authentication, create the admin user manually; do not enable public sign-up for admin.
-- 2. In that user's app_metadata, set {"role":"admin"} using the Supabase dashboard / trusted server.
-- 3. Never put the Supabase service_role/secret key in this app.
-- 4. Test policies with a non-admin account before launch.
