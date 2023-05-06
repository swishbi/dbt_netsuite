{{ config(enabled=(var('netsuite__time_tracking_enabled', false))) }}

with employees as (
    select * from {{ var('netsuite_employees') }}
),
employee_work_calendar_by_day as (
    select * from {{ ref('int_netsuite__employee_work_calendar_by_day') }}
),
time_entries_by_day as (
    select * from {{ ref('int_netsuite__employee_time_entries_by_day') }}
),
employee_utilization as (
    
    select
        employee_work_calendar_by_day.employee_id,
        employees.employee_name_last_first,
        employees.employee_job_title,
        employees.employee_type_name,
        employees.employee_status_name,
        employees.employee_status_category_name,
        employees.department_id,
        employees.department_name as employee_department,
        employees.subsidiary_id,
        employees.subsidiary_name as employee_subsidiary,
        employees.location_id,
        employees.location_name as employee_location,
        employees.location_city as employee_location_city,
        employees.location_country as employee_location_country,
        employee_work_calendar_by_day.date_day,
        employee_work_calendar_by_day.is_holiday,
        employee_work_calendar_by_day.holiday_description,
        employee_work_calendar_by_day.work_calendar_hours,
        coalesce(time_entries_by_day.total_hours, 0) as total_hours,
        coalesce(time_entries_by_day.billable_hours, 0) as billable_hours,
        coalesce(time_entries_by_day.non_billable_hours, 0) as non_billable_hours,
        coalesce(time_entries_by_day.time_off_hours, 0) as time_off_hours,
        coalesce(time_entries_by_day.productive_hours, 0) as productive_hours,
        coalesce(time_entries_by_day.utilized_hours, 0) as utilized_hours
    
    from employee_work_calendar_by_day
    
    left join time_entries_by_day 
        on time_entries_by_day.employee_id = employee_work_calendar_by_day.employee_id
        and time_entries_by_day.date = employee_work_calendar_by_day.date_day
    
    left join employees 
        on employees.employee_id = employee_work_calendar_by_day.employee_id
    
    where
        employee_work_calendar_by_day.date_day < {{ dbt.date_trunc("day", dbt.current_timestamp()) }}
)
select * from employee_utilization