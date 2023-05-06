{{ config(enabled=(var('netsuite__multiple_currencies_enabled', false))) }}

with accounts as (
    select * from {{ var('netsuite_accounts') }}
),
{% if var('netsuite__multibook_accounting_enabled', false) %}
accounting_books as (
    select * from {{ var('netsuite_accounting_books') }}
),
{% endif %}
subsidiaries as (
    select * from {{ var('netsuite_subsidiaries') }}
),
consolidated_exchange_rates as (
    select * from {{ var('netsuite_consolidated_exchange_rates') }}
),
period_exchange_rate_map as (
    -- exchange rates used, by accounting period, to convert to parent subsidiary
    select
        consolidated_exchange_rates.accounting_period_id,
        consolidated_exchange_rates.average_rate,
        consolidated_exchange_rates.current_rate,
        consolidated_exchange_rates.historical_rate,
        consolidated_exchange_rates.from_subsidiary_id,
        consolidated_exchange_rates.to_subsidiary_id
    
    from consolidated_exchange_rates
    
    where
        consolidated_exchange_rates.to_subsidiary_id in (select subsidiary_id from subsidiaries where parent_id is null) -- constrait - only the primary subsidiary has no parent
        {% if var('netsuite__multibook_accounting_enabled', false) %}
        and consolidated_exchange_rates.accounting_book_id in (select accounting_book_id from accounting_books where is_primary)
        {% endif %}
),
accountxperiod_exchange_rate_map as (
    -- account table with exchange rate details by accounting period
    select
        period_exchange_rate_map.accounting_period_id,
        period_exchange_rate_map.from_subsidiary_id,
        period_exchange_rate_map.to_subsidiary_id,
        accounts.account_id,

        case
            when lower(accounts.general_rate_type) = 'historical' then period_exchange_rate_map.historical_rate
            when lower(accounts.general_rate_type) = 'current' then period_exchange_rate_map.current_rate
            when lower(accounts.general_rate_type) = 'average' then period_exchange_rate_map.average_rate
            else null
        end as exchange_rate

    from accounts
    
    cross join period_exchange_rate_map
)
select * from accountxperiod_exchange_rate_map