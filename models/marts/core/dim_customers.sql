with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_history as (
    select * from {{ ref('int_customer_order_history') }}
),

final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customers.full_name,

        coalesce(customer_history.number_of_orders, 0)              as number_of_orders,
        coalesce(customer_history.lifetime_value, 0)                as lifetime_value,
        coalesce(customer_history.completed_order_value, 0)         as completed_order_value,
        coalesce(customer_history.number_of_returns, 0)             as number_of_returns,
        coalesce(customer_history.number_of_pending_returns, 0)     as number_of_pending_returns,
        customer_history.first_order_date,
        customer_history.most_recent_order_date,

        case
            when customer_history.number_of_orders is null then 'no_orders'
            when customer_history.number_of_orders = 1 then 'new'
            when customer_history.number_of_orders between 2 and 4 then 'regular'
            else 'vip'
        end as customer_segment
    from customers
    left join customer_history using (customer_id)
)

select * from final
