---AI Layer Table

-- ============================================================
-- DataInsideData™ Builder Showcase
-- AI Project Review Layer
-- Table: builder_ai_project_reviews
-- ============================================================

create table if not exists public.builder_ai_project_reviews (
    id uuid primary key default gen_random_uuid(),

    -- ------------------------------------------------------------
    -- Relationships
    -- ------------------------------------------------------------
    submission_id uuid not null
        references public.builder_project_submissions(id)
        on delete cascade,

    builder_project_id uuid
        references public.builder_projects(id)
        on delete set null,

    -- ------------------------------------------------------------
    -- Review lifecycle
    -- ------------------------------------------------------------
    review_status text not null default 'generated'
        check (
            review_status in (
                'queued',
                'generated',
                'reviewed',
                'accepted',
                'needs_changes',
                'superseded',
                'failed',
                'archived'
            )
        ),

    is_active boolean not null default true,

    review_version integer not null default 1
        check (review_version > 0),

    -- ------------------------------------------------------------
    -- AI/model metadata
    -- ------------------------------------------------------------
    model_provider text,
    model_name text,
    prompt_version text,
    rubric_version text not null default 'builder_showcase_readiness_v1',

    -- ------------------------------------------------------------
    -- Source snapshots
    -- ------------------------------------------------------------
    -- Snapshot of required form fields at review time.
    -- This prevents later form edits from changing what the AI evaluated.
    form_metadata_snapshot jsonb not null default '{}'::jsonb,

    -- Full README text captured at review time.
    -- Useful for auditability and repeatability.
    readme_snapshot_md text,

    -- Optional hash later, useful for knowing if README changed.
    readme_snapshot_sha256 text,

    -- Optional README fetch/check context from existing README checker.
    readme_check_snapshot jsonb not null default '{}'::jsonb,

    -- ------------------------------------------------------------
    -- Rubric scores
    -- ------------------------------------------------------------
    overall_score numeric(5,2)
        check (overall_score is null or overall_score between 0 and 100),

    readiness_band text
        check (
            readiness_band is null
            or readiness_band in (
                'showcase_ready',
                'strong_minor_improvements',
                'publishable_with_revisions',
                'needs_improvement',
                'not_ready'
            )
        ),

    publication_recommendation text
        check (
            publication_recommendation is null
            or publication_recommendation in (
                'publish_ready',
                'publish_with_minor_revisions',
                'revise_before_publish',
                'not_ready_to_publish',
                'manual_review_required'
            )
        ),

    -- Category-level scores stored as JSON for flexibility.
    -- Example:
    -- {
    --   "project_identity": 13,
    --   "problem_purpose": 8,
    --   "technical_stack_architecture": 12
    -- }
    category_scores jsonb not null default '{}'::jsonb,

    -- ------------------------------------------------------------
    -- AI feedback outputs
    -- ------------------------------------------------------------
    top_strengths jsonb not null default '[]'::jsonb,
    highest_priority_fixes jsonb not null default '[]'::jsonb,
    suggested_readme_sections jsonb not null default '[]'::jsonb,

    suggested_showcase_summary text,
    suggested_resume_bullet text,
    suggested_project_tags jsonb not null default '[]'::jsonb,

    ai_review_summary text,
    ai_review_metadata jsonb not null default '{}'::jsonb,

    -- ------------------------------------------------------------
    -- Private preview / staging support
    -- ------------------------------------------------------------
    preview_status text not null default 'not_generated'
        check (
            preview_status in (
                'not_generated',
                'generated',
                'needs_review',
                'approved',
                'archived',
                'failed'
            )
        ),

    preview_slug text,
    preview_path text,
    preview_metadata jsonb not null default '{}'::jsonb,

    -- ------------------------------------------------------------
    -- Error handling
    -- ------------------------------------------------------------
    error_message text,

    -- ------------------------------------------------------------
    -- Audit fields
    -- ------------------------------------------------------------
    created_by text not null default 'local_admin',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


--Add indexes
--It lets you keep history, but only one review is considered the “current” 
--AI review for a submission.

-- Fast lookup by submission
create index if not exists idx_builder_ai_reviews_submission_id
on public.builder_ai_project_reviews(submission_id);

-- Fast lookup by promoted/public builder project
create index if not exists idx_builder_ai_reviews_builder_project_id
on public.builder_ai_project_reviews(builder_project_id);

-- Dashboard filters
create index if not exists idx_builder_ai_reviews_review_status
on public.builder_ai_project_reviews(review_status);

create index if not exists idx_builder_ai_reviews_publication_recommendation
on public.builder_ai_project_reviews(publication_recommendation);

create index if not exists idx_builder_ai_reviews_created_at
on public.builder_ai_project_reviews(created_at desc);

-- Only one active AI review per submission at a time
create unique index if not exists uq_builder_ai_reviews_one_active_per_submission
on public.builder_ai_project_reviews(submission_id)
where is_active = true;


--Add updated_at trigger set_updated_at()
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_builder_ai_reviews_updated_at
on public.builder_ai_project_reviews;

create trigger trg_builder_ai_reviews_updated_at
before update on public.builder_ai_project_reviews
for each row
execute function public.set_updated_at();

--Enable RLS and grants
alter table public.builder_ai_project_reviews enable row level security;

revoke all on public.builder_ai_project_reviews from anon;
revoke all on public.builder_ai_project_reviews from authenticated;

grant select, insert, update, delete
on public.builder_ai_project_reviews
to service_role;

grant select, insert, update, delete
on public.builder_ai_project_reviews
to postgres;

--Add a first test row manually
insert into public.builder_ai_project_reviews (
    submission_id,
    review_status,
    model_provider,
    model_name,
    prompt_version,
    rubric_version,
    form_metadata_snapshot,
    readme_snapshot_md,
    overall_score,
    readiness_band,
    publication_recommendation,
    category_scores,
    top_strengths,
    highest_priority_fixes,
    ai_review_summary
)
values (
    'a3a7e274-ceca-4c8e-908b-08917faf2826',
    'generated',
    'openai',
    'gpt-4o-mini',
    'ai_project_review_prompt_v1',
    'builder_showcase_readiness_v1',
    '{
        "project_title": "Cross-Cohort Music Recommendation — EDA & Unsupervised Clustering",
        "project_category": "Web / Software Development",
        "repo_url": "https://github.com/DataEden/PatternRoots"
    }'::jsonb,
    '# Placeholder README snapshot for first AI review test',
    82,
    'strong_minor_improvements',
    'publish_with_minor_revisions',
    '{
        "project_identity": 13,
        "problem_purpose": 8,
        "technical_stack_architecture": 12,
        "setup_reproducibility": 10,
        "usage_demo": 7,
        "results_impact": 8,
        "documentation_quality": 8,
        "recruiter_proof_value": 9,
        "safety_publishing": 7
    }'::jsonb,
    '[
        "Clear project concept",
        "Strong evidence of data/analytics workflow",
        "Good candidate for showcase publication"
    ]'::jsonb,
    '[
        "Clarify setup instructions",
        "Add clearer screenshots or demo evidence",
        "Explain project outcomes more directly"
    ]'::jsonb,
    'Initial AI review test row for Builder Showcase readiness scoring.'
)
returning *;

--Verify
select
    id,
    submission_id,
    review_status,
    is_active,
    review_version,
    overall_score,
    readiness_band,
    publication_recommendation,
    created_at
from public.builder_ai_project_reviews
order by created_at desc;

/*
Why this table is the right shape
This supports project product vision cleanly:

Raw GitHub README
+ required form metadata
+ README safety check
+ AI rubric scoring
+ improvement suggestions
+ private preview support
+ dashboard reporting
*/

