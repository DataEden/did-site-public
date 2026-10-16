/*
------------------
Business Queries -
------------------
review submissions
approve/reject submissions
view published builder projects
find projects ready to export
audit status flow
check duplicates
dashboard/reporting views
QA before deploy 
*/

--1. View latest submissions
select
    id,
    first_name,
    last_name,
    submitter_email,
    github_username,
    repo_url,
    project_title,
    project_category,
    status,
    readme_fetch_status,
    created_at,
    updated_at
from builder_project_submissions
order by created_at desc;

--2. View review queue
select
    id,
    first_name,
    last_name,
    submitter_email,
    github_username,
    repo_url,
    project_title,
    project_category,
    project_description,
    project_tags,
    readme_url,
    status,
    readme_fetch_status,
    created_at,
    updated_at
from builder_project_submissions
where status in ('submitted', 'reviewing', 'needs_changes')
order by created_at asc;

--3. Update submission status

In pgAdmin, use literal values instead of :submission_id.

update builder_project_submissions
set status = 'reviewing'
where id = 'PASTE_SUBMISSION_UUID_HERE'
returning
    id,
    project_title,
    status,
    updated_at;

--4. View approved submissions ready for promotion
select
    id,
    github_username,
    repo_url,
    project_title,
    project_category,
    project_description,
    project_tags,
    readme_url,
    live_url,
    status,
    created_at
from builder_project_submissions
where status = 'approved'
order by created_at asc;

--5. View published submissions
select
    id,
    first_name,
    last_name,
    project_title,
    github_username,
    repo_url,
    status,
    created_at,
    updated_at
from builder_project_submissions
where status = 'published'
order by updated_at desc;

--6. View public builder projects
select
    p.id,
    p.submission_id,
    p.title,
    p.slug,
    p.description,
    p.category,
    p.tags,
    p.github_username,
    p.repo_url,
    p.readme_url,
    p.live_url,
    p.is_public,
    p.created_at,
    p.updated_at,
    s.first_name,
    s.last_name,
    s.status as submission_status
from builder_projects p
left join builder_project_submissions s
    on p.submission_id = s.id
where p.is_public = true
order by p.created_at desc;

--7. View one builder project by slug
select
    p.id,
    p.submission_id,
    p.title,
    p.slug,
    p.description,
    p.category,
    p.tags,
    p.github_username,
    p.repo_url,
    p.readme_url,
    p.live_url,
    p.is_public,
    p.created_at,
    p.updated_at,
    s.first_name,
    s.last_name,
    s.status as submission_status
from builder_projects p
left join builder_project_submissions s
    on p.submission_id = s.id
where p.slug = 'ai-review-sentiment-labeling-pipeline';

--8. Count submissions by status
select
    status,
    count(*) as submission_count
from builder_project_submissions
group by status
order by submission_count desc;

--9. Count projects by category
select
    category,
    count(*) as project_count
from builder_projects
group by category
order by project_count desc;

--10. QA: find duplicate submission IDs in builder_projects
select
    submission_id,
    count(*) as record_count
from builder_projects
where submission_id is not null
group by submission_id
having count(*) > 1;

--11. QA: find duplicate slugs
select
    slug,
    count(*) as record_count
from builder_projects
group by slug
having count(*) > 1;

--12. QA: public projects missing README URL
select
    id,
    title,
    slug,
    repo_url,
    readme_url,
    is_public
from builder_projects
where is_public = true
  and (
    readme_url is null
    or trim(readme_url) = ''
  )
order by created_at desc;

--13. QA: public projects missing repo URL
select
    id,
    title,
    slug,
    repo_url,
    is_public
from builder_projects
where is_public = true
  and (
    repo_url is null
    or trim(repo_url) = ''
  )
order by created_at desc;

--14. QA: published submissions not in builder_projects
--This is an important one.
select
    s.id,
    s.project_title,
    s.github_username,
    s.repo_url,
    s.status,
    s.updated_at
from builder_project_submissions s
left join builder_projects p
    on s.id = p.submission_id
where s.status = 'published'
  and p.id is null
order by s.updated_at desc;

--15. QA: builder projects linked to non-published submissions
select
    p.id as builder_project_id,
    p.title,
    p.slug,
    p.is_public,
    s.id as submission_id,
    s.status as submission_status
from builder_projects p
left join builder_project_submissions s
    on p.submission_id = s.id
where s.status is distinct from 'published'
order by p.created_at desc;

/* 
---------------------------------
What to put in each SQL file
--------------------------------

sql/admin/builder_showcase_admin_queries.sql
view latest submissions
view review queue
update status
view approved ready for promotion
view public builder projects
view one builder project by slug

sql/reports/builder_showcase_reporting_queries.sql
count submissions by status
count projects by category
public project catalog
latest published projects

sql/qa/builder_showcase_qa_queries.sql
duplicate slugs
duplicate submission ids
missing README URL
missing repo URL
published submissions not in builder_projects
builder_projects linked to non-published submissions

That gives you the same operational power in pgAdmin that my Python scripts have in the terminal.

pgAdmin becomes my manual admin cockpit, while scripts are repeatable automation,
and later the dashboard becomes the user-friendly app layer.
*/



-------------------------------------------------------------------------------
select * 
from builder_projects;
--

select *
from builder_project_submissions;

--grant permissions to service role (.insert(submissionRow).select("id, status, readme_fetch_status, created_at"))
--for builder_project_submissions
grant usage on schema public to service_role;

grant select, insert, update
on builder_project_submissions
to service_role;  

--this is for projects_builder
grant select, insert, update
on builder_projects
to service_role;