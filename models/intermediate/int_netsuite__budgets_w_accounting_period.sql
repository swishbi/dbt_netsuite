{{ config(enabled=(var('netsuite__using_budgets', false))) }}

with budgets as (
    select * from {{ var('netsuite_budgets') }}
),
budgets_machine as (
    select * from {{ var('netsuite_budgets_machine') }}
),
budgets_w_accounting_period as (
    
    select
        budgets.*,
        budgets_machine.accounting_period_id,
        coalesce(budgets_machine.amount, 0) as unconverted_amount
    
    from budgets
    
    left join budgets_machine 
        on budgets_machine.budget_id = budgets.budget_id
)
select * from budgets_w_accounting_period