-- ============================================================
-- PROJECT: E-COMMERCE SALES & CUSTOMER ANALYTICS
-- DATABASE: ecommerce_analytics | TOOL: MySQL
-- PURPOSE: Data validation, business analysis, advanced SQL, and views
-- ============================================================

-- 01. DATABASE SELECTION
USE ecommerce_analytics;

-- 02. DATASET OVERVIEW: ROW COUNTS FOR CORE TABLES
SELECT
    'customers' AS table_name, COUNT(*) AS total_rows
FROM customers

UNION ALL

SELECT 'orders', COUNT(*) FROM orders

UNION ALL

SELECT 'order_items', COUNT(*) FROM order_items

UNION ALL

SELECT 'products', COUNT(*) FROM products

UNION ALL

SELECT 'order_payments', COUNT(*) FROM order_payments;

-- 03. DATA QUALITY & VALIDATION
-- 1. Check duplicate customer IDs
-- Query 3.1: Check duplicate customer IDs
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;

-- Query 3.2: Check duplicate order IDs
-- 2. Check duplicate order IDs
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders;

-- Query 3.3: Check missing customer fields
-- 3. Check missing values in customers
SELECT
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(customer_unique_id IS NULL) AS missing_unique_id,
    SUM(customer_city IS NULL) AS missing_city,
    SUM(customer_state IS NULL) AS missing_state
FROM customers;

-- Query 3.4: Order status distribution
-- 4. Check order status distribution
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Query 3.5: Dataset order date range
-- 5. Check order date range
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 04. SALES PERFORMANCE & BUSINESS KPIs
-- Query 4.1: Total number of orders
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;

-- Query 4.2: Total product revenue
SELECT ROUND(SUM(price), 2) AS total_revenue
FROM order_items;

-- Query 4.3: Average order value (AOV)
SELECT ROUND(
    SUM(price) / COUNT(DISTINCT order_id), 2
) AS average_order_value
FROM order_items;

-- Query 4.4: Monthly revenue trend
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- Query 4.5: Order status share (%)
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2
    ) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 05. CUSTOMER ANALYSIS
-- Query 5.1: Count unique customers
SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- Query 5.2: Identify repeat customers
SELECT
    COUNT(*) AS repeat_customers
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
    HAVING COUNT(o.order_id) > 1
) AS repeat_customer_data;

-- Query 5.3: Top 10 customers by spending
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- Query 5.4: Top 10 cities by customer orders
SELECT
    c.customer_city,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_city
ORDER BY total_orders DESC
LIMIT 10;

-- Query 5.5: Segment customers by spending
SELECT
    customer_unique_id,
    total_spent,
    CASE
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS customer_spending;

-- 06. PRODUCT & CATEGORY ANALYSIS
-- Query 6.1: Count distinct products
SELECT COUNT(DISTINCT product_id) AS total_products
FROM products;

-- Query 6.2: Top 10 products by revenue
SELECT
    p.product_id,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 6.3: Top 10 products by units sold
SELECT
    product_id,
    COUNT(*) AS units_sold
FROM order_items
GROUP BY product_id
ORDER BY units_sold DESC
LIMIT 10;

-- Query 6.4: Top 15 product categories by revenue
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price), 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 15;

-- Query 6.5: Categories by average item price
SELECT
    p.product_category_name,
    ROUND(AVG(oi.price), 2) AS average_price,
    COUNT(*) AS items_sold
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY average_price DESC
LIMIT 15;

-- Query 6.6: Products with no recorded order items
SELECT
    p.product_id,
    p.product_category_name
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- 07. PAYMENT ANALYSIS
-- Query 7.1: Payment type performance and value
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Query 7.2: Order share by payment type
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0 /
        (SELECT COUNT(DISTINCT order_id) FROM order_payments),
        2
    ) AS order_share_percentage
FROM order_payments
GROUP BY payment_type
ORDER BY order_share_percentage DESC;

-- Query 7.3: Average and maximum installments by payment type
SELECT
    payment_type,
    ROUND(AVG(payment_installments), 2) AS avg_installments,
    MAX(payment_installments) AS max_installments
FROM order_payments
GROUP BY payment_type
ORDER BY avg_installments DESC;

-- Query 7.4: Top 10 orders by total payment value
SELECT
    order_id,
    ROUND(SUM(payment_value), 2) AS total_paid,
    COUNT(*) AS payment_records
FROM order_payments
GROUP BY order_id
ORDER BY total_paid DESC
LIMIT 10;

-- Query 7.5: Payment performance for delivered orders
SELECT
    op.payment_type,
    COUNT(DISTINCT op.order_id) AS delivered_orders,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY total_payment_value DESC;

-- 08. DELIVERY & FULFILLMENT ANALYSIS
-- Query 8.1: Average delivery time in days
SELECT
    ROUND(
        AVG(DATEDIFF(order_delivered_customer_date,
                     order_purchase_timestamp)), 2
    ) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
  
-- Query 8.2: Average difference between actual and estimated delivery
  SELECT
    ROUND(AVG(DATEDIFF(
        order_delivered_customer_date,
        order_estimated_delivery_date
    )), 2) AS avg_days_vs_estimate
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
  
-- Query 8.3: On-time vs late delivery breakdown
  SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM orders
         WHERE order_status = 'delivered'
           AND order_delivered_customer_date IS NOT NULL
           AND order_estimated_delivery_date IS NOT NULL),
        2
    ) AS percentage
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

-- Query 8.4: Monthly average delivery time
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(
        order_delivered_customer_date,
        order_purchase_timestamp
    )), 2) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

-- Query 8.5: Order status and delivered-order counts
SELECT
    order_status,
    COUNT(*) AS total_orders,
    COUNT(order_delivered_customer_date) AS delivered_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Query 8.6: 20 orders with the longest delivery times (over 15 days)
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    DATEDIFF(
        order_delivered_customer_date,
        order_purchase_timestamp
    ) AS delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND DATEDIFF(
        order_delivered_customer_date,
        order_purchase_timestamp
      ) > 15
ORDER BY delivery_days DESC
LIMIT 20;

-- 09. ADVANCED SQL ANALYSIS
-- Query 9.1: Monthly sales using a CTE
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
)
SELECT *
FROM monthly_sales
ORDER BY order_month;

-- Query 9.2: Customers spending above the average
SELECT
    customer_unique_id,
    total_spent
FROM (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS customer_spending
WHERE total_spent > (
    SELECT AVG(total_spent)
    FROM (
        SELECT
            c.customer_unique_id,
            SUM(oi.price) AS total_spent
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
    ) AS avg_spending
)
ORDER BY total_spent DESC
LIMIT 20;

-- Query 9.3: Rank product categories by revenue using DENSE_RANK
WITH category_sales AS (
    SELECT
        p.product_category_name,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name
)
SELECT
    product_category_name,
    revenue,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS category_rank
FROM category_sales;

-- Query 9.4: Top 3 products within each category using window functions
WITH product_sales AS (
    SELECT
        p.product_category_name,
        p.product_id,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name, p.product_id
),
ranked_products AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY product_category_name
            ORDER BY revenue DESC
        ) AS product_rank
    FROM product_sales
)
SELECT *
FROM ranked_products
WHERE product_rank <= 3
ORDER BY product_category_name, product_rank;

-- Query 9.5: Month-over-month revenue growth using LAG
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
),
sales_comparison AS (
    SELECT
        order_month,
        revenue,
        LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    order_month,
    ROUND(revenue, 2) AS current_revenue,
    ROUND(previous_month_revenue, 2) AS previous_revenue,
    ROUND(
        (revenue - previous_month_revenue) * 100.0 /
        NULLIF(previous_month_revenue, 0),
        2
    ) AS growth_percentage
FROM sales_comparison
ORDER BY order_month;

-- Query 9.6: Cumulative monthly revenue using a window function
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (ORDER BY order_month),
        2
    ) AS cumulative_revenue
FROM monthly_sales
ORDER BY order_month;

-- 10. REUSABLE SQL VIEWS FOR TABLEAU
-- View 10.1: Monthly sales overview and KPIs
CREATE OR REPLACE VIEW vw_sales_overview AS
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue_with_shipping,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id), 2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month;

-- View 10.2: Customer analytics
CREATE OR REPLACE VIEW vw_customer_analytics AS
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    c.customer_unique_id,
    c.customer_city,
    c.customer_state;
    
-- View 10.3: Product performance
    CREATE OR REPLACE VIEW vw_product_performance AS
SELECT
    p.product_id,
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.order_item_id) AS item_id_sum,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_price
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, p.product_category_name;

-- View 10.4: Payment analytics
CREATE OR REPLACE VIEW vw_payment_analytics AS
SELECT
    op.payment_type,
    COUNT(DISTINCT op.order_id) AS total_orders,
    COUNT(*) AS payment_records,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value,
    ROUND(AVG(op.payment_installments), 2) AS avg_installments
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type;

-- View 10.5: Delivery analytics
CREATE OR REPLACE VIEW vw_delivery_analytics AS
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    DATEDIFF(
        order_delivered_customer_date,
        order_purchase_timestamp
    ) AS actual_delivery_days,
    DATEDIFF(
        order_delivered_customer_date,
        order_estimated_delivery_date
    ) AS days_vs_estimated,
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_performance
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
  
-- 11. VIEW VALIDATION: CONFIRM AND PREVIEW CREATED VIEWS
-- Query 11.1: List all views
  SHOW FULL TABLES
WHERE Table_type = 'VIEW';

-- Query 11.2: Preview sales overview view
SELECT * FROM vw_sales_overview LIMIT 10;

-- Query 11.3: Preview customer analytics view
SELECT * FROM vw_customer_analytics LIMIT 10;

-- Query 11.4: Preview product performance view
SELECT * FROM vw_product_performance LIMIT 10;

-- Query 11.5: Preview payment analytics view
SELECT * FROM vw_payment_analytics LIMIT 10;

-- Query 11.6: Preview delivery analytics view
SELECT * FROM vw_delivery_analytics LIMIT 10;

SELECT * FROM vw_payment_analytics;
