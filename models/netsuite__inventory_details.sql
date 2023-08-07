{{ config(enabled=(var('netsuite__inventory_management_enabled', false))) }}

with transaction_details as (
    select * from {{ ref('netsuite__transaction_details') }}
), 
inventory_transactions as (
    select
        transaction_id,
        transaction_line_id,
        transaction_memo,
        transaction_status,
        transaction_date,
        transaction_type,
        transaction_name,
        transaction_number
        accounting_period_id,
        accounting_period_starting,
        accounting_period_ending,
        accounting_period_name,
        is_accounting_period_closed,
        account_name,
        account_type_name,
        account_id,
        account_number,
        account_number_and_name,
        location_id,
        location_name
        item_id,
        item_name
        converted_amount,
        transaction_amount,
        quantity,

        sum(quantity) over (partition by item_id, location_id order by transaction_date, transaction_id, transaction_line_id) as inventory_quantity_balance,
        sum(transaction_amount) over (partition by item_id, location_id order by transaction_date, transaction_id, transaction_line_id) as inventory_value_balance

        --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
        {% if var('inventory_transaction_detail_columns') %}
        , transaction_details.{{ var('inventory_transaction_detail_columns') | join (", transaction_details.")}}
        {% endif %}

    from transaction_details
    
    where (is_inventory_affecting and not is_voided)
            or (lower(accounting_line_type) = 'asset' and lower(transaction_memo) = 'cost of sales adjustment')
)
select * from inventory_transactions
