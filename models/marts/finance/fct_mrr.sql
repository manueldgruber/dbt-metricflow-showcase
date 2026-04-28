-- Monthly revenue aggregation for finance reporting
with orders as (
    select * from {{ ref('fct_orders') }}
),

monthly as (
    select
        date_trunc('month', order_date)     as revenue_month,
        count(distinct order_id)             as orders_count,
        count(distinct customer_id)          as customers_count,
        sum(amount)                          as gross_revenue,
        sum(case when is_completed then amount else 0 end) as net_revenue,
        sum(case when is_returned then amount else 0 end)  as returned_revenue,
        sum(credit_card_amount)              as credit_card_revenue,
        sum(coupon_amount)                   as coupon_revenue,
        sum(bank_transfer_amount)            as bank_transfer_revenue,
        sum(gift_card_amount)                as gift_card_revenue
    from orders
    group by 1
)

select * from monthly
order by 1
