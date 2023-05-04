{{ config(enabled=(var('netsuite__using_jobs', false) and var('netsuite__advanced_jobs_enabled') and var('netsuite__time_tracking_enabled', false))) }}

with customers as (
    select * from {{ var('netsuite_customers') }}
),
employees as (
    select * from {{ var('netsuite_employees') }}
),
items as (
    select * from {{ var('netsuite_items') }}
),
jobs as (
    select * from {{ var('netsuite_jobs') }}
),
job_resources as (
    select * from {{ var('netsuite_job_resources') }}
),
project_tasks as (
    select * from {{ var('netsuite_project_tasks') }}
),
project_task_assignees as (
    select * from {{ var('netsuite_project_task_assignees') }}
),
actual_work as (
    
    select
        case_task_event_id as project_task_id,
        employee_id,
        item_id,
        sum(hours) as hours,
        sum(case when is_billable then hours else 0 end) as billable_hours
    
    from {{ var('netsuite_time_entries') }}
    
    where lower(time_type) = 'a'
    
    {{ dbt_utils.group_by(n=3) }}
),
project_job_details as (

    select
        jobs.*,
        customers.company_name,
        customers.customer_city,
        customers.customer_state,
        customers.customer_zip_code,
        customers.customer_country,
        customers.customer_external_id,
        employees.employee_id,
        employees.employee_name_last_first,
        employees.employee_job_title,
        employees.employee_labor_cost,
        job_resources.job_resource_role,
        items.item_id,
        items.item_name,
        items.item_type_name,
        project_tasks.project_task_name,
        project_tasks.project_task_full_name,
        project_tasks.project_task_start_date,
        project_tasks.project_task_status,
        project_tasks.is_non_billable_task,
        project_tasks.is_summary_task,
        project_task_assignees.unit_price,
        project_task_assignees.unit_cost,
        project_task_assignees.estimated_work,
        project_task_assignees.planned_work,
        actual_work.hours as actual_work,
        actual_work.billable_hours as actual_billable_work
    
    from jobs
    
    left join customers 
        on customers.customer_id = jobs.customer_id
    
    left join project_tasks 
        on project_tasks.project_id = jobs.job_id

    left join project_task_assignees 
        on project_task_assignees.project_task_id = project_tasks.project_task_id
    
    left join job_resources 
        on job_resources.project_id = jobs.job_id
        and job_resources.job_resource_id = project_task_assignees.resource_id
    
    left join actual_work 
        on actual_work.project_task_id = project_task_assignees.project_task_id
        and actual_work.employee_id = project_task_assignees.resource_id
        and actual_work.item_id = project_task_assignees.service_item_id
    
    left join employees 
        on employees.employee_id = job_resources.job_resource_id
    
    left join items 
        on items.item_id = project_task_assignees.service_item_id
),
final as (

    select
        *,
        unit_price * estimated_work as estimated_revenue,
        unit_price * planned_work as planned_revenue,
        unit_price * actual_billable_work as actual_revenue,
        unit_cost * estimated_work as estimated_costs,
        unit_cost * planned_work as planned_costs,
        unit_cost * actual_work as actual_costs
    
    from project_job_details
)
select * from final