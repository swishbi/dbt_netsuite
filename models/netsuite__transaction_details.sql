with transactions_with_converted_amounts as (
    select * from {{ ref('int_netsuite__tran_with_converted_amounts') }}
),

accounts as (
    select * from {{ var('netsuite_accounts') }}
),

accounting_periods as (
    select * from {{ var('netsuite_accounting_periods') }}
),

subsidiaries as (
    select * from {{ var('netsuite_subsidiaries') }}
),

transaction_lines as (
    select * from {{ var('netsuite_transaction_lines') }}
),

transactions as (
    select * from {{ var('netsuite_transactions') }}
),

customers as (
    select * from {{ var('netsuite_customers') }}
),

employees as (
    select * from {{ var('netsuite_employees') }}
),

entities as (
    select * from {{ var('netsuite_entities') }}
),

items as (
    select * from {{ var('netsuite_items') }}
),

{% if var('netsuite__using_jobs', false) %}
jobs as (
    select * from {{ var('netsuite_jobs') }}
),
{% endif %}

locations as (
    select * from {{ var('netsuite_locations') }}
),

vendors as (
    select * from {{ var('netsuite_vendors') }}
),

departments as (
    select * from {{ var('netsuite_departments') }}
),

{% if var('netsuite__multiple_currencies_enabled', false) %}
currencies as (
    select * from {{ var('netsuite_currencies') }}
),
{% endif %}

classes as (
    select * from {{ var('netsuite_classes') }}
),

transaction_details as (
    select
        transaction_lines.transaction_line_id,
        transaction_lines.memo as transaction_memo,
        not transaction_lines.is_posting as is_transaction_non_posting,
        transactions.transaction_id,
        transactions.transaction_status_name as transaction_status,
        transactions.transaction_date,
        transactions.transaction_due_date,
        transactions.transaction_type,
        transactions.transaction_name,
        transactions.transaction_number,
        transaction_lines.rate_amount,
        transaction_lines.quantity,
        transactions.is_voided
        {% if var('netsuite__inventory_management_enabled', false) %}
        ,transaction_lines.is_inventory_affecting
        ,transaction_lines.accounting_line_type
        {% endif %}

        --The below script allows for transaction line table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='transaction_lines_pass_through_columns', identifier='transaction_lines', transform='') }}

        --The below script allows for transaction table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='transactions_pass_through_columns', identifier='transactions', transform='') }},

        transactions.accounting_period_id,
        accounting_periods.starting_at as accounting_period_starting,
        accounting_periods.ending_at as accounting_period_ending,
        accounting_periods.accounting_period_name,
        accounting_periods.is_adjustment as is_accounting_period_adjustment,
        accounting_periods.is_closed as is_accounting_period_closed,

        transaction_lines.account_id,
        accounts.account_name,
        accounts.account_type_name,
        accounts.account_number,
        accounts.account_number_and_name,
        accounts.is_leftside as is_account_leftside,
        accounts.is_accounts_payable,
        accounts.is_accounts_receivable,
        accounts.is_account_intercompany,
        parent_account.account_name as parent_account_name,
        accounts.is_expense_account,
        accounts.is_income_account

        --The below script allows for accounts table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='accounts_pass_through_columns', identifier='accounts', transform='') }},

        coalesce(transaction_lines.entity_id, transactions.entity_id) as entity_id,
        entities.entity_title,
        entities.entity_type

        --The below script allows for entity table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='entities_pass_through_columns', identifier='entities', transform='') }},

        customers.customer_id,
        customers.company_name,
        customers.customer_name,
        customers.customer_city,
        customers.customer_state,
        customers.customer_zip_code,
        customers.customer_country,
        customers.customer_external_id
        {% if var('netsuite__using_customer_categories', false) %}
        ,customers.customer_category_name
        {% endif %}

        --The below script allows for customers table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='customers_pass_through_columns', identifier='customers', transform='') }},
        
        {% if var('netsuite__using_jobs', false) %}
        jobs.job_id,
        jobs.job_name,
        jobs.job_full_name,
        jobs.job_type_name,
        jobs.job_status_name
        
        --The below script allows for jobs table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='jobs_pass_through_columns', identifier='jobs', transform='') }},
        {% endif %}
        
        transaction_lines.class_id,
        classes.class_full_name
        
        --The below script allows for class table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='classes_pass_through_columns', identifier='classes', transform='') }},
        
        transaction_lines.item_id,
        items.item_name,
        items.item_type_name,
        items.item_sales_description
        
        --The below script allows for items table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='items_pass_through_columns', identifier='items', transform='') }},
        
        transaction_lines.location_id,
        locations.location_name,
        locations.location_city,
        locations.location_country
        
        --The below script allows for locations table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='locations_pass_through_columns', identifier='locations', transform='') }},
        
        coalesce(transaction_lines.entity_id, transactions.entity_id) as vendor_id,
        vendors.vendor_name,
        vendors.vendor_create_date
        {% if var('netsuite__using_vendor_categories', false) %}
        ,vendors.vendor_category_name
        {% endif %}
        
        --The below script allows for vendors table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='vendors_pass_through_columns', identifier='vendors', transform='') }},
        
        {% if var('netsuite__multiple_currencies_enabled', false) %}
        transactions.currency_id,
        currencies.currency_name,
        currencies.currency_symbol,
        {% endif %}
        
        transaction_lines.department_id,
        departments.department_name
        
        --The below script allows for departments table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='departments_pass_through_columns', identifier='departments', transform='') }},
        
        transaction_lines.subsidiary_id,
        subsidiaries.subsidiary_name
        
        --The below script allows for subsidiaries table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='subsidiaries_pass_through_columns', identifier='subsidiaries', transform='') }},
        
        transactions.employee_id as sales_rep_id,
        employees.employee_name_last_first as sales_rep_name_last_first,
        employees.employee_name_first_last as sales_rep_name_first_last,

        case
            when accounts.is_income_account
            then -converted_amount_using_transaction_accounting_period
            else converted_amount_using_transaction_accounting_period
        end as converted_amount,

        case
            when accounts.is_income_account
            then -transaction_lines.amount
            else transaction_lines.amount
        end as transaction_amount,

        case
            when accounts.is_income_account
            then -converted_paid_amount_using_transaction_accounting_period
            else converted_paid_amount_using_transaction_accounting_period
        end as converted_paid_amount,

        case
            when accounts.is_income_account
            then -converted_unpaid_amount_using_transaction_accounting_period
            else converted_unpaid_amount_using_transaction_accounting_period
        end as converted_unpaid_amount,

        -converted_amount_using_transaction_accounting_period as converted_income_statement_amount

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
    
    {% if var('netsuite__using_jobs', false) %}
    left join jobs
        on jobs.job_id = coalesce(transaction_lines.entity_id, transactions.entity_id)

    left join customers
        on customers.customer_id = coalesce(jobs.customer_id, transaction_lines.entity_id, transactions.entity_id)
    {% else %}
    left join customers
        on customers.customer_id = coalesce(transaction_lines.entity_id, transactions.entity_id)
    {% endif %}
    
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
    
    {% if var('netsuite__multiple_currencies_enabled', false) %}
    left join currencies 
        on currencies.currency_id = transactions.currency_id
    {% endif %}
    
    left join departments 
        on departments.department_id = transaction_lines.department_id
    
    left join subsidiaries 
        on subsidiaries.subsidiary_id = transaction_lines.subsidiary_id
    
    {% if var('netsuite__multiple_calendars_enabled', false) %}
    where
        (accounting_periods.fiscal_calendar_id is null
        or accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null))
    {% endif %}
)
select * from transaction_details
