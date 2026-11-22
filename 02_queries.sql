-- Part 2 — SQL Queries for CareLoop Clinics No-Show Guard
-- Run in MySQL Workbench or SQLiteOnline (skip CREATE DATABASE/USE for SQLiteOnline)

-- ============================================================
-- TASK 2.1 — Build and Load Database
-- ============================================================

-- MySQL only (skip for SQLiteOnline):
-- CREATE DATABASE noshowguard;
-- USE noshowguard;

-- Create tables
CREATE TABLE clinics (
  clinic_id VARCHAR(5) PRIMARY KEY, 
  clinic_name VARCHAR(40) NOT NULL, 
  city VARCHAR(20) NOT NULL,
  tier VARCHAR(10), 
  latitude DECIMAL(8,4), 
  longitude DECIMAL(8,4), 
  temp_c DECIMAL(5,1)
);

CREATE TABLE appointments (
  appointment_id VARCHAR(8) PRIMARY KEY, 
  patient_id VARCHAR(8) NOT NULL, 
  clinic_id VARCHAR(5) NOT NULL,
  booked_on DATE, 
  appt_date DATE, 
  age INT, 
  gender VARCHAR(1), 
  distance_km DECIMAL(5,1), 
  fee_inr INT,
  booking_channel VARCHAR(10), 
  visit_type VARCHAR(12), 
  reminder_sent VARCHAR(3), 
  prior_no_shows INT,
  status VARCHAR(10), 
  lead_days INT, 
  no_show INT,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
);

-- Load data: run load_data.sql (generated in Part 1)
-- SOURCE load_data.sql;  -- MySQL
-- Or paste contents of load_data.sql here

-- Verify counts
SELECT 'clinics' AS table_name, COUNT(*) AS row_count FROM clinics
UNION ALL
SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL
SELECT 'no_shows_total', SUM(no_show) FROM appointments;

-- Test duplicate key insertion (record error message)
-- Expected error: Duplicate entry 'A0001' for key 'appointments.PRIMARY' (MySQL)
-- or UNIQUE constraint failed: appointments.appointment_id (SQLite)
INSERT INTO appointments VALUES ('A0001','P509','C05','2025-01-24','2025-01-25',60,'F',18.0,850,'Phone','Consultation','Yes',1,'No-Show',1,1);

-- ============================================================
-- TASK 2.2 — No-Show Rate by Clinic
-- ============================================================

-- With HAVING (clinics with >= 95 appointments)
SELECT 
  c.clinic_name,
  c.city,
  COUNT(*) AS appointments,
  SUM(a.no_show) AS no_shows,
  ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;

-- Without HAVING (all 8 clinics)
SELECT 
  c.clinic_name,
  c.city,
  COUNT(*) AS appointments,
  SUM(a.no_show) AS no_shows,
  ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
ORDER BY no_show_pct DESC;

-- ============================================================
-- TASK 2.3 — Lead Days Bands
-- ============================================================

SELECT 
  CASE 
    WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
    WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
    WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
    ELSE '31+'
  END AS lead_band,
  COUNT(*) AS appointments,
  SUM(no_show) AS no_shows,
  ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_band
ORDER BY MIN(lead_days);

-- ============================================================
-- TASK 2.4 — Month-by-Month Trend
-- ============================================================

WITH monthly AS (
  SELECT 
    SUBSTR(appt_date, 1, 7) AS month,
    COUNT(*) AS appointments,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
  FROM appointments
  GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT 
  month,
  appointments,
  no_show_pct,
  ROUND(no_show_pct - LAG(no_show_pct) OVER (ORDER BY month), 1) AS pct_change
FROM monthly
ORDER BY month;

-- ============================================================
-- TASK 2.5 — Rank Clinics Inside Each City
-- ============================================================

WITH clinic_rates AS (
  SELECT 
    c.clinic_name AS clinic,
    c.city,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
  FROM appointments a
  JOIN clinics c ON a.clinic_id = c.clinic_id
  GROUP BY c.clinic_id, c.clinic_name, c.city
)
SELECT 
  cr.clinic,
  cr.city,
  cr.no_show_pct,
  RANK() OVER (PARTITION BY cr.city ORDER BY cr.no_show_pct DESC) AS rank_in_city,
  CASE 
    WHEN cr.no_show_pct > (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 2) FROM appointments) THEN 'above'
    WHEN cr.no_show_pct < (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 2) FROM appointments) THEN 'below'
    ELSE 'equal'
  END AS vs_overall
FROM clinic_rates cr
ORDER BY cr.city, rank_in_city;

-- ============================================================
-- DUPLICATE KEY ERROR MESSAGE (for submission)
-- ============================================================
/*
MySQL Error:
ERROR 1062 (23000): Duplicate entry 'A0001' for key 'appointments.PRIMARY'

SQLiteOnline Error:
UNIQUE constraint failed: appointments.appointment_id
*/