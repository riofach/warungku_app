create or replace function get_top_selling_items(
  start_date timestamptz,
  end_date timestamptz,
  limit_count int default 10
)
returns json
language plpgsql
as $$
declare
  result json;
begin
  select json_agg(t)
  into result
  from (
    select
      i.id as item_id,
      i.name as item_name,
      sum(ti.quantity) as total_quantity,
      sum(ti.subtotal) as total_revenue
    from transaction_items ti
    join transactions tr on ti.transaction_id = tr.id
    join items i on ti.item_id = i.id
    where tr.created_at >= start_date
      and tr.created_at <= end_date
    group by i.id, i.name
    order by total_quantity desc
    limit limit_count
  ) t;

  return coalesce(result, '[]'::json);
end;
$$;
