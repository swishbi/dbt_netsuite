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
transaction_lines as (
    select * from {{ ref('base_netsuite__transaction_lines') }}
),
transactions as (
    select * from {{ ref('base_netsuite__transactions') }}
),
customers as (
    select * from {{ ref('base_netsuite__customers') }}
),
employees as (
    select * from {{ ref('base_netsuite__employees') }}
),
entities as (
    select * from {{ ref('base_netsuite__entities') }}
),
items as (
    select * from {{ ref('base_netsuite__items') }}
),
jobs as (
    select * from {{ ref('base_netsuite__jobs') }}
),
locations as (
    select * from {{ ref('base_netsuite__locations') }}
),
vendors as (
    select * from {{ ref('base_netsuite__vendors') }}
),
departments as (
    select * from {{ var('netsuite_departments') }}
),
currencies as (
    select * from {{ var('netsuite_currencies') }}
),
classes as (
    select * from {{ var('netsuite_classes') }}
),
transaction_details as (
    select
        transaction_lines.transaction_line_id,
        transaction_lines.memo as transaction_memo,
        not transaction_lines.is_posting as is_transaction_non_posting,
        transaction_lines.is_cogs as is_cost_of_goods_sold,
        transaction_lines.is_billable,
        transaction_lines.is_closed,
        transaction_lines.is_inventory_affecting as is_transaction_inventory_affecting,
        transaction_lines.is_drop_shipment,
        transaction_lines.is_special_order,
        transaction_lines.rate,
        transaction_lines.cost_estimate_rate,
        transaction_lines.quantity,
        transaction_lines.quantity_packed,
        transaction_lines.quantity_picked,
        transaction_lines.quantity_shipped_received,
        transaction_lines.quantity_billed,
        transaction_lines.quantity_committed,
        transaction_lines.quantity_back_ordered
        --The below script allows for accounts table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='transaction_lines_pass_through_columns', identifier='transaction_lines', transform='') }},
        datediff(transaction_lines.actual_ship_date, transactions.transaction_date) as days_to_ship,
        datediff(transactions.transaction_closed_date, transactions.transaction_date) as days_to_close,
        transactions.transaction_id,
        transactions.transaction_status_name,
        transactions.transaction_date,
        transactions.transaction_due_date,
        transactions.transaction_closed_date,
        transactions.transaction_expected_close_date,
        transactions.transaction_name,
        transactions.transaction_number,
        transactions.transaction_type,
        transactions.is_transaction_voided,
        transactions.is_transaction_intercompany_adjustment,
        transactions.transaction_url_link
        --The below script allows for accounts table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='transactions_pass_through_columns', identifier='transactions', transform='') }},
        transactions.accounting_period_id,
        accounting_periods.starting_at as accounting_period_starting,
        accounting_periods.ending_at as accounting_period_ending,
        accounting_periods.accounting_period_name,
        accounting_periods.is_adjustment as is_accounting_period_adjustment,
        accounting_periods.is_closed as is_accounting_period_closed,
        accounts.account_name,
        accounts.account_type_name,
        accounts.account_id,
        accounts.account_number,
        accounts.account_number_and_name
        --The below script allows for accounts table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='accounts_pass_through_columns', identifier='accounts', transform='') }},
        accounts.is_leftside as is_account_leftside,
        accounts.is_accounts_payable,
        accounts.is_accounts_receivable,
        accounts.is_account_intercompany,
        parent_account.account_name as parent_account_name,
        accounts.is_expense_account,
        accounts.is_income_account,
        coalesce(transaction_lines.entity_id, transactions.entity_id) as entity_id,
        entities.entity_title,
        entities.entity_type,
        customers.customer_id,
        customers.company_name,
        customers.customer_name,
        customers.customer_city,
        customers.customer_state,
        customers.customer_zip_code,
        customers.customer_country,
        customers.customer_external_id,
        jobs.job_id,
        jobs.job_name,
        jobs.job_full_name,
        jobs.job_type_name,
        jobs.job_status_name,
        coalesce(transaction_lines.class_id, items.class_id) as class_id,
        classes.class_full_name,
        transaction_lines.item_id,
        items.item_name,
        items.item_type_name,
        items.item_sales_description,
        transaction_lines.location_id,
        locations.location_name,
        locations.location_city,
        locations.location_country,
        coalesce(transaction_lines.entity_id, transactions.entity_id) as vendor_id,
        vendors.vendor_category_name,
        vendors.vendor_name,
        vendors.vendor_create_date,
        transactions.currency_id,
        currencies.currency_name,
        currencies.currency_symbol,
        transaction_lines.department_id,
        departments.department_name
        --The below script allows for accounts table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='departments_pass_through_columns', identifier='departments', transform='') }},
        transaction_lines.subsidiary_id,
        subsidiaries.subsidiary_name,
        transactions.employee_id as sales_rep_id,
        employees.employee_name_last_first as sales_rep_name_last_first,
        employees.employee_name_first_last as sales_rep_name_first_last,

        case
            when accounts.is_income_account
            then - converted_amount_using_transaction_accounting_period
            else converted_amount_using_transaction_accounting_period
        end as converted_amount,

        case
            when accounts.is_income_account
            then - transaction_lines.amount
            else transaction_lines.amount
        end as transaction_amount,

        case
            when accounts.is_income_account
            then - converted_paid_amount_using_transaction_accounting_period
            else converted_paid_amount_using_transaction_accounting_period
        end as converted_paid_amount,

        case
            when accounts.is_income_account
            then - converted_unpaid_amount_using_transaction_accounting_period
            else converted_unpaid_amount_using_transaction_accounting_period
        end as converted_unpaid_amount,

        - converted_amount_using_transaction_accounting_period as converted_income_statement_amount

    from transaction_lines
    
    join transactions
        on transactions.transaction_id = transaction_lines.transaction_id
    
    left join transactions_with_converted_amounts as transactions_with_converted_amounts
        on transactions_with_converted_amounts.transaction_line_id = transaction_lines.transaction_line_id
        and transactions_with_converted_amounts.transaction_id = transaction_lines.transaction_id
        and transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
    
    left join accounts 
        on accounts.account_id = transaction_lines.account_id
    
    left join accounts as parent_account 
        on parent_account.account_id = accounts.parent_id
    
    left join accounting_periods
        on accounting_periods.accounting_period_id = transactions.accounting_period_id
    
    left join jobs
        on jobs.job_id = coalesce(transaction_lines.entity_id, transactions.entity_id)
    
    left join customers
        on customers.customer_id = coalesce(jobs.customer_id, transaction_lines.entity_id, transactions.entity_id)
    
    left join items 
        on items.item_id = transaction_lines.item_id
    
    left join classes
        on classes.class_id = coalesce(transaction_lines.class_id, items.class_id)

    left join employees 
        on employees.employee_id = transactions.employee_id
    
    left join entities
        on entities.entity_id = coalesce(transaction_lines.entity_id, transactions.entity_id)
    
    left join locations 
        on locations.location_id = transaction_lines.location_id
    
    left join vendors
        on vendors.vendor_id = coalesce(transaction_lines.entity_id, transactions.entity_id)
    
    left join currencies 
        on currencies.currency_id = transactions.currency_id
    
    left join departments 
        on departments.department_id = transaction_lines.department_id
    
    left join subsidiaries 
        on subsidiaries.subsidiary_id = transaction_lines.subsidiary_id
    
    where
        (accounting_periods.fiscal_calendar_id is null
        or accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null))
)
select * from transaction_details
