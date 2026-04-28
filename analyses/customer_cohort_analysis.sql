-- Cohort analysis: revenue by customer acquisition month
with customers as (
    select
        customer_id,
        date_trunc('month', first_order_date) as cohort_month
    from {{ ref('dim_customers') }}
    where first_order_date is not null
),

orders as (
    select
        customer_id,
        order_date,
        amount,
        date_trunc('month', order_date) as order_month
    from {{ ref('fct_orders') }}
),

cohort_data as (
    select
        customers.cohort_month,
        orders.order_month,
        datediff('month', customers.cohort_month, orders.order_month) as months_since_acquisition,
        count(distinct orders.customer_id) as active_customers,
        sum(orders.amount) as revenue
    from customers
    inner join orders using (customer_id)
    group by 1, 2, 3
)

select * from cohort_data
order by cohort_month, months_since_acquisition
