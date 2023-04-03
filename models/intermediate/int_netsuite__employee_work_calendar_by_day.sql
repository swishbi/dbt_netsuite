with dim_date as (
    select * from {{ ref('dim_date') }}
),
employees as (
    select * from {{ ref('base_netsuite__employees') }}
),
work_calendars as (
    select * from {{ var('netsuite_work_calendars') }}
),
work_calendar_holidays as (
    select * from {{ var('netsuite_work_calendar_holidays') }}
),
employee_work_calendar_by_day as (

    select
        employees.employee_id,
        dim_date.date_day,
        dim_date.relative_day,

        case
            when work_calendar_holidays.exception_date is not null then true
            else false
        end as is_holiday,

        work_calendar_holidays.holiday_description as holiday_description,

        case
            when work_calendar_holidays.exception_date is not null then 0
            when lower(date_format(dim_date.date_day, 'EEEE')) = 'monday' and work_calendars.monday then work_calendars.work_hours_per_day
            when lower(date_format(dim_date.date_day, 'EEEE')) = 'tuesday' and work_calendars.tuesday then work_calendars.work_hours_per_day
            when lower(date_format(dim_date.date_day, 'EEEE')) = 'wednesday' and work_calendars.wednesday then work_calendars.work_hours_per_day
            when lower(date_format(dim_date.date_day, 'EEEE')) = 'thursday' and work_calendars.thursday then work_calendars.work_hours_per_day
            when lower(date_format(dim_date.date_day, 'EEEE')) = 'friday' and work_calendars.friday then work_calendars.work_hours_per_day
            when lower(date_format(dim_date.date_day, 'EEEE')) = 'saturday' and work_calendars.saturday then work_calendars.work_hours_per_day
            when lower(date_format(dim_date.date_day, 'EEEE')) = 'sunday' and work_calendars.sunday then work_calendars.work_hours_per_day
            else 0
        end as work_calendar_hours
    
    from employees
    
    join dim_date 
        on dim_date.date_day >= employees.employee_hire_date
        and (dim_date.date_day <= employees.employee_release_date or employees.employee_release_date is null)

    left join work_calendars 
        on work_calendars.work_calendar_id = employees.work_calendar_id
    
    left join work_calendar_holidays 
        on work_calendar_holidays.work_calendar_id = work_calendars.work_calendar_id
        and work_calendar_holidays.exception_date = dim_date.date_day
    
    where
        coalesce(employees.is_job_resource, false)
)
select * from employee_work_calendar_by_day
