with transactions_with_converted_amounts as (
    select * from {{ ref('int_netsuite__tran_with_converted_amounts') }}
), 

--Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
{% if var('income_statement_transaction_detail_columns') != []%}
transaction_details as (
    select * 
    from {{ ref('netsuite__transaction_details') }}
), 
{% endif %}

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

classes as (
    select * from {{ var('netsuite_classes') }}
),

locations as (
    select * from {{ var('netsuite_locations') }}
),

departments as (
    select * from {{ var('netsuite_departments') }}
),

income_statement as (

    select
        transactions_with_converted_amounts.transaction_id,
        transactions_with_converted_amounts.transaction_line_id,
        reporting_accounting_periods.accounting_period_id as accounting_period_id,
        reporting_accounting_periods.starting_at as accounting_period_starting,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.accounting_period_name,
        reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
        reporting_accounting_periods.is_closed as is_accounting_period_closed,
        accounts.account_name,
        accounts.account_type_name,
        accounts.account_id,
        accounts.account_number,
        accounts.account_number_and_name,
        subsidiaries.subsidiary_id,
        subsidiaries.subsidiary_full_name,
        subsidiaries.subsidiary_name

        --The below script allows for accounts table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='accounts_pass_through_columns', identifier='accounts', transform='') }},
        
        transaction_lines.class_id,
        classes.class_full_name
        
        --The below script allows for classes table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='classes_pass_through_columns', identifier='classes', transform='') }},
        
        transaction_lines.location_id,
        locations.location_full_name,
        
        transaction_lines.department_id,
        departments.department_full_name
        
        --The below script allows for departments table pass through columns.
        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='departments_pass_through_columns', identifier='departments', transform='') }},
        
        transactions_with_converted_amounts.account_category,

        case 
            when lower(accounts.account_type_name) = 'income' then 1
            when lower(accounts.account_type_name) = 'cost of goods sold' then 2
            when lower(accounts.account_type_name) = 'expense' then 3
            when lower(accounts.account_type_name) = 'other income' then 4
            when lower(accounts.account_type_name) = 'other expense' then 5
            else null
        end as income_statement_sort_helper

        --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
        {% if var('income_statement_transaction_detail_columns') %}
        , transaction_details.{{ var('income_statement_transaction_detail_columns') | join (", transaction_details.")}}
        {% endif %}

        , -converted_amount_using_transaction_accounting_period as converted_amount
        , -unconverted_amount as unconverted_amount

    from transactions_with_converted_amounts
    
    join transaction_lines as transaction_lines
        on transaction_lines.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
            and transaction_lines.transaction_id = transactions_with_converted_amounts.transaction_id
    
    left join departments 
        on departments.department_id = transaction_lines.department_id
    
    left join accounts 
        on accounts.account_id = transactions_with_converted_amounts.account_id
    
    left join locations
        on locations.location_id = transaction_lines.location_id
    
    left join classes 
        on classes.class_id = transaction_lines.class_id
    
    left join accounting_periods as reporting_accounting_periods 
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
    
    left join subsidiaries
        on transactions_with_converted_amounts.subsidiary_id = subsidiaries.subsidiary_id
    
    --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
    {% if var('income_statement_transaction_detail_columns') != []%}
    join transaction_details
        on transaction_details.transaction_id = transactions_with_converted_amounts.transaction_id
        and transaction_details.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
    {% endif %}
    
    where transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
        and transactions_with_converted_amounts.is_income_statement
        {% if var('netsuite__multiple_calendars_enabled', false) %}
        and reporting_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
        {% endif %}
)
select * from income_statement
