-- ControlBreaker: clean baseline transactions (SYNTHETIC SAMPLE DATA ONLY)
USE controlbreaker;

-- helper table with numbers 1 to 200 (needs MySQL 8)
SET SESSION cte_max_recursion_depth = 1000;
CREATE TABLE tmp_numbers AS
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 200
)
SELECT n FROM seq;

-- 200 purchase orders at standard price, all closed
INSERT INTO purchase_orders
(po_number, vendor_id, material_id, po_date, quantity, unit_price, status)
SELECT
  CONCAT('PO', LPAD(t.n, 5, '0')),
  CONCAT('V', LPAD(((t.n - 1) MOD 20) + 1, 3, '0')),
  m.material_id,
  DATE_ADD('2025-01-01', INTERVAL (t.n * 2) DAY),
  CASE WHEN m.standard_price > 1000
       THEN 1 + ((t.n * 13) MOD 10)
       ELSE 10 + ((t.n * 13) MOD 40) END,
  m.standard_price,
  'Closed'
FROM tmp_numbers t
JOIN material_master m
  ON m.material_id = CONCAT('M', LPAD(((t.n * 7) MOD 15) + 1, 3, '0'));

-- goods receipts: full quantity, a few days after the PO
INSERT INTO goods_receipts
(receipt_number, po_number, receipt_date, quantity_received)
SELECT
  CONCAT('GR', LPAD(t.n, 5, '0')),
  p.po_number,
  DATE_ADD(p.po_date, INTERVAL (3 + (t.n MOD 5)) DAY),
  p.quantity
FROM tmp_numbers t
JOIN purchase_orders p ON p.po_number = CONCAT('PO', LPAD(t.n, 5, '0'));

-- vendor invoices: same quantity and price as the PO, 2 days after receipt
INSERT INTO vendor_invoices
(invoice_id, vendor_invoice_number, po_number, invoice_date,
 quantity_billed, unit_price, amount)
SELECT
  CONCAT('INV', LPAD(t.n, 5, '0')),
  CONCAT('VI-', p.vendor_id, '-', LPAD(t.n, 4, '0')),
  p.po_number,
  DATE_ADD(g.receipt_date, INTERVAL 2 DAY),
  p.quantity,
  p.unit_price,
  p.quantity * p.unit_price
FROM tmp_numbers t
JOIN purchase_orders p ON p.po_number = CONCAT('PO', LPAD(t.n, 5, '0'))
JOIN goods_receipts g ON g.po_number = p.po_number;

-- payments: full amount, paid on the vendor's payment terms
INSERT INTO payments (payment_id, invoice_id, payment_date, amount)
SELECT
  CONCAT('PAY', LPAD(t.n, 5, '0')),
  i.invoice_id,
  DATE_ADD(i.invoice_date, INTERVAL v.payment_terms_days DAY),
  i.amount
FROM tmp_numbers t
JOIN vendor_invoices i ON i.invoice_id = CONCAT('INV', LPAD(t.n, 5, '0'))
JOIN purchase_orders p ON p.po_number = i.po_number
JOIN vendor_master v ON v.vendor_id = p.vendor_id;

DROP TABLE tmp_numbers;


SELECT 'purchase_orders' AS tbl, COUNT(*) AS n FROM purchase_orders
UNION ALL SELECT 'goods_receipts', COUNT(*) FROM goods_receipts
UNION ALL SELECT 'vendor_invoices', COUNT(*) FROM vendor_invoices
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'max invoice amount (should be under 50000)', MAX(amount) FROM vendor_invoices;


DROP TABLE IF EXISTS tmp_numbers;
SHOW TABLES;