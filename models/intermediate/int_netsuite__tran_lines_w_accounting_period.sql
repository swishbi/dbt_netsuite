with transactions as (
    select * from {{ ref('base_netsuite__transactions') }}
),
transaction_lines as (
    select * from {{ ref('base_netsuite__transaction_lines') }}
),
transaction_lines_w_accounting_period as (
    -- transaction line totals, by accounts, accounting period, entity, and subsidiary
    select
        transaction_lines.transaction_id,
        transaction_lines.transaction_line_id,
        transaction_lines.subsidiary_id,
        transaction_lines.account_id,
        coalesce(transaction_lines.entity_id, transactions.entity_id) as entity_id,
        transactions.accounting_period_id as transaction_accounting_period_id,
        coalesce(transaction_lines.amount, 0) as unconverted_amount,
        coalesce(transaction_lines.net_amount, 0) as unconverted_net_amount,
        coalesce(transaction_lines.credit_amount, 0) as unconverted_credit_amount,
        coalesce(transaction_lines.debit_amount, 0) as unconverted_debit_amount,
        coalesce(transaction_lines.paid_amount, 0) as unconverted_paid_amount,
        coalesce(transaction_lines.unpaid_amount, 0) as unconverted_unpaid_amount
        
    from transaction_lines
    
    join transactions 
        on transactions.transaction_id = transaction_lines.transaction_id
    
    where
        lower(transactions.transaction_type) != 'revenue arrangement'
        and transaction_lines.is_posting
)
select * from transaction_lines_w_accounting_period