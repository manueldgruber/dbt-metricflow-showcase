with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

payment_totals as (
    select
        order_id,
        sum(amount)                                                         as total_amount,
        sum(case when payment_method = 'credit_card' then amount else 0 end) as credit_card_amount,
        sum(case when payment_method = 'coupon' then amount else 0 end)     as coupon_amount,
        sum(case when payment_method = 'bank_transfer' then amount else 0 end) as bank_transfer_amount,
        sum(case when payment_method = 'gift_card' then amount else 0 end)  as gift_card_amount
    from payments
    group by 1
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,
        coalesce(payment_totals.total_amount, 0)          as amount,
        coalesce(payment_totals.credit_card_amount, 0)    as credit_card_amount,
        coalesce(payment_totals.coupon_amount, 0)         as coupon_amount,
        coalesce(payment_totals.bank_transfer_amount, 0)  as bank_transfer_amount,
        coalesce(payment_totals.gift_card_amount, 0)      as gift_card_amount
    from orders
    left join payment_totals using (order_id)
)

select * from final
