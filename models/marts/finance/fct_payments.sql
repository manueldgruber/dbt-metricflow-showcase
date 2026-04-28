with payments as (
    select * from {{ ref('stg_payments') }}
),

orders as (
    select
        order_id,
        customer_id,
        order_date,
        status
    from {{ ref('fct_orders') }}
),

final as (
    select
        payments.payment_id,
        payments.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status    as order_status,
        payments.payment_method,
        payments.amount
    from payments
    left join orders using (order_id)
)

select * from final
