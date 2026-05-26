ALTER TABLE sql_customers
ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);
GO


ALTER TABLE sql_sales
ADD CONSTRAINT FK_sql_customers 
FOREIGN KEY (customer_id) REFERENCES sql_customers(customer_id);
GO

USE retailnova_analysis;
GO

PRINT '========== COMPLETE FIX SCRIPT ==========';

-- ============================================
-- 1. FIX CUSTOMERS (with age_group)
-- ============================================
PRINT 'Step 1: Fixing customers...';

INSERT INTO customers (customer_id, first_name, last_name, gender, age, age_group, signup_date, region)
SELECT DISTINCT 
    s.customer_id,
    'Unknown' AS first_name,
    'Unknown' AS last_name,
    'Other' AS gender,
    0 AS age,
    'Unknown' AS age_group,
    GETDATE() AS signup_date,
    'Unknown' AS region
FROM sales s
LEFT JOIN customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

PRINT '✅ Customers fixed';
GO

-- ============================================
-- 2. FIX PRODUCTS (with Price_Tier)
-- ============================================
PRINT 'Step 2: Fixing products...';

INSERT INTO product (product_id, product_name, category, brand, cost_price, unit_price, margin_pct, Price_Tier)
SELECT DISTINCT 
    s.product_id,
    'Unknown' AS product_name,
    'Unknown' AS category,
    'Unknown' AS brand,
    0 AS cost_price,
    0 AS unit_price,
    0 AS margin_pct,
    'Unknown' AS Price_Tier
FROM sales s
LEFT JOIN product p ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

PRINT '✅ Products fixed';
GO

-- ============================================
-- 3. FIX STORES
-- ============================================
PRINT 'Step 3: Fixing stores...';

INSERT INTO store (store_id, store_name, store_type, region, city, operating_cost)
SELECT DISTINCT 
    s.store_id,
    'Unknown' AS store_name,
    'Unknown' AS store_type,
    'Unknown' AS region,
    'Unknown' AS city,
    0 AS operating_cost
FROM sales s
LEFT JOIN store st ON s.store_id = st.store_id
WHERE st.store_id IS NULL 
  AND s.store_id IS NOT NULL 
  AND s.store_id NOT IN ('ONLINE', 'Online');

PRINT '✅ Stores fixed';
GO

-- ============================================
-- 4. VERIFY NO ORPHAN RECORDS
-- ============================================
PRINT 'Step 4: Verifying orphan records...';

SELECT 'orphan_customers' AS CheckType, COUNT(*) AS Count
FROM sales s LEFT JOIN customers c ON s.customer_id = c.customer_id WHERE c.customer_id IS NULL
UNION ALL
SELECT 'orphan_products', COUNT(*) 
FROM sales s LEFT JOIN product p ON s.product_id = p.product_id WHERE p.product_id IS NULL
UNION ALL
SELECT 'orphan_stores', COUNT(*)
FROM sales s LEFT JOIN store st ON s.store_id = st.store_id 
WHERE st.store_id IS NULL AND s.store_id IS NOT NULL AND s.store_id NOT IN ('ONLINE', 'Online');
GO

-- ============================================
-- 5. PRIMARY KEYS
-- ============================================
PRINT 'Step 5: Adding Primary Keys...';

ALTER TABLE customers ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);
ALTER TABLE product ADD CONSTRAINT PK_product PRIMARY KEY (product_id);
ALTER TABLE store ADD CONSTRAINT PK_store PRIMARY KEY (store_id);
ALTER TABLE sales ADD CONSTRAINT PK_sales PRIMARY KEY (order_id);
ALTER TABLE returns ADD CONSTRAINT PK_returns PRIMARY KEY (return_id);

PRINT '✅ Primary Keys added';
GO

-- ============================================
-- 6. FOREIGN KEYS (Drop & Create)
-- ============================================
PRINT 'Step 6: Adding Foreign Keys...';

-- Drop existing foreign keys
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_customer')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_customer;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_product')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_product;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_store')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_store;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_returns_order')
    ALTER TABLE returns DROP CONSTRAINT FK_returns_order;
GO

-- Create new foreign keys
ALTER TABLE sales ADD CONSTRAINT FK_sales_customer 
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE sales ADD CONSTRAINT FK_sales_product 
FOREIGN KEY (product_id) REFERENCES product(product_id);

ALTER TABLE sales ADD CONSTRAINT FK_sales_store 
FOREIGN KEY (store_id) REFERENCES store(store_id);

ALTER TABLE returns ADD CONSTRAINT FK_returns_order 
FOREIGN KEY (order_id) REFERENCES sales(order_id);

PRINT '✅ Foreign Keys added';
GO

-- ============================================
-- 7. PROFIT COLUMN
-- ============================================
PRINT 'Step 7: Adding Profit column...';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sales' AND COLUMN_NAME = 'profit')
    ALTER TABLE sales DROP COLUMN profit;

ALTER TABLE sales ADD profit DECIMAL(10,2);

UPDATE s
SET s.profit = s.total_amount - (s.quantity * p.cost_price)
FROM sales s
JOIN product p ON s.product_id = p.product_id;

PRINT '✅ Profit column added';
GO

-- ============================================
-- 8. FINAL VERIFICATION
-- ============================================
PRINT '========== FINAL VERIFICATION ==========';

SELECT 'customers' AS TableName, COUNT(*) AS Rows FROM customers
UNION ALL
SELECT 'product', COUNT(*) FROM product
UNION ALL
SELECT 'store', COUNT(*) FROM store
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
UNION ALL
SELECT 'returns', COUNT(*) FROM returns;

SELECT name AS ForeignKeyName FROM sys.foreign_keys;

PRINT '✅ Database is now fully ready!';
GO




USE retailnova_analysis;
GO

-- LAST RESORT - Saari foreign keys drop karo aur dobara banao
PRINT '========== EXTREME FIX ==========';

-- Sab foreign keys drop karo
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_customer')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_customer;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_product')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_product;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_store')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_store;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_returns_order')
    ALTER TABLE returns DROP CONSTRAINT FK_returns_order;
GO

USE retailnova_analysis;
GO

PRINT '========== EXTREME FIX ==========';

-- ============================================
-- STEP 1: Drop all foreign keys
-- ============================================
PRINT 'Step 1: Dropping all foreign keys...';
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_customer')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_customer;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_product')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_product;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sales_store')
    ALTER TABLE sales DROP CONSTRAINT FK_sales_store;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_returns_order')
    ALTER TABLE returns DROP CONSTRAINT FK_returns_order;
PRINT '✅ Foreign keys dropped';
GO

-- ============================================
-- STEP 2: Drop all primary keys
-- ============================================
PRINT 'Step 2: Dropping all primary keys...';
ALTER TABLE customers DROP CONSTRAINT IF EXISTS PK_customers;
ALTER TABLE product DROP CONSTRAINT IF EXISTS PK_product;
ALTER TABLE store DROP CONSTRAINT IF EXISTS PK_store;
ALTER TABLE sales DROP CONSTRAINT IF EXISTS PK_sales;
ALTER TABLE returns DROP CONSTRAINT IF EXISTS PK_returns;
PRINT '✅ Primary keys dropped';
GO

-- ============================================
-- STEP 3: Recreate all primary keys
-- ============================================
PRINT 'Step 3: Recreating primary keys...';
ALTER TABLE customers ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);
ALTER TABLE product ADD CONSTRAINT PK_product PRIMARY KEY (product_id);
ALTER TABLE store ADD CONSTRAINT PK_store PRIMARY KEY (store_id);
ALTER TABLE sales ADD CONSTRAINT PK_sales PRIMARY KEY (order_id);
ALTER TABLE returns ADD CONSTRAINT PK_returns PRIMARY KEY (return_id);
PRINT '✅ Primary keys recreated';
GO

-- ============================================
-- STEP 4: Fix all missing records
-- ============================================
PRINT 'Step 4: Fixing all missing records...';

-- Create UNKNOWN store
IF NOT EXISTS (SELECT * FROM store WHERE store_id = 'UNKNOWN')
    INSERT INTO store (store_id, store_name, store_type, region, city, operating_cost)
    VALUES ('UNKNOWN', 'Unknown Store', 'Unknown', 'Unknown', 'Unknown', 0);

-- Fix NULL/empty store_ids
UPDATE sales SET store_id = 'UNKNOWN' 
WHERE store_id IS NULL OR store_id = '' OR store_id = 'NULL';

-- Fix any other missing store_ids
UPDATE s SET s.store_id = 'UNKNOWN'
FROM sales s LEFT JOIN store st ON s.store_id = st.store_id
WHERE st.store_id IS NULL AND s.store_id IS NOT NULL;

-- Fix missing customers
INSERT INTO customers (customer_id, first_name, last_name, gender, age, age_group, signup_date, region)
SELECT DISTINCT s.customer_id, 'Unknown', 'Unknown', 'Other', 0, 'Unknown', GETDATE(), 'Unknown'
FROM sales s LEFT JOIN customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Fix missing products
INSERT INTO product (product_id, product_name, category, brand, cost_price, unit_price, margin_pct, Price_Tier)
SELECT DISTINCT s.product_id, 'Unknown', 'Unknown', 'Unknown', 0, 0, 0, 'Unknown'
FROM sales s LEFT JOIN product p ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

PRINT '✅ All missing records fixed';
GO

-- ============================================
-- STEP 5: Verify all fixed
-- ============================================
PRINT 'Step 5: Verifying...';
SELECT 
    (SELECT COUNT(*) FROM sales s LEFT JOIN customers c ON s.customer_id = c.customer_id WHERE c.customer_id IS NULL) AS MissingCustomers,
    (SELECT COUNT(*) FROM sales s LEFT JOIN product p ON s.product_id = p.product_id WHERE p.product_id IS NULL) AS MissingProducts,
    (SELECT COUNT(*) FROM sales s LEFT JOIN store st ON s.store_id = st.store_id WHERE st.store_id IS NULL AND s.store_id IS NOT NULL) AS MissingStores;
GO

-- ============================================
-- STEP 6: Recreate all foreign keys
-- ============================================
PRINT 'Step 6: Recreating all foreign keys...';

ALTER TABLE sales ADD CONSTRAINT FK_sales_customer 
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE sales ADD CONSTRAINT FK_sales_product 
FOREIGN KEY (product_id) REFERENCES product(product_id);

ALTER TABLE sales ADD CONSTRAINT FK_sales_store 
FOREIGN KEY (store_id) REFERENCES store(store_id);

ALTER TABLE returns ADD CONSTRAINT FK_returns_order 
FOREIGN KEY (order_id) REFERENCES sales(order_id);

PRINT '✅ All foreign keys recreated!';
GO

-- ============================================
-- STEP 7: Final verification
-- ============================================
PRINT '========== FINAL VERIFICATION ==========';
SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS TableName
FROM sys.foreign_keys fk
JOIN sys.tables tp ON fk.parent_object_id = tp.object_id;

PRINT '✅ Database is now 100% ready!';
GO






USE retailnova_analysis;
GO

-- Q1. Total revenue in last 12 months
SELECT SUM(total_amount) AS total_revenue_last_12_months
FROM sales
WHERE order_date >= DATEADD(YEAR, -1, (SELECT MAX(order_date) FROM sales));
GO

-- Q2. Top 5 best-selling products by quantity
SELECT TOP 5
    p.product_id,
    p.product_name,
    p.category,
    SUM(s.quantity) AS total_quantity_sold
FROM sales s
JOIN product p ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_quantity_sold DESC;
GO

-- Q3. Customers count by region
SELECT region, COUNT(*) AS customer_count
FROM customers
WHERE region IS NOT NULL
GROUP BY region
ORDER BY customer_count DESC;
GO

-- Q4. Store with highest profit in past year
SELECT TOP 1
    s.store_id,
    st.store_name,
    st.region,
    st.city,
    SUM(s.profit) AS total_profit
FROM sales s
JOIN store st ON s.store_id = st.store_id
WHERE s.order_date >= DATEADD(YEAR, -1, (SELECT MAX(order_date) FROM sales))
  AND s.store_id IS NOT NULL
GROUP BY s.store_id, st.store_name, st.region, st.city
ORDER BY total_profit DESC;
GO

-- Q5. Return rate by product category
SELECT 
    p.category,
    COUNT(DISTINCT s.order_id) AS total_orders,
    COUNT(DISTINCT r.order_id) AS returned_orders,
    ROUND(COUNT(DISTINCT r.order_id) * 100.0 / NULLIF(COUNT(DISTINCT s.order_id), 0), 2) AS return_rate_percent
FROM product p
LEFT JOIN sales s ON p.product_id = s.product_id
LEFT JOIN returns r ON s.order_id = r.order_id
GROUP BY p.category
ORDER BY return_rate_percent DESC;
GO

-- Q6. Average revenue per customer by age group
SELECT 
    c.age_group,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(s.total_amount) AS total_revenue,
    ROUND(AVG(s.total_amount), 2) AS avg_revenue_per_customer
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
WHERE c.age_group IS NOT NULL
GROUP BY c.age_group
ORDER BY CASE age_group
    WHEN 'Young' THEN 1 WHEN 'Adult' THEN 2
    WHEN 'Middle-Aged' THEN 3 WHEN 'Senior' THEN 4 END;
GO

-- Q7. Sales channel profitability comparison
SELECT 
    sales_channel,
    COUNT(*) AS transaction_count,
    SUM(total_amount) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(AVG(profit), 2) AS avg_profit_per_transaction
FROM sales
WHERE sales_channel IS NOT NULL
GROUP BY sales_channel;
GO

-- Q8. Monthly profit trend by region (last 2 years)
SELECT 
    YEAR(s.order_date) AS year,
    MONTH(s.order_date) AS month_num,
    DATENAME(MONTH, s.order_date) AS month_name,
    st.region,
    SUM(s.profit) AS monthly_profit
FROM sales s
JOIN store st ON s.store_id = st.store_id
WHERE s.order_date >= DATEADD(YEAR, -2, (SELECT MAX(order_date) FROM sales))
  AND st.region IS NOT NULL
GROUP BY YEAR(s.order_date), MONTH(s.order_date), DATENAME(MONTH, s.order_date), st.region
ORDER BY year, month_num, st.region;
GO

-- Q9. Top 3 products with highest return rate in each category
WITH ProductReturns AS (
    SELECT 
        p.category,
        p.product_id,
        p.product_name,
        COUNT(DISTINCT s.order_id) AS total_sold,
        COUNT(DISTINCT r.order_id) AS total_returns,
        ROUND(COUNT(DISTINCT r.order_id) * 100.0 / NULLIF(COUNT(DISTINCT s.order_id), 0), 2) AS return_rate,
        ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY COUNT(DISTINCT r.order_id) * 100.0 / NULLIF(COUNT(DISTINCT s.order_id), 0) DESC) AS rank
    FROM product p
    JOIN sales s ON p.product_id = s.product_id
    LEFT JOIN returns r ON s.order_id = r.order_id
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT category, product_id, product_name, total_sold, total_returns, return_rate
FROM ProductReturns WHERE rank <= 3
ORDER BY category, return_rate DESC;
GO

-- Q10. Top 5 customers by profit contribution
SELECT TOP 5
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    DATEDIFF(YEAR, c.signup_date, GETDATE()) AS tenure_years,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.profit) AS total_profit_contribution
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.region, c.signup_date
ORDER BY total_profit_contribution DESC;
GO

select * from store