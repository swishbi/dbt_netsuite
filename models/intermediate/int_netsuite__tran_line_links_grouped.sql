with transaction_line_links as (
    select * from {{ var('netsuite_previous_transaction_line_links') }}
),
grouped as (
    select
        previous_transaction_id,
        previous_transaction_line_id,
        previous_transaction_type,
        next_transaction_id,
        next_transaction_line_id,
        next_transaction_type,
        max(last_modified_date) as last_modified_date
    from transaction_line_links
    {{ dbt_utils.group_by(n=6) }}
)
select * from grouped