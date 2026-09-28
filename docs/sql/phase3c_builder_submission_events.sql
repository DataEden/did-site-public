-- ============================================================
-- Phase 3C: Builder Showcase operational event log
-- ============================================================
create table if not exists public.builder_submission_events (
    id uuid primary key default gen_random_uuid(),

    submission_id uuid references public.builder_project_submissions(id)
        on delete cascade,

    builder_project_id uuid references public.builder_projects(id)
        on delete set null,

    event_type text not null,
    event_message text,

    old_status text,
    new_status text,

    metadata jsonb not null default '{}'::jsonb,

    created_by text not null default 'local_admin',
    created_at timestamptz not null default now()
);
--Indexes
create index if not exists idx_builder_submission_events_submission_id
on public.builder_submission_events(submission_id);

create index if not exists idx_builder_submission_events_builder_project_id
on public.builder_submission_events(builder_project_id);

create index if not exists idx_builder_submission_events_event_type
on public.builder_submission_events(event_type);

create index if not exists idx_builder_submission_events_created_at
on public.builder_submission_events(created_at desc);

--Useful Dashboard Queries:
select
    e.id,
    e.submission_id,
    s.project_title,
    e.builder_project_id,
    e.event_type,
    e.event_message,
    e.old_status,
    e.new_status,
    e.created_by,
    e.created_at,
    e.metadata      
from public.builder_submission_events e
left join public.builder_project_submissions s
    on e.submission_id = s.id
order by e.created_at desc
limit 25;

--Granting insertion + select service role 
grant usage on schema public to service_role;

grant insert, select
on public.builder_submission_events
to service_role;

--Inspect RLS status check
Select
    schemaname,
    tablename,
    rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'builder_project_submissions',
    'builder_projects',
    'builder_submission_events'
  )
order by tablename;

--Inspect grants
select
    grantee,
    table_schema,
    table_name,
    privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'builder_project_submissions',
    'builder_projects',
    'builder_submission_events'
  )
order by table_name, grantee, privilege_type;

--begin;

-- ------------------------------------------------------------
-- 1. Enable RLS on workflow/admin tables in public schema
-- ------------------------------------------------------------
alter table public.builder_projects enable row level security;
alter table public.builder_submission_events enable row level security;

-- builder_project_submissions already has RLS enabled,
-- but this is safe if you want the SQL file to be idempotent.
alter table public.builder_project_submissions enable row level security;

-- ------------------------------------------------------------
-- 2. Remove all direct table privileges from public-facing roles
-- ------------------------------------------------------------
revoke all privileges on table public.builder_project_submissions
from anon, authenticated;

revoke all privileges on table public.builder_projects
from anon, authenticated;

revoke all privileges on table public.builder_submission_events
from anon, authenticated;

-- ------------------------------------------------------------
-- 3. Keep service_role privileges intentional/minimal
-- ------------------------------------------------------------

-- Submissions:
-- Edge Function needs SELECT for duplicate checks and INSERT for new submissions.
-- UPDATE is useful for admin/server workflows.
grant select, insert, update
on table public.builder_project_submissions
to service_role;

-- Builder projects:
-- Server/admin workflows may need SELECT/INSERT/UPDATE for promotion/export.
grant select, insert, update
on table public.builder_projects
to service_role;

-- Events:
-- Edge Function and admin scripts need INSERT.
-- SELECT is needed because your helper inserts and returns/selects the event id.
grant select, insert
on table public.builder_submission_events
to service_role;

-- ------------------------------------------------------------
-- 4. Remove unnecessary high-risk service_role privileges
-- ------------------------------------------------------------
revoke truncate, trigger, references
on table public.builder_project_submissions
from service_role;

revoke truncate, trigger, references
on table public.builder_projects
from service_role;

revoke truncate, trigger, references
on table public.builder_submission_events
from service_role;

commit;


--Some tracking columns
alter table public.builder_project_submissions
add column if not exists readme_checked_at timestamptz;

alter table public.builder_project_submissions
add column if not exists readme_check_notes text;

alter table public.builder_project_submissions
add column if not exists readme_check_metadata jsonb not null default '{}'::jsonb;


--Check current allowed values
select
    conname,
    pg_get_constraintdef(oid) as constraint_definition
from pg_constraint
where conname = 'builder_project_submissions_readme_fetch_status_check';

--Check total values in the table
select distinct
    readme_fetch_status
from public.builder_project_submissions
order by readme_fetch_status;

--Update the check constraint
--If the only current value is pending, run this:
begin;

alter table public.builder_project_submissions
drop constraint if exists builder_project_submissions_readme_fetch_status_check;

alter table public.builder_project_submissions
add constraint builder_project_submissions_readme_fetch_status_check
check (
    readme_fetch_status in (
        'pending',
        'fetched',
        'not_found',
        'failed',
        'skipped',
        'checked_clean',
        'checked_flagged',
        'fetch_failed',
        'missing_readme_url'
    )
);

commit;

-- 
select
    conname,
    pg_get_constraintdef(oid) as constraint_definition
from pg_constraint
where conrelid = 'public.builder_project_submissions'::regclass;

--
select
    current_database() as database_name,
    current_user as connected_user,
    inet_server_addr() as server_address,
    inet_server_port() as server_port,
    version() as postgres_version;
	
--
select
    count(*) as submissions_count
from public.builder_project_submissions;

select
    count(*) as ai_reviews_count
from public.builder_ai_project_reviews;
