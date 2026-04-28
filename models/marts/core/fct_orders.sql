with orders as (
    select * from {{ ref('int_orders_with_payments') }}
),

final as (
    select
        order_id,
        customer_id,
        order_date,
        status,

        amount,
        credit_card_amount,
        coupon_amount,
        bank_transfer_amount,
        gift_card_amount,

        case
            when status = 'completed' then true
            else false
        end as is_completed,

        case
            when status in ('returned', 'return_pending') then true
            else false
        end as is_returned
    from orders
)

select * from final
