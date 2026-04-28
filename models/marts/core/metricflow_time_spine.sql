{{
    config(
        materialized = 'table',
    )
}}

select cast(range as date) as date_day
from range(
    cast('2017-01-01' as timestamp),
    cast('2030-01-01' as timestamp),
    interval '1 day'
)
