{{ config(enabled=(var('netsuite__time_tracking_enabled', false))) }}

with time_entries as (
    select * from {{ var('netsuite_time_entries') }}
),

classes as (
    select * from {{ var('netsuite_classes') }}
),

customers as (
    select * from {{ var('netsuite_customers') }}
),

departments as (
    select * from {{ var('netsuite_departments') }}
),

employees as (
    select * from {{ var('netsuite_employees') }}
),

items as (
    select * from {{ var('netsuite_items') }}
),

{% if var('netsuite__using_jobs', false) %}
jobs as (
    select * from {{ var('netsuite_jobs') }}
),
{% endif %}

locations as (
    select * from {{ var('netsuite_locations') }}
),

{% if var('netsuite__advanced_jobs_enabled', false) %}
job_resources as (
    select * from {{ var('netsuite_job_resources') }}
),

project_tasks as (
    select * from {{ var('netsuite_project_tasks') }}
),

project_task_assignees as (
    select * from {{ var('netsuite_project_task_assignees') }}
),
{% endif %}

subsidiaries as (
    select * from {{ var('netsuite_subsidiaries') }}
),

{% if var('netsuite__time_off_management_enabled', false) %}
time_off_types as (
    select * from {{ var('netsuite_time_off_types') }}
),
{% endif %}

time_entry_details as (

    select
        time_entries.time_entry_id,
        time_entries.memo as time_entry_memo,
        {% if var('netsuite__time_off_management_enabled', false) %}
        time_entries.time_off_type_id,
        time_off_types.time_off_type_name,
        {% endif %}
        time_entries.is_time_off,
        time_entries.is_billable,
        time_entries.billable_label,
        time_entries.is_productive,
        time_entries.is_utilized,
        time_entries.date,
        time_entries.hours,
        time_entries.rate,
        time_entries.time_type,
        time_entries.time_type_full_name

        --The below script allows for time entries table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='time_entries_pass_through_columns', identifier='time_entries', transform='') }},
        
        time_entries.employee_id,
        employees.employee_name_last_first,
        employees.employee_job_title,
        employees.employee_labor_cost
        
        --The below script allows for employees table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='employees_pass_through_columns', identifier='employees', transform='') }},
        
        time_entries.customer_id as customer_job_id,
        customers.customer_id,
        customers.company_name, 
        customers.customer_city,
        customers.customer_state,
        customers.customer_zip_code,
        customers.customer_country,
        customers.customer_external_id
        
        --The below script allows for customers table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='customers_pass_through_columns', identifier='customers', transform='') }},
        
        {% if var('netsuite__using_jobs', false) %}
        jobs.job_id,
        jobs.job_external_id,
        jobs.job_name,
        jobs.job_full_name, 
        jobs.job_status_name,
        jobs.job_type_name,
        jobs.project_manager_name_last_first

        --The below script allows for jobs table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='jobs_pass_through_columns', identifier='jobs', transform='') }},
        {% endif %}

        {% if var('netsuite__advanced_jobs_enabled', false) %}
        job_resources.job_resource_role,
        project_tasks.project_task_id,
        project_tasks.project_task_name, 
        project_tasks.project_task_full_name, 
        project_task_assignees.unit_price as project_task_unit_price,
        project_task_assignees.unit_cost as project_task_unit_cost,
        {% endif %}

        coalesce(time_entries.class_id, items.class_id) as class_id,
        classes.class_full_name

        --The below script allows for jobs table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='classes_pass_through_columns', identifier='classes', transform='') }},

        time_entries.item_id,
        items.item_name,
        items.item_type_name

        --The below script allows for items table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='items_pass_through_columns', identifier='items', transform='') }},

        time_entries.department_id,
        departments.department_name
        
        --The below script allows for departments table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='departments_pass_through_columns', identifier='departments', transform='') }},
        
        time_entries.subsidiary_id,
        subsidiaries.subsidiary_name

        -- The below script allows for subsidiaries table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='subsidiaries_pass_through_columns', identifier='subsidiaries', transform='') }},

        time_entries.location_id,
        locations.location_name,
        locations.location_city,
        locations.location_country

        --The below script allows for locations table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='locations_pass_through_columns', identifier='locations', transform='') }}
    
    from time_entries
    
    left join items 
        on items.item_id = time_entries.item_id
    
    left join classes 
        on classes.class_id = coalesce(time_entries.class_id, items.class_id)
        
    {% if var('netsuite__using_jobs', false) %}
    left join jobs 
        on jobs.job_id = time_entries.customer_id
        
    left join customers 
        on customers.customer_id = coalesce(jobs.customer_id, time_entries.customer_id)
    {% else %}
    left join customers 
        on customers.customer_id = time_entries.customer_id
    {% endif %}
        
    left join departments 
        on departments.department_id = time_entries.department_id
        
    left join employees 
        on employees.employee_id = time_entries.employee_id
        
    left join locations 
        on locations.location_id = time_entries.location_id

    {% if var('netsuite__advanced_jobs_enabled', false) %}
    left join job_resources 
        on job_resources.project_id = time_entries.customer_id
        and job_resources.job_resource_id = time_entries.employee_id
        
    left join project_tasks 
        on project_tasks.project_task_id = time_entries.case_task_event_id
        
    left join project_task_assignees 
        on project_task_assignees.project_task_id = project_tasks.project_task_id
        and project_task_assignees.resource_id = employees.employee_id
        and project_task_assignees.service_item_id = items.item_id
    {% endif %}
        
    left join subsidiaries 
        on subsidiaries.subsidiary_id = time_entries.subsidiary_id
        
    {% if var('netsuite__time_off_management_enabled', false) %}
    left join time_off_types
        on time_off_types.time_off_type_id = time_entries.time_off_type_id
    {% endif %}
        
)
select * from time_entry_details
