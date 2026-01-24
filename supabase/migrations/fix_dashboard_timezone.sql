-- Fix dashboard summary timezone issue (UTC vs Asia/Jakarta)
-- Previous implementation used CURRENT_DATE which is UTC on Supabase, causing 
-- early morning Jakarta transactions (UTC+7) to be counted as "yesterday" in UTC, 
-- or "yesterday's" late transactions to be counted as "today".

CREATE OR REPLACE FUNCTION get_dashboard_summary()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_omset BIGINT;
  v_profit BIGINT;
  v_count INTEGER;
  v_today_jakarta DATE;
BEGIN
  -- Define "today" based on Jakarta timezone
  v_today_jakarta := (now() AT TIME ZONE 'Asia/Jakarta')::date;

  -- Get today's omset (total revenue)
  SELECT COALESCE(SUM(total), 0)
  INTO v_omset
  FROM transactions
  WHERE (created_at AT TIME ZONE 'Asia/Jakarta')::date = v_today_jakarta;

  -- Get today's profit from transaction_items
  SELECT COALESCE(SUM((sell_price - buy_price) * quantity), 0)
  INTO v_profit
  FROM transaction_items ti
  JOIN transactions t ON t.id = ti.transaction_id
  WHERE (t.created_at AT TIME ZONE 'Asia/Jakarta')::date = v_today_jakarta;

  -- Get today's transaction count
  SELECT COUNT(*)
  INTO v_count
  FROM transactions
  WHERE (created_at AT TIME ZONE 'Asia/Jakarta')::date = v_today_jakarta;

  RETURN jsonb_build_object(
    'omset', v_omset,
    'profit', v_profit,
    'transaction_count', v_count,
    'date', v_today_jakarta
  );
END;
$$;
