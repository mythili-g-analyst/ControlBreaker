CREATE DATABASE controlbreaker;
USE controlbreaker;
SELECT DATABASE();

-- ControlBreaker: schema (synthetic data only)
USE controlbreaker;

CREATE TABLE vendor_master (
  vendor_id          VARCHAR(10)  PRIMARY KEY,
  vendor_name        VARCHAR(100) NOT NULL,
  city               VARCHAR(50),
  gstin              VARCHAR(15),
  phone              VARCHAR(15),
  status             ENUM('Active','Blocked','Inactive') NOT NULL DEFAULT 'Active',
  payment_terms_days INT NOT NULL DEFAULT 30,
  created_date       DATE NOT NULL
);

CREATE TABLE material_master (
  material_id    VARCHAR(10)  PRIMARY KEY,
  description    VARCHAR(100) NOT NULL,
  uom            VARCHAR(10)  NOT NULL,
  standard_price DECIMAL(12,2) NOT NULL
);

CREATE TABLE purchase_orders (
  po_number   VARCHAR(12) PRIMARY KEY,
  vendor_id   VARCHAR(10) NOT NULL,
  material_id VARCHAR(10) NOT NULL,
  po_date     DATE NOT NULL,
  quantity    INT NOT NULL,
  unit_price  DECIMAL(12,2) NOT NULL,
  status      ENUM('Open','Closed') NOT NULL DEFAULT 'Open',
  FOREIGN KEY (vendor_id)   REFERENCES vendor_master(vendor_id),
  FOREIGN KEY (material_id) REFERENCES material_master(material_id)
);

CREATE TABLE goods_receipts (
  receipt_number    VARCHAR(12) PRIMARY KEY,
  po_number         VARCHAR(12) NOT NULL,
  receipt_date      DATE NOT NULL,
  quantity_received INT NOT NULL,
  FOREIGN KEY (po_number) REFERENCES purchase_orders(po_number)
);

CREATE TABLE vendor_invoices (
  invoice_id            VARCHAR(12) PRIMARY KEY,
  vendor_invoice_number VARCHAR(30) NOT NULL,
  po_number             VARCHAR(12) NOT NULL,
  invoice_date          DATE NOT NULL,
  quantity_billed       INT NOT NULL,
  unit_price            DECIMAL(12,2) NOT NULL,
  amount                DECIMAL(14,2) NOT NULL,
  FOREIGN KEY (po_number) REFERENCES purchase_orders(po_number)
);

CREATE TABLE payments (
  payment_id   VARCHAR(12) PRIMARY KEY,
  invoice_id   VARCHAR(12) NOT NULL,
  payment_date DATE NOT NULL,
  amount       DECIMAL(14,2) NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES vendor_invoices(invoice_id)
);

CREATE TABLE answer_key (
  answer_key_id   INT AUTO_INCREMENT PRIMARY KEY,
  scenario_id     VARCHAR(5)   NOT NULL,
  scenario_name   VARCHAR(100) NOT NULL,
  affected_table  VARCHAR(30)  NOT NULL,
  affected_record VARCHAR(30)  NOT NULL,
  planted_value   DECIMAL(14,2)
);

CREATE TABLE exception_log (
  exception_id     INT AUTO_INCREMENT PRIMARY KEY,
  rule_name        VARCHAR(60) NOT NULL,
  vendor_id        VARCHAR(10),
  related_document VARCHAR(30),
  value_at_risk    DECIMAL(14,2) NOT NULL DEFAULT 0,
  detection_date   DATE NOT NULL,
  severity         ENUM('Low','Medium','High') NOT NULL,
  status           VARCHAR(20) NOT NULL DEFAULT 'Open'
);

CREATE TABLE rule_parameters (
  parameter_name  VARCHAR(40) PRIMARY KEY,
  parameter_value DECIMAL(14,2) NOT NULL,
  description     VARCHAR(150)
);

USE controlbreaker;
SHOW TABLES;
-- ControlBreaker: master data (SYNTHETIC SAMPLE DATA ONLY)


-- Rule parameters (tolerances documented before each test run)
INSERT INTO rule_parameters (parameter_name, parameter_value, description) VALUES
('price_tolerance_pct',        2,     'Allowed % difference between PO price and invoice price'),
('qty_tolerance_pct',          2,     'Allowed % difference between received quantity and billed quantity'),
('duplicate_window_days',      30,    'Days within which similar invoices are treated as possible duplicates'),
('approval_limit',             50000, 'Invoice amount (INR) above which approval is required'),
('split_invoice_window_days',  7,     'Days within which several invoices to one vendor are checked for splitting'),
('unbilled_receipt_age_days',  30,    'Days after which a goods receipt with no invoice is flagged');

-- 20 synthetic vendors (all Active in the clean baseline)
INSERT INTO vendor_master
(vendor_id, vendor_name, city, gstin, phone, status, payment_terms_days, created_date) VALUES
('V001','Alpha Fasteners',      'Coimbatore','33SYNTH0001A1Z1','9000000001','Active',30,'2024-01-10'),
('V002','Beta Bearings',        'Chennai',   '33SYNTH0002B1Z2','9000000002','Active',45,'2024-01-15'),
('V003','Gamma Lubricants',     'Hosur',     '33SYNTH0003C1Z3','9000000003','Active',30,'2024-01-20'),
('V004','Delta Packaging',      'Salem',     '33SYNTH0004D1Z4','9000000004','Active',60,'2024-02-01'),
('V005','Epsilon Electricals',  'Coimbatore','33SYNTH0005E1Z5','9000000005','Active',30,'2024-02-05'),
('V006','Zeta Tools',           'Erode',     '33SYNTH0006F1Z6','9000000006','Active',45,'2024-02-12'),
('V007','Eta Safety Supplies',  'Chennai',   '33SYNTH0007G1Z7','9000000007','Active',30,'2024-02-18'),
('V008','Theta Steel Traders',  'Tiruppur',  '33SYNTH0008H1Z8','9000000008','Active',60,'2024-03-01'),
('V009','Iota Hydraulics',      'Coimbatore','33SYNTH0009I1Z9','9000000009','Active',45,'2024-03-07'),
('V010','Kappa Rubber Works',   'Hosur',     '33SYNTH0010J1Z1','9000000010','Active',30,'2024-03-15'),
('V011','Lambda Paints',        'Madurai',   '33SYNTH0011K1Z2','9000000011','Active',30,'2024-03-22'),
('V012','Mu Gaskets',           'Chennai',   '33SYNTH0012L1Z3','9000000012','Active',45,'2024-04-02'),
('V013','Nu Cables',            'Salem',     '33SYNTH0013M1Z4','9000000013','Active',60,'2024-04-10'),
('V014','Xi Filters',           'Coimbatore','33SYNTH0014N1Z5','9000000014','Active',30,'2024-04-18'),
('V015','Omicron Motors',       'Erode',     '33SYNTH0015O1Z6','9000000015','Active',45,'2024-05-03'),
('V016','Pi Valves',            'Chennai',   '33SYNTH0016P1Z7','9000000016','Active',30,'2024-05-11'),
('V017','Rho Chemicals',        'Hosur',     '33SYNTH0017Q1Z8','9000000017','Active',60,'2024-05-20'),
('V018','Sigma Springs',        'Coimbatore','33SYNTH0018R1Z9','9000000018','Active',30,'2024-06-01'),
('V019','Tau Fabrication',      'Tiruppur',  '33SYNTH0019S1Z1','9000000019','Active',45,'2024-06-12'),
('V020','Upsilon Stationery',   'Madurai',   '33SYNTH0020T1Z2','9000000020','Active',30,'2024-06-25');

-- 15 synthetic materials
INSERT INTO material_master (material_id, description, uom, standard_price) VALUES
('M001','Hex Bolt M10',            'EA',   12.00),
('M002','Ball Bearing 6205',       'EA',  180.00),
('M003','Machine Lubricant 20L',   'DRM',3200.00),
('M004','Corrugated Box Large',    'EA',   45.00),
('M005','Copper Wire 2.5mm',       'M',    38.00),
('M006','Drill Bit Set',           'SET', 850.00),
('M007','Safety Gloves',           'PAIR', 95.00),
('M008','Mild Steel Sheet 2mm',    'KG',   72.00),
('M009','Hydraulic Hose 1in',      'M',   260.00),
('M010','Rubber Seal Ring',        'EA',   28.00),
('M011','Industrial Paint 20L',    'DRM',4200.00),
('M012','Gasket Sheet',            'EA',  140.00),
('M013','Electrical Cable 4mm',    'M',    55.00),
('M014','Air Filter Cartridge',    'EA',  620.00),
('M015','Compression Spring',      'EA',   34.00);

SELECT 'vendors' AS tbl, COUNT(*) AS rows_loaded FROM vendor_master
UNION ALL SELECT 'materials', COUNT(*) FROM material_master
UNION ALL SELECT 'parameters', COUNT(*) FROM rule_parameters;