-- ============================================================
-- SETUP MOBILE TABLES - warungku_app recovery script
-- ============================================================
-- Jalankan script ini setelah `php artisan migrate:fresh` di warungku_web
-- atau kapanpun database direset, agar warungku_app (Flutter) bisa berjalan normal.
--
-- Cara menjalankan:
--   1. Buka Supabase Dashboard → SQL Editor
--   2. Paste seluruh isi file ini → klik Run
--   3. Atau gunakan: supabase db push (jika supabase CLI terinstall)
--
-- Catatan: Script ini IDEMPOTENT (aman dijalankan berkali-kali)
-- ============================================================

-- ============================================================
-- SECTION 1: Pastikan Extension UUID tersedia
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- SECTION 2: Fix DEFAULT UUID untuk tabel yang dibuat Laravel
-- Laravel tidak mengeset DEFAULT untuk UUID columns di Supabase
-- Supabase RPC perlu DEFAULT agar bisa auto-generate ID
-- ============================================================

-- Fix transactions.id
ALTER TABLE IF EXISTS transactions
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Fix transaction_items.id  
ALTER TABLE IF EXISTS transaction_items
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Fix orders.id
ALTER TABLE IF EXISTS orders
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Fix order_items.id
ALTER TABLE IF EXISTS order_items
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Fix items.id
ALTER TABLE IF EXISTS items
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Fix categories.id
ALTER TABLE IF EXISTS categories
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Fix housing_blocks.id
ALTER TABLE IF EXISTS housing_blocks
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- NOTE: 'settings' table uses 'key' as primary key (not UUID), skip.

-- ============================================================
-- SECTION 3: Tambahkan kolom buy_price ke transaction_items
-- (Kolom ini tidak ada di Laravel schema, khusus untuk mobile POS)
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transaction_items'
    AND column_name = 'buy_price'
  ) THEN
    ALTER TABLE transaction_items ADD COLUMN buy_price INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;

-- ============================================================
-- SECTION 4: RLS Policies untuk Mobile App
-- ============================================================

-- Enable RLS (jika belum)
ALTER TABLE IF EXISTS transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS housing_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS settings ENABLE ROW LEVEL SECURITY;

-- --- transactions: Admin only ---
DROP POLICY IF EXISTS "Admin All Transactions" ON transactions;
CREATE POLICY "Admin All Transactions"
  ON transactions FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- --- transaction_items: Admin only ---
DROP POLICY IF EXISTS "Admin All Transaction Items" ON transaction_items;
CREATE POLICY "Admin All Transaction Items"
  ON transaction_items FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- --- orders: Admin read all, Public insert ---
DROP POLICY IF EXISTS "Admin Read All Orders" ON orders;
CREATE POLICY "Admin Read All Orders"
  ON orders FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated Select Orders for Realtime" ON orders;
CREATE POLICY "Authenticated Select Orders for Realtime"
  ON orders FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Public Insert Orders" ON orders;
CREATE POLICY "Public Insert Orders"
  ON orders FOR INSERT
  TO anon
  WITH CHECK (true);

-- --- order_items: Admin read all, Public insert ---
DROP POLICY IF EXISTS "Admin Read Order Items" ON order_items;
CREATE POLICY "Admin Read Order Items"
  ON order_items FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated Select Order Items" ON order_items;
CREATE POLICY "Authenticated Select Order Items"
  ON order_items FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Public Insert Order Items" ON order_items;
CREATE POLICY "Public Insert Order Items"
  ON order_items FOR INSERT
  TO anon
  WITH CHECK (true);

-- --- items: Admin write, Public read ---
DROP POLICY IF EXISTS "Admin Write Items" ON items;
CREATE POLICY "Admin Write Items"
  ON items FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Public Read Items" ON items;
CREATE POLICY "Public Read Items"
  ON items FOR SELECT
  TO anon
  USING (true);

-- --- categories: Admin write, Public read ---
DROP POLICY IF EXISTS "Admin All Categories" ON categories;
CREATE POLICY "Admin All Categories"
  ON categories FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Public Read Categories" ON categories;
CREATE POLICY "Public Read Categories"
  ON categories FOR SELECT
  TO anon
  USING (true);

-- --- housing_blocks: Admin write, Public read ---
DROP POLICY IF EXISTS "Admin All Housing Blocks" ON housing_blocks;
CREATE POLICY "Admin All Housing Blocks"
  ON housing_blocks FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Public Read Housing Blocks" ON housing_blocks;
CREATE POLICY "Public Read Housing Blocks"
  ON housing_blocks FOR SELECT
  TO anon
  USING (true);

-- --- settings: Admin write, Public read ---
-- NOTE: settings table uses 'key' as PK (varchar), no 'id' column
DROP POLICY IF EXISTS "Admin All Settings" ON settings;
CREATE POLICY "Admin All Settings"
  ON settings FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Public Read Settings" ON settings;
CREATE POLICY "Public Read Settings"
  ON settings FOR SELECT
  TO anon
  USING (true);

-- ============================================================
-- SECTION 5: RPC Functions
-- ============================================================

-- 5.1 get_dashboard_summary
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
  v_today_jakarta := (now() AT TIME ZONE 'Asia/Jakarta')::date;

  SELECT COALESCE(SUM(total), 0) INTO v_omset
  FROM transactions
  WHERE (created_at AT TIME ZONE 'Asia/Jakarta')::date = v_today_jakarta;

  SELECT COALESCE(SUM((ti.price - ti.buy_price) * ti.quantity), 0) INTO v_profit
  FROM transaction_items ti
  JOIN transactions t ON t.id = ti.transaction_id
  WHERE (t.created_at AT TIME ZONE 'Asia/Jakarta')::date = v_today_jakarta;

  SELECT COUNT(*) INTO v_count
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

-- 5.2 get_report_summary
CREATE OR REPLACE FUNCTION get_report_summary(start_date TIMESTAMPTZ, end_date TIMESTAMPTZ)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_rev BIGINT;
  trx_count INTEGER;
  avg_val BIGINT;
  tot_profit BIGINT;
  result JSON;
  v_start TIMESTAMPTZ;
  v_end TIMESTAMPTZ;
BEGIN
  -- Shift +7h to match Jakarta-shifted storage
  v_start := start_date + INTERVAL '7 hours';
  v_end := end_date + INTERVAL '7 hours';

  SELECT COALESCE(SUM(total), 0), COUNT(id)
  INTO total_rev, trx_count
  FROM transactions
  WHERE created_at >= v_start AND created_at <= v_end;

  avg_val := CASE WHEN trx_count > 0 THEN total_rev / trx_count ELSE 0 END;

  SELECT COALESCE(SUM((ti.price - ti.buy_price) * ti.quantity), 0) INTO tot_profit
  FROM transactions t
  JOIN transaction_items ti ON t.id = ti.transaction_id
  WHERE t.created_at >= v_start AND t.created_at <= v_end;

  SELECT json_build_object(
    'total_revenue', total_rev,
    'transaction_count', trx_count,
    'average_value', avg_val,
    'total_profit', tot_profit
  ) INTO result;

  RETURN result;
END;
$$;

-- 5.3 get_top_selling_items (single version - date range)
DROP FUNCTION IF EXISTS get_top_selling_items(TEXT);
DROP FUNCTION IF EXISTS get_top_selling_items(TIMESTAMPTZ, TIMESTAMPTZ, INT);
CREATE OR REPLACE FUNCTION get_top_selling_items(
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  limit_count INT DEFAULT 10
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_start TIMESTAMPTZ;
  v_end TIMESTAMPTZ;
  result JSON;
BEGIN
  v_start := start_date + INTERVAL '7 hours';
  v_end := end_date + INTERVAL '7 hours';

  SELECT json_agg(t) INTO result
  FROM (
    SELECT 
      ti.item_id,
      COALESCE(i.name, 'Unknown Item') as item_name,
      SUM(ti.quantity)::INTEGER as total_quantity,
      SUM(ti.subtotal)::INTEGER as total_revenue
    FROM transaction_items ti
    LEFT JOIN items i ON i.id = ti.item_id
    WHERE ti.created_at >= v_start AND ti.created_at <= v_end
    GROUP BY ti.item_id, i.name
    ORDER BY total_quantity DESC
    LIMIT limit_count
  ) t;

  RETURN COALESCE(result, '[]'::JSON);
END;
$$;

-- 5.4 create_pos_transaction
CREATE OR REPLACE FUNCTION create_pos_transaction(
  p_admin_id UUID,
  p_payment_method TEXT,
  p_total INTEGER,
  p_items JSONB,
  p_cash_received INTEGER DEFAULT NULL,
  p_change_amount INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_transaction_id UUID;
  v_code TEXT;
  v_today TEXT;
  v_seq INTEGER;
  v_item JSONB;
  v_jakarta_timestamp TIMESTAMP;
BEGIN
  v_jakarta_timestamp := (NOW() AT TIME ZONE 'Asia/Jakarta')::TIMESTAMP;
  v_today := TO_CHAR(v_jakarta_timestamp, 'YYYYMMDD');

  SELECT COALESCE(MAX(SUBSTRING(code FROM 14 FOR 4)::INTEGER), 0) + 1
  INTO v_seq
  FROM transactions
  WHERE code LIKE 'TRX-' || v_today || '-%';

  v_code := 'TRX-' || v_today || '-' || LPAD(v_seq::TEXT, 4, '0');
  v_transaction_id := gen_random_uuid();

  INSERT INTO transactions (id, code, admin_id, payment_method, cash_received, "change", total, created_at, updated_at)
  VALUES (v_transaction_id, v_code, p_admin_id, p_payment_method, p_cash_received, p_change_amount, p_total, v_jakarta_timestamp, v_jakarta_timestamp);

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO transaction_items (id, transaction_id, item_id, buy_price, price, quantity, subtotal, created_at, updated_at)
    VALUES (
      gen_random_uuid(),
      v_transaction_id,
      (v_item->>'item_id')::UUID,
      (v_item->>'buy_price')::INTEGER,
      (v_item->>'sell_price')::INTEGER,
      (v_item->>'quantity')::INTEGER,
      (v_item->>'subtotal')::INTEGER,
      v_jakarta_timestamp,
      v_jakarta_timestamp
    );

    UPDATE items
    SET stock = stock - (v_item->>'quantity')::INTEGER, updated_at = v_jakarta_timestamp
    WHERE id = (v_item->>'item_id')::UUID;
  END LOOP;

  RETURN jsonb_build_object(
    'id', v_transaction_id,
    'code', v_code,
    'total', p_total,
    'created_at', v_jakarta_timestamp,
    'payment_method', p_payment_method,
    'admin_id', p_admin_id,
    'cash_received', p_cash_received,
    'change_amount', p_change_amount
  );
END;
$$;

-- ============================================================
-- DONE! warungku_app siap digunakan.
-- ============================================================
SELECT 'Setup mobile tables complete! warungku_app is ready.' AS status;
