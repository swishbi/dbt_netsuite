{{ config(enabled=(var('netsuite__time_tracking_enabled', false))) }}

with time_entries as (
    select * from {{ var('netsuite_time_entries') }}
),
employee_time_entries_by_day as (

    select
        time_entries.employee_id,
        time_entries.date,
        sum(time_entries.hours) as total_hours,
        sum(case when time_entries.is_billable then time_entries.hours else 0 end) as billable_hours,
        sum(case when not time_entries.is_billable then time_entries.hours else 0 end) as non_billable_hours,
        sum(case when time_entries.time_off_type_id is not null then time_entries.hours else 0 end) as time_off_hours,
        sum(case when time_entries.is_productive then time_entries.hours else 0 end) as productive_hours,
        sum(case when time_entries.is_utilized then time_entries.hours else 0 end) as utilized_hours
    
    from time_entries
    
    where 
        lower(time_type) = 'a'
    
    {{ dbt_utils.group_by(n=2) }}
)
select * from employee_time_entries_by_day
