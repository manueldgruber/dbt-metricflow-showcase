{% macro cents_to_dollars(column_name, scale=2) %}
    ({{ column_name }} / 100.0)::numeric(16, {{ scale }})
{% endmacro %}
