with transactions_with_converted_amounts as (
    select * from {{ ref('int_netsuite__tran_with_converted_amounts') }}
), 
accounts as (
    select * from {{ ref('base_netsuite__accounts') }}
), 
accounting_periods as (
    select * from {{ ref('base_netsuite__accounting_periods') }}
), 
subsidiaries as (
    select * from {{ var('netsuite_subsidiaries') }}
),
balance_sheet as (

    select
        transactions_with_converted_amounts.transaction_id,
        transactions_with_converted_amounts.transaction_line_id,
        transactions_with_converted_amounts.entity_id,
        reporting_accounting_periods.accounting_period_id,
        reporting_accounting_periods.starting_at as accounting_period_starting,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.accounting_period_name,
        reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
        reporting_accounting_periods.is_closed as is_accounting_period_closed,
        transactions_with_converted_amounts.account_category,

        case
            when (not accounts.is_balancesheet 
                and date_trunc('year', reporting_accounting_periods.starting_at) = date_trunc('year', transaction_accounting_periods.starting_at)
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
            when not accounts.is_balancesheet then 'Retained Earnings'
            else accounts.account_name
        end as account_name,
        
        case
            when (not accounts.is_balancesheet 
                and date_trunc('year', reporting_accounting_periods.starting_at) = date_trunc('year', transaction_accounting_periods.starting_at)
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
            when not accounts.is_balancesheet then 'Retained Earnings'
            else accounts.account_number_and_name
        end as account_number_and_name,

        case
            when (not accounts.is_balancesheet 
                and date_trunc('year', reporting_accounting_periods.starting_at) = date_trunc('year', transaction_accounting_periods.starting_at) 
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
            when not accounts.is_balancesheet then 'Retained Earnings'
            else accounts.account_type_name
        end as account_type_name,

        case
            when not accounts.is_balancesheet then null
            else accounts.account_id
        end as account_id,

        case
            when not accounts.is_balancesheet then null
            else accounts.account_number
        end as account_number

        --The below script allows for accounts table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='accounts_pass_through_columns', identifier='accounts', transform='') }},
        
        case
            when not accounts.is_balancesheet or lower(transactions_with_converted_amounts.account_category) = 'equity' then -converted_amount_using_transaction_accounting_period
            when not accounts.is_leftside then -converted_amount_using_reporting_month
            when accounts.is_leftside then converted_amount_using_reporting_month
            else 0
        end as converted_amount,

        case
            when lower(accounts.account_type_name) = 'bank' then 1
            when lower(accounts.account_type_name) = 'accounts receivable' then 2
            when lower(accounts.account_type_name) = 'unbilled receivable' then 3
            when lower(accounts.account_type_name) = 'other current asset' then 4
            when lower(accounts.account_type_name) = 'fixed asset' then 5
            when lower(accounts.account_type_name) = 'other asset' then 6
            when lower(accounts.account_type_name) = 'deferred expense' then 7
            when lower(accounts.account_type_name) = 'accounts payable' then 8
            when lower(accounts.account_type_name) = 'credit card' then 9
            when lower(accounts.account_type_name) = 'other current liability' then 10
            when lower(accounts.account_type_name) = 'long term liability' then 11
            when lower(accounts.account_type_name) = 'deferred revenue' then 12
            when lower(accounts.account_type_name) = 'equity' then 13
            when (not accounts.is_balancesheet 
                and date_trunc('year', reporting_accounting_periods.starting_at) = date_trunc('year', transaction_accounting_periods.starting_at) 
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 15
            when not accounts.is_balancesheet then 14
            else null
        end as balance_sheet_sort_helper

    from transactions_with_converted_amounts
    
    left join accounts 
        on accounts.account_id = transactions_with_converted_amounts.account_id
    
    left join accounting_periods as reporting_accounting_periods 
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
    
    left join accounting_periods as transaction_accounting_periods 
        on transaction_accounting_periods.accounting_period_id = transactions_with_converted_amounts.transaction_accounting_period_id
        where coalesce(reporting_accounting_periods.fiscal_calendar_id,1) = coalesce((select fiscal_calendar_id from subsidiaries where parent_id is null),1)
        and coalesce(transaction_accounting_periods.fiscal_calendar_id,1) = coalesce((select fiscal_calendar_id from subsidiaries where parent_id is null),1)
        and (accounts.is_balancesheet or transactions_with_converted_amounts.is_income_statement)
    
    union all
    
    select
        transactions_with_converted_amounts.transaction_id,
        transactions_with_converted_amounts.transaction_line_id,
        transactions_with_converted_amounts.entity_id,
        reporting_accounting_periods.accounting_period_id,
        reporting_accounting_periods.starting_at as accounting_period_starting,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.accounting_period_name,
        reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
        reporting_accounting_periods.is_closed as is_accounting_period_closed,

        'Equity' as account_category,
        'Cumulative Translation Adjustment' as account_name,
        'Cumulative Translation Adjustment' as account_number_and_name,
        'Cumulative Translation Adjustment' as account_type_name,
        null as account_id,
        null as account_number,

        case
            when lower(transactions_with_converted_amounts.account_category) = 'equity' or transactions_with_converted_amounts.is_income_statement then converted_amount_using_transaction_accounting_period
            else converted_amount_using_reporting_month
            end as converted_amount,
        16 as balance_sheet_sort_helper

    from transactions_with_converted_amounts
    
    left join accounts
        on accounts.account_id = transactions_with_converted_amounts.account_id
    
    left join accounting_periods as reporting_accounting_periods 
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
    
    where 
        coalesce(reporting_accounting_periods.fiscal_calendar_id, 1) = coalesce((select fiscal_calendar_id from subsidiaries where parent_id is null), 1)
        and (accounts.is_balancesheet or transactions_with_converted_amounts.is_income_statement)
)
select * from balance_sheet