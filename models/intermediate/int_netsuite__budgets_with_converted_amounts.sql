{{ config(enabled=(var('netsuite__using_budgets', false))) }}

with budgets_w_accounting_period as (
    select * from {{ ref('int_netsuite__budgets_w_accounting_period') }}
), 
accountxperiod_exchange_rate_map as (
    select * from {{ ref('int_netsuite__acctxperiod_exchange_rate_map') }}
), 
accounts as (
    select * from {{ ref('base_netsuite__accounts') }}
),
budgets_w_exchange_rates as (
    
    select
        budgets_w_accounting_period.*,
        exchange_transaction_period.exchange_rate as exchange_rate_transaction_period
    
    from budgets_w_accounting_period
    
    left join accountxperiod_exchange_rate_map as exchange_transaction_period
        on exchange_transaction_period.account_id = budgets_w_accounting_period.account_id
        and exchange_transaction_period.from_subsidiary_id = budgets_w_accounting_period.subsidiary_id
), 
budgets_with_converted_amounts as (
    
    select
        budgets_w_exchange_rates.*,
        unconverted_amount * coalesce(exchange_rate_transaction_period, 1.00) as converted_amount_using_budget_accounting_period
    
    from budgets_w_exchange_rates
)
select * from budgets_with_converted_amounts