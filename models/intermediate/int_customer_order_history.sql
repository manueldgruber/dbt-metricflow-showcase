with orders as (
    select * from {{ ref('int_orders_with_payments') }}
),

final as (
    select
        customer_id,
        count(order_id)                                                   as number_of_orders,
        min(order_date)                                                   as first_order_date,
        max(order_date)                                                   as most_recent_order_date,
        sum(amount)                                                       as lifetime_value,
        sum(case when status = 'completed' then amount else 0 end)       as completed_order_value,
        count(case when status = 'returned' then 1 end)                  as number_of_returns,
        count(case when status = 'return_pending' then 1 end)            as number_of_pending_returns
    from orders
    group by 1
)

select * from final
