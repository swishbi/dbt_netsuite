with budgets_with_converted_amounts as (
    select * from {{ ref("int_netsuite__budgets_with_converted_amounts") }}
),
accounts as (
    select * from {{ ref("base_netsuite__accounts") }}
),
accounting_periods as (
    select * from {{ ref("base_netsuite__accounting_periods") }}
),
subsidiaries as (
    select * from {{ ref("stg_netsuite__subsidiaries") }}
),
customers as (
    select * from {{ ref("base_netsuite__customers") }}
),
items as (
    select * from {{ ref("base_netsuite__items") }}
),
locations as (
    select * from {{ ref("base_netsuite__locations") }}
),
departments as (
    select * from {{ ref("stg_netsuite__departments") }}
),
currencies as (
    select * from {{ ref("stg_netsuite__currencies") }}
),
classes as (
    select * from {{ ref("stg_netsuite__classes") }}
),
budget_details as (
    
    select
        budgets_with_converted_amounts.budget_id,
        budgets_with_converted_amounts.budget_category,
        budgets_with_converted_amounts.budget_accounting_period_id,
        accounting_periods.starting_at as accounting_period_starting,
        accounting_periods.ending_at as accounting_period_ending,
        accounting_periods.accounting_period_name,
        accounting_periods.is_adjustment as is_accounting_period_adjustment,
        accounting_periods.is_closed as is_accounting_period_closed,
        budgets_with_converted_amounts.account_id,
        accounts.account_name,
        accounts.account_type_name,
        accounts.account_number,
        accounts.account_number_and_name,
        accounts.is_leftside as is_account_leftside,
        accounts.is_accounts_payable,
        accounts.is_accounts_receivable,
        accounts.is_account_intercompany,
        coalesce(parent_account.account_name, accounts.account_name) as parent_account_name,
        accounts.is_expense_account, -- includes deferred expense
        accounts.is_income_account,
        budgets_with_converted_amounts.customer_id,
        customers.company_name,
        customers.customer_name,
        customers.customer_city,
        customers.customer_state,
        customers.customer_zip_code,
        customers.customer_country,
        customers.customer_external_id,
        budgets_with_converted_amounts.class_id,
        classes.class_full_name,
        budgets_with_converted_amounts.item_id,
        items.item_name,
        items.item_type_name,
        items.item_sales_description,
        budgets_with_converted_amounts.location_id,
        locations.location_name,
        locations.location_city,
        locations.location_country,
        budgets_with_converted_amounts.currency_id,
        currencies.currency_name,
        currencies.currency_symbol,
        budgets_with_converted_amounts.department_id,
        departments.department_name,
        budgets_with_converted_amounts.subsidiary_id,
        subsidiaries.subsidiary_name,

        case
            when lower(accounts.account_type_name) = 'income' or lower(accounts.account_type_name) = 'other income' then - converted_amount_using_budget_accounting_period
            else converted_amount_using_budget_accounting_period
        end as converted_amount,

        case
            when lower(accounts.account_type_name) = 'income' or lower(accounts.account_type_name) = 'other income' then - budgets_with_converted_amounts.unconverted_amount
            else budgets_with_converted_amounts.unconverted_amount
        end as unconverted_amount

    from budgets_with_converted_amounts

    left join accounts 
        on accounts.account_id = budgets_with_converted_amounts.account_id
    
    left join accounts as parent_account 
        on parent_account.account_id = accounts.parent_id
    
    left join accounting_periods
        on accounting_periods.accounting_period_id = budgets_with_converted_amounts.budget_accounting_period_id
    
    left join customers 
        on customers.customer_id = budgets_with_converted_amounts.customer_id
    
    left join classes 
        on classes.class_id = budgets_with_converted_amounts.class_id
    
    left join items 
        on items.item_id = budgets_with_converted_amounts.item_id
    
    left join locations 
        on locations.location_id = budgets_with_converted_amounts.location_id
    
    left join currencies 
        on currencies.currency_id = budgets_with_converted_amounts.currency_id
    
    left join departments 
        on departments.department_id = budgets_with_converted_amounts.department_id
    
    left join subsidiaries 
        on subsidiaries.subsidiary_id = budgets_with_converted_amounts.subsidiary_id
    where
        (accounting_periods.fiscal_calendar_id is null
        or accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null))
)
select * from budget_details
