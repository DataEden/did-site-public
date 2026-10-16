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

--builder_submission_readme_checks table
create table if not exists public.builder_submission_readme_checks (
    id uuid primary key default gen_random_uuid(),

    submission_id uuid not null
        references public.builder_project_submissions(id)
        on delete cascade,

    readme_fetch_status text not null,
    readme_check_notes text,

    submitted_readme_url text,
    normalized_readme_url text,

    raw_readme_md text,
    cleaned_readme_md text,

    raw_sha256 text,
    cleaned_sha256 text,

    raw_character_count integer,
    cleaned_character_count integer,
    unsafe_marker_count integer,
    event_source text,

    raw_scan_result jsonb default '{}'::jsonb,
    cleaned_scan_result jsonb default '{}'::jsonb,
    readme_check_metadata jsonb default '{}'::jsonb,

    sanitization_applied boolean default false,
    fetch_success boolean default false,
    fetch_error text,

    is_latest boolean default true,

    created_by text default 'local_admin',
    created_at timestamptz default now()
);

create index if not exists idx_readme_checks_submission_id
on public.builder_submission_readme_checks(submission_id);

create index if not exists idx_readme_checks_latest
on public.builder_submission_readme_checks(submission_id, is_latest);

create index if not exists idx_readme_checks_created_at
on public.builder_submission_readme_checks(created_at desc);

create unique index if not exists idx_readme_checks_one_latest_per_submission
on public.builder_submission_readme_checks(submission_id)
where is_latest = true;

--add submission_readme_check alignment foreign key
--pointer from the submission row to the newest saved README check row
alter table public.builder_project_submissions
add column if not exists latest_readme_check_id uuid
references public.builder_submission_readme_checks(id)
on delete set null;

create index if not exists idx_builder_project_submissions_latest_readme_check_id
on public.builder_project_submissions(latest_readme_check_id);

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

--look into which of these create ai_review_snapshot_created event_type, since I see two!
--scripts/check_submission_readme.py
--python scripts/create_ai_review_snapshot.py
----AI snapshot is created without a model selected/used
----It creates a project/readme snapshot for subsequent review
----It creates one record in builder_submision_events
--python scripts/generate_ai_project_review.py
----Second review of the same reamde generated as planned 
----There is now a rubric score of 65 for this second scoring vs 70 for the first scoring
----The scoring mechanism needs to be updated/fine tuned for greater scoring consistency
--Readme Checker & Readme Fetcher tightening
----I may not need two seperate fetching events in the two separate modules/functions
----I may need it, but this is the question I'll answer next before moving to the next readme test workflow
/* From ai_reviews.src Using 

def create_ai_review_snapshot(
    *,
    submission_id: str,
    model_provider: str = "manual",
    model_name: str = "no_model_yet",
    prompt_version: str = "ai_project_review_prompt_v1",
    rubric_version: str = "builder_showcase_readiness_v1",
    created_by: str = "local_admin",
) -> dict[str, Any]:

--the fetch 
readme_result = fetch_submission_readme_markdown(
        repo_url=context.get("repo_url"),
        readme_url=context.get("readme_url")

--This is the other function 
def check_submission_readme(submission_id: str):
*/
select *
from builder_submission_events;

--check updated readme_checker.py + checker_submission.py
select
    event_type,
    event_message,
    metadata->>'script' as script,
    metadata->>'sanitization_applied' as sanitization_applied,
    created_at
from builder_submission_events
where submission_id = 'ac9b7eba-c303-4700-a8cd-86ba816eee10'
order by created_at desc;

delete from builder_submission_events
where id = 'ad6143dc-6250-4672-b172-9556d3696824'
returning *;

select *
from builder_ai_Project_reviews;

select * 
from builder_project_submissions;

--Notifications Table
create table if not exists public.builder_submission_notifications (
    id uuid primary key default gen_random_uuid(),

    submission_id uuid
        references public.builder_project_submissions(id)
        on delete set null,

    builder_project_id uuid
        references public.builder_projects(id)
        on delete set null,

    ai_review_id uuid
        references public.builder_ai_project_reviews(id)
        on delete set null,

    notification_type text not null,

    recipient_email text not null,
    recipient_name text,

    sender_email text,
    reply_to_email text,

    subject text not null,
    body_text text not null,
    body_html text,

    delivery_status text not null default 'drafted',

    provider text default 'aws_ses',
    provider_region text,
    provider_message_id text,

    provider_event_type text,
    provider_event_payload jsonb default '{}'::jsonb,

    error_message text,

    metadata jsonb default '{}'::jsonb,

    created_by text default 'local_admin',
    created_at timestamptz default now(),

    queued_at timestamptz,
    sent_at timestamptz,
    delivered_at timestamptz,
    bounced_at timestamptz,
    complained_at timestamptz,
    failed_at timestamptz
);
--Indexes
create index if not exists idx_builder_notifications_submission_id
on public.builder_submission_notifications(submission_id);

create index if not exists idx_builder_notifications_builder_project_id
on public.builder_submission_notifications(builder_project_id);

create index if not exists idx_builder_notifications_ai_review_id
on public.builder_submission_notifications(ai_review_id);

create index if not exists idx_builder_notifications_type
on public.builder_submission_notifications(notification_type);

create index if not exists idx_builder_notifications_status
on public.builder_submission_notifications(delivery_status);

create index if not exists idx_builder_notifications_recipient_email
on public.builder_submission_notifications(recipient_email);

create index if not exists idx_builder_notifications_created_at
on public.builder_submission_notifications(created_at desc);

create index if not exists idx_builder_notifications_sent_at
on public.builder_submission_notifications(sent_at desc);

create index if not exists idx_builder_notifications_provider_message_id
on public.builder_submission_notifications(provider_message_id);

--Status Constraints/Guards
alter table public.builder_submission_notifications
drop constraint if exists chk_builder_notifications_delivery_status;

alter table public.builder_submission_notifications
add constraint chk_builder_notifications_delivery_status
check (
    delivery_status in (
        'drafted',
        'queued',
        'sending',
        'sent',
        'delivered',
        'bounced',
        'complained',
        'failed',
        'skipped'
    )
);


--check notification send test
select
    id,
    notification_type,
    recipient_email,
    subject,
    delivery_status,
    provider,
    provider_region,
    provider_message_id,
    sent_at,
    failed_at,
    error_message
from builder_submission_notifications
order by created_at desc
limit 10;

--Update notification table with check constraints
alter table public.builder_submission_notifications
drop constraint if exists chk_builder_notifications_delivery_status;

alter table public.builder_submission_notifications
add constraint chk_builder_notifications_delivery_status
check (
    delivery_status in (
        'drafted',
        'queued',
        'sending',
        'sent',
        'delivered',
        'bounced',
        'complained',
        'delivery_delayed',
        'rejected',
        'failed',
        'skipped'
    )
);

--Indexes
alter table public.builder_submission_notifications
add column if not exists rejected_at timestamptz;

alter table public.builder_submission_notifications
add column if not exists delivery_delayed_at timestamptz;

--=====================================================================================
---Second optional event table when I need historical raw event audit like:
--same email had Send → DeliveryDelay → Delivery
--same email generated multiple diagnostic events
--I want immutable raw AWS event history
--I want to debug provider payloads without overwriting the latest payload
--====================================================================================
create table if not exists public.builder_notification_provider_events (
    id uuid primary key default gen_random_uuid(),

    notification_id uuid
        references public.builder_submission_notifications(id)
        on delete cascade,

    provider text not null default 'aws_ses',
    provider_message_id text,
    provider_event_type text not null,
    provider_event_payload jsonb not null default '{}'::jsonb,

    event_received_at timestamptz default now()
);

create index if not exists idx_builder_provider_events_notification_id
on public.builder_notification_provider_events(notification_id);

create index if not exists idx_builder_provider_events_message_id
on public.builder_notification_provider_events(provider_message_id);

create index if not exists idx_builder_provider_events_type
on public.builder_notification_provider_events(provider_event_type);

create index if not exists idx_builder_provider_events_received_at
on public.builder_notification_provider_events(event_received_at desc);
