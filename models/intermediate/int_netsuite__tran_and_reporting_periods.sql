with accounting_periods as (
    select * from {{ ref('base_netsuite__accounting_periods') }}
),
subsidiaries as (
    select * from {{ var('netsuite_subsidiaries') }}
),
transaction_and_reporting_periods as (

    select
        base.accounting_period_id as accounting_period_id,
        multiplier.accounting_period_id as reporting_accounting_period_id
    from accounting_periods as base

    join accounting_periods as multiplier
        on multiplier.starting_at >= base.starting_at
        and multiplier.is_quarter = base.is_quarter
        and multiplier.is_year = base.is_year -- this was year_0 in netsuite1
        and coalesce(multiplier.fiscal_calendar_id, 1) = coalesce(base.fiscal_calendar_id, 1)
        and cast(multiplier.starting_at as {{ dbt.type_timestamp() }}) <= {{ current_timestamp() }} 

    where 
        not base.is_quarter
        and not base.is_year
        and coalesce(base.fiscal_calendar_id, 1) = coalesce((select fiscal_calendar_id from subsidiaries where parent_id is null), 1) -- fiscal calendar will align with parent subsidiary's default calendar
)
select *  from transaction_and_reporting_periods