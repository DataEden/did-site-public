-- ============================================================
-- DataInsideData™ Builder Showcase
-- Phase 3G: pgAdmin Business / Operational Queries
-- ============================================================
-- This file contains SQL queries for the builder showcase operations summary dashboard. 
-- Purpose:
--   These queries support Builder Showcase operations, review,
--   publishing QA, README review health, and dashboard preparation.
--
-- Repo path:
--   sql/business_queries/builder_showcase_ops_queries.sql
--
-- Activity Notes:
--   - Run individual sections in pgAdmin as needed.
--   - Replace placeholder UUIDs/slugs where marked.
--   - These queries are read-only.
--   ============================================================
--   It includes queries for:
--   1. Submission status counts
--   2. README review health
--   3. Recent submissions
--   4. Review queue
--   5. README flagged queue
--   6. Pending README checks
--   7. Published projects
--   8. Lifecycle metrics
--   9. Event timeline by submission
--   10. Recent events
--   11. Event counts
--   12. Latest event per submission
--   13. Missing lifecycle history
--   14. Daily submission/event activity
--   15. Category mix
--   16. README flag details
--   17. Origin/security metadata
--   18. Duplicate-looking URLs
-- ============================================================


-- ============================================================
-- 01. Submission Status Counts
-- Business question:
--   How many submissions are in each workflow status?
-- ============================================================

select
    status,
    count(*) as submission_count
from public.builder_project_submissions
group by status
order by submission_count desc, status;


-- ============================================================
-- 02. README Review Health
-- Business question:
--   Which submissions still need README review, are clean,
--   are flagged, or have fetch issues?
-- ============================================================

with status_list as (
    select *
    from (
        values
            ('pending', 1, 'Needs check'),
            ('checked_clean', 2, 'Ready'),
            ('checked_flagged', 3, 'Needs review'),
            ('fetch_failed', 4, 'Fetch issue'),
            ('missing_readme_url', 5, 'Missing README'),

            -- legacy/transition values
            ('fetched', 6, 'Legacy'),
            ('not_found', 7, 'Legacy'),
            ('failed', 8, 'Legacy'),
            ('skipped', 9, 'Legacy')
    ) as statuses(readme_fetch_status, sort_order, review_group)
)

select
    sl.readme_fetch_status,
    sl.review_group,
    coalesce(count(s.id), 0) as submission_count
from status_list sl
left join public.builder_project_submissions s
    on s.readme_fetch_status = sl.readme_fetch_status
group by
    sl.readme_fetch_status,
    sl.review_group,
    sl.sort_order
order by sl.sort_order;


-- ============================================================
-- 03. Recent Submissions
-- Business question:
--   What are the latest Builder Showcase submissions?
-- ============================================================

select
    id,
    project_title,
    submitter_email,
    github_username,
    repo_url,
    readme_url,
    project_category,
    status,
    readme_fetch_status,
    readme_checked_at,
    readme_check_notes,
    created_at,
    updated_at
from public.builder_project_submissions
order by created_at desc
limit 25;


-- ============================================================
-- 04. Review Queue
-- Business question:
--   Which submissions still need admin review or action?
-- ============================================================

select
    id,
    project_title,
    submitter_email,
    github_username,
    repo_url,
    readme_url,
    project_category,
    status,
    readme_fetch_status,
    readme_checked_at,
    created_at,
    updated_at
from public.builder_project_submissions
where status in (
    'submitted',
    'reviewing',
    'needs_changes'
)
order by created_at asc;


-- ============================================================
-- 05. README Flagged Queue
-- Business question:
--   Which submissions need README safety/content review?
-- ============================================================

select
    id,
    project_title,
    status,
    readme_fetch_status,
    readme_checked_at,
    readme_check_notes,
    readme_check_metadata,
    repo_url,
    readme_url,
    created_at,
    updated_at
from public.builder_project_submissions
where readme_fetch_status in (
    'checked_flagged',
    'fetch_failed',
    'missing_readme_url'
)
order by readme_checked_at desc nulls last,
         created_at desc;


-- ============================================================
-- 06. Pending README Checks
-- Business question:
--   Which submissions still need README checking?
-- ============================================================

select
    id,
    project_title,
    status,
    readme_fetch_status,
    readme_url,
    created_at,
    updated_at
from public.builder_project_submissions
where readme_fetch_status = 'pending'
order by created_at asc;


-- ============================================================
-- 07. Published Builder Projects
-- Business question:
--   Which Builder Showcase projects are public/published?
-- ============================================================

select
    p.id as builder_project_id,
    p.submission_id,
    p.title,
    p.slug,
    p.category,
    p.github_username,
    p.repo_url,
    p.readme_url,
    p.live_url,
    p.is_public,
    p.created_at,
    p.updated_at,
    s.status as submission_status,
    s.readme_fetch_status,
    s.first_name,
    s.last_name,
    s.submitter_email
from public.builder_projects p
left join public.builder_project_submissions s
    on p.submission_id = s.id
where p.is_public = true
order by p.updated_at desc;


-- ============================================================
-- 08. Submission Lifecycle Metrics
-- Business question:
--   How long does it take from submission to promotion/page generation?
-- ============================================================

with event_pivot as (
    select
        submission_id,

        min(created_at) filter (
            where event_type = 'submission_created'
        ) as submitted_at,

        min(created_at) filter (
            where event_type = 'readme_checked'
        ) as readme_checked_at,

        min(created_at) filter (
            where event_type = 'status_changed'
              and new_status = 'reviewing'
        ) as first_reviewed_at,

        min(created_at) filter (
            where event_type = 'promoted_to_builder_project'
        ) as promoted_at,

        min(created_at) filter (
            where event_type = 'exported_to_yml'
        ) as exported_at,

        min(created_at) filter (
            where event_type = 'detail_page_generated'
        ) as detail_page_generated_at

    from public.builder_submission_events
    where submission_id is not null
    group by submission_id
)

select
    s.id as submission_id,
    s.project_title,
    s.status,
    s.readme_fetch_status,
    p.id as builder_project_id,
    p.slug,
    p.is_public,

    ep.submitted_at,
    ep.readme_checked_at,
    ep.first_reviewed_at,
    ep.promoted_at,
    ep.exported_at,
    ep.detail_page_generated_at,

    case
        when ep.submitted_at is not null
         and ep.readme_checked_at is not null
        then round(
            (extract(epoch from (ep.readme_checked_at - ep.submitted_at)) / 3600)::numeric,
            2
        )
        else null
    end as hours_to_readme_check,

    case
        when ep.submitted_at is not null
         and ep.promoted_at is not null
        then round(
            (extract(epoch from (ep.promoted_at - ep.submitted_at)) / 3600)::numeric,
            2
        )
        else null
    end as hours_to_promote,

    case
        when ep.submitted_at is not null
         and ep.detail_page_generated_at is not null
        then round(
            (extract(epoch from (ep.detail_page_generated_at - ep.submitted_at)) / 3600)::numeric,
            2
        )
        else null
    end as hours_to_generated_page

from public.builder_project_submissions s
left join event_pivot ep
    on s.id = ep.submission_id
left join public.builder_projects p
    on s.id = p.submission_id
order by coalesce(ep.submitted_at, s.created_at) desc;


-- ============================================================
-- 09. Full Event Timeline for One Submission
-- Business question:
--   What exactly happened to one submission?
--
-- Replace the UUID below before running.
-- ============================================================

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
where e.submission_id = 'ac9b7eba-c303-4700-a8cd-86ba816eee10'
order by e.created_at asc;


-- ============================================================
-- 10. Recent Operational Events
-- Business question:
--   What happened recently across the Builder Showcase workflow?
-- ============================================================

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
limit 50;


-- ============================================================
-- 11. Event Counts by Type
-- Business question:
--   Which workflow events are happening most often?
-- ============================================================

select
    event_type,
    created_by,
    count(*) as event_count,
    min(created_at) as first_seen_at,
    max(created_at) as last_seen_at
from public.builder_submission_events
group by event_type, created_by
order by event_count desc, event_type;


-- ============================================================
-- 12. Latest Event Per Submission
-- Business question:
--   What is the latest recorded workflow event for each submission?
-- ============================================================

with ranked_events as (
    select
        e.*,
        row_number() over (
            partition by e.submission_id
            order by e.created_at desc
        ) as rn
    from public.builder_submission_events e
    where e.submission_id is not null
)

select
    re.submission_id,
    s.project_title,
    s.status,
    s.readme_fetch_status,
    re.event_type as latest_event_type,
    re.event_message as latest_event_message,
    re.created_by as latest_event_created_by,
    re.created_at as latest_event_at
from ranked_events re
left join public.builder_project_submissions s
    on re.submission_id = s.id
where re.rn = 1
order by re.created_at desc;


-- ============================================================
-- 13. Published Projects Missing Full Event History
-- Business question:
--   Which published projects existed before event logging
--   or are missing lifecycle events?
-- ============================================================

with event_flags as (
    select
        submission_id,
        bool_or(event_type = 'submission_created') as has_submission_created,
        bool_or(event_type = 'readme_checked') as has_readme_checked,
        bool_or(event_type = 'promoted_to_builder_project') as has_promotion_event,
        bool_or(event_type = 'exported_to_yml') as has_export_event,
        bool_or(event_type = 'detail_page_generated') as has_page_event
    from public.builder_submission_events
    where submission_id is not null
    group by submission_id
)

select
    s.id as submission_id,
    s.project_title,
    s.status,
    s.readme_fetch_status,
    p.id as builder_project_id,
    p.slug,
    coalesce(ef.has_submission_created, false) as has_submission_created,
    coalesce(ef.has_readme_checked, false) as has_readme_checked,
    coalesce(ef.has_promotion_event, false) as has_promotion_event,
    coalesce(ef.has_export_event, false) as has_export_event,
    coalesce(ef.has_page_event, false) as has_page_event
from public.builder_project_submissions s
left join public.builder_projects p
    on s.id = p.submission_id
left join event_flags ef
    on s.id = ef.submission_id
where s.status = 'published'
order by s.updated_at desc;


-- ============================================================
-- 14. Daily Submission Activity
-- Business question:
--   How many submissions are coming in per day?
-- ============================================================

select
    date_trunc('day', created_at)::date as submission_date,
    count(*) as submission_count
from public.builder_project_submissions
group by date_trunc('day', created_at)::date
order by submission_date desc;


-- ============================================================
-- 15. Daily Event Activity
-- Business question:
--   What workflow activity is happening by day and event type?
-- ============================================================
select
    date_trunc('day', created_at)::date as event_date,
    event_type,
    count(*) as event_count
from public.builder_submission_events
group by
    date_trunc('day', created_at)::date,
    event_type
order by event_date desc, event_type;


-- ============================================================
-- 16. Category Mix
-- Business question:
--   What kinds of projects are being submitted/published?
-- ============================================================
select
    project_category,
    status,
    count(*) as submission_count
from public.builder_project_submissions
group by project_category, status
order by submission_count desc, project_category, status;


-- ============================================================
-- 17. README Flag Details from JSON Metadata
-- Business question:
--   What unsafe/unsupported markers were detected in flagged READMEs?
-- ============================================================

select
    id,
    project_title,
    readme_fetch_status,
    readme_check_notes,
    readme_check_metadata -> 'scan_result' -> 'unsafe_markers' as unsafe_markers,
    readme_check_metadata -> 'scan_result' ->> 'unsafe_marker_count' as unsafe_marker_count,
    readme_url,
    readme_checked_at
from public.builder_project_submissions
where readme_fetch_status = 'checked_flagged'
order by readme_checked_at desc;


-- ============================================================
-- 18. Public-Origin Submission Metadata
-- Business question:
--   Which origins/referers are public form submissions coming from?
-- ============================================================
select
    request_origin,
    request_referer,
    count(*) as submission_count,
    min(created_at) as first_seen_at,
    max(created_at) as last_seen_at
from public.builder_project_submissions
group by request_origin, request_referer
order by submission_count desc, last_seen_at desc;


-- ============================================================
-- 19. Submission Records with IP Hash Present
-- Business question:
--   Are security metadata fields being captured as expected?
-- ============================================================

select
    case
        when client_ip_hash is null or client_ip_hash = '' then false
        else true
    end as has_client_ip_hash,
    count(*) as submission_count
from public.builder_project_submissions
group by has_client_ip_hash
order by has_client_ip_hash desc;


-- ============================================================
-- 20. Duplicate-Looking Project URLs
-- Business question:
--   Are the same repo/readme URLs appearing across submissions?
-- ============================================================

select
    repo_url,
    readme_url,
    count(*) as submission_count,
    min(created_at) as first_submitted_at,
    max(created_at) as last_submitted_at
from public.builder_project_submissions
group by repo_url, readme_url
having count(*) > 1
order by submission_count desc, last_submitted_at desc;

-- ============================================================
-- End of Builder Showcase business queries
-- ============================================================