-- Update get_report_summary to include online orders (paid/completed only)
CREATE OR REPLACE FUNCTION get_report_summary(start_date TIMESTAMPTZ, end_date TIMESTAMPTZ)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  pos_rev BIGINT;
  pos_count INTEGER;
  pos_profit BIGINT;
  order_rev BIGINT;
  order_count INTEGER;
  order_profit BIGINT;
  total_rev BIGINT;
  total_count INTEGER;
  avg_val BIGINT;
  result JSON;
  v_start TIMESTAMPTZ;
  v_end TIMESTAMPTZ;
BEGIN
  v_start := start_date + INTERVAL '7 hours';
  v_end := end_date + INTERVAL '7 hours';

  -- POS transactions
  SELECT COALESCE(SUM(total), 0), COUNT(id)
  INTO pos_rev, pos_count
  FROM transactions
  WHERE created_at >= v_start AND created_at <= v_end;

  SELECT COALESCE(SUM((ti.price - ti.buy_price) * ti.quantity), 0)
  INTO pos_profit
  FROM transactions t
  JOIN transaction_items ti ON t.id = ti.transaction_id
  WHERE t.created_at >= v_start AND t.created_at <= v_end;

  -- Online orders (only paid/completed statuses)
  SELECT COALESCE(SUM(total), 0), COUNT(id)
  INTO order_rev, order_count
  FROM orders
  WHERE created_at >= v_start AND created_at <= v_end
    AND status IN ('paid', 'processing', 'ready', 'delivered', 'completed');

  SELECT COALESCE(SUM((oi.price - COALESCE(i.buy_price, 0)) * oi.quantity), 0)
  INTO order_profit
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  JOIN items i ON oi.item_id = i.id
  WHERE o.created_at >= v_start AND o.created_at <= v_end
    AND o.status IN ('paid', 'processing', 'ready', 'delivered', 'completed');

  total_rev := pos_rev + order_rev;
  total_count := pos_count + order_count;
  avg_val := CASE WHEN total_count > 0 THEN total_rev / total_count ELSE 0 END;

  SELECT json_build_object(
    'total_revenue', total_rev,
    'total_profit', pos_profit + order_profit,
    'transaction_count', total_count,
    'average_value', avg_val,
    'pos_count', pos_count,
    'pos_revenue', pos_rev,
    'order_count', order_count,
    'order_revenue', order_rev
  ) INTO result;

  RETURN result;
END;
$$;

-- Update get_top_selling_items to include items from online orders
CREATE OR REPLACE FUNCTION get_top_selling_items(
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  limit_count INT DEFAULT 10
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(t)
  INTO result
  FROM (
    SELECT
      item_id,
      item_name,
      SUM(qty) AS total_quantity,
      SUM(rev) AS total_revenue
    FROM (
      -- POS transaction items
      SELECT
        i.id AS item_id,
        i.name AS item_name,
        ti.quantity AS qty,
        ti.subtotal AS rev
      FROM transaction_items ti
      JOIN transactions tr ON ti.transaction_id = tr.id
      JOIN items i ON ti.item_id = i.id
      WHERE tr.created_at >= start_date AND tr.created_at <= end_date

      UNION ALL

      -- Online order items (paid/completed only)
      SELECT
        i.id AS item_id,
        i.name AS item_name,
        oi.quantity AS qty,
        oi.subtotal AS rev
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN items i ON oi.item_id = i.id
      WHERE o.created_at >= start_date AND o.created_at <= end_date
        AND o.status IN ('paid', 'processing', 'ready', 'delivered', 'completed')
    ) combined
    GROUP BY item_id, item_name
    ORDER BY total_quantity DESC
    LIMIT limit_count
  ) t;

  RETURN COALESCE(result, '[]'::json);
END;
$$;
