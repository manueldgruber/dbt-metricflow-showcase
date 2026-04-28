-- Every customer lifetime value must be non-negative
select
    customer_id,
    lifetime_value
from {{ ref('dim_customers') }}
where lifetime_value < 0
