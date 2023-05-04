with transaction_lines_w_accounting_period as (
    select * from {{ ref('int_netsuite__tran_lines_w_accounting_period') }}
),
{% if var('netsuite__multiple_currencies_enabled', false) and var('netsuite__multibook_accounting_enabled', false) %}
accountxperiod_exchange_rate_map as (
    select * from {{ ref('int_netsuite__acctxperiod_exchange_rate_map') }}
),
{% endif %}
transaction_and_reporting_periods as (
    select * from {{ ref('int_netsuite__tran_and_reporting_periods') }}
), 
accounts as (
    select * from {{ var('netsuite_accounts') }}
),
transactions_in_every_calculation_period_w_exchange_rates as (

    select
        transaction_lines_w_accounting_period.*,
        reporting_accounting_period_id,
        {% if var('netsuite__multiple_currencies_enabled', false) and var('netsuite__multibook_accounting_enabled', false) %}
        exchange_reporting_period.exchange_rate as exchange_rate_reporting_period,
        exchange_transaction_period.exchange_rate as exchange_rate_transaction_period
        {% else %}
        1.00 as exchange_rate_reporting_period,
        1.00 as exchange_rate_transaction_period
        {% endif %}

    from transaction_lines_w_accounting_period
    
    left join transaction_and_reporting_periods 
        on transaction_and_reporting_periods.accounting_period_id = transaction_lines_w_accounting_period.transaction_accounting_period_id 
    
    {% if var('netsuite__multiple_currencies_enabled', false) and var('netsuite__multibook_accounting_enabled', false) %}
    left join accountxperiod_exchange_rate_map as exchange_reporting_period
        on exchange_reporting_period.accounting_period_id = transaction_and_reporting_periods.reporting_accounting_period_id
        and exchange_reporting_period.account_id = transaction_lines_w_accounting_period.account_id
        and exchange_reporting_period.from_subsidiary_id = transaction_lines_w_accounting_period.subsidiary_id
    
    left join accountxperiod_exchange_rate_map as exchange_transaction_period
        on exchange_transaction_period.accounting_period_id = transaction_and_reporting_periods.accounting_period_id
        and exchange_transaction_period.account_id = transaction_lines_w_accounting_period.account_id
        and exchange_transaction_period.from_subsidiary_id = transaction_lines_w_accounting_period.subsidiary_id
    {% endif %}
), 
transactions_with_converted_amounts as (
    
    select
        transactions_in_every_calculation_period_w_exchange_rates.*,
        unconverted_amount * coalesce(exchange_rate_transaction_period, 1.00) as converted_amount_using_transaction_accounting_period,
        unconverted_amount * coalesce(exchange_rate_reporting_period, 1.00) as converted_amount_using_reporting_month,
        unconverted_paid_amount * coalesce(exchange_rate_transaction_period, 1.00) as converted_paid_amount_using_transaction_accounting_period,
        unconverted_paid_amount * coalesce(exchange_rate_reporting_period, 1.00) as converted_paid_amount_using_reporting_month,
        unconverted_unpaid_amount * coalesce(exchange_rate_transaction_period, 1.00) as converted_unpaid_amount_using_transaction_accounting_period,
        unconverted_unpaid_amount * coalesce(exchange_rate_reporting_period, 1.00) as converted_unpaid_amount_using_reporting_month,
        accounts.is_income_statement,    
        accounts.account_category
        
    from transactions_in_every_calculation_period_w_exchange_rates
    
    join accounts 
        on accounts.account_id = transactions_in_every_calculation_period_w_exchange_rates.account_id 
)
select * from transactions_with_converted_amounts