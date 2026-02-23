-- =====================================================
-- NETFLIX SUBSCRIPTION ANALYTICS
-- FILE: 01_core_kpis.sql
-- PURPOSE: Foundational Business KPIs
-- =====================================================


-- =====================================================
-- KPI 1: Total Revenue
-- =====================================================
SELECT 
    SUM(amount) as total_revenue
FROM payments
WHERE payment_status="Success";


-- =====================================================
-- KPI 2: Active Subscribers
-- =====================================================
SELECT 
    COUNT(DISTINCT user_id) as active_subscribers
FROM subscriptions
WHERE is_active=1;


-- =====================================================
-- KPI 3: Active User Percentage
-- =====================================================
SELECT 
    ROUND((
        (SELECT COUNT(DISTINCT user_id)
        FROM subscriptions
        WHERE is_active = 1)
        * 100.0 )
        /   
		(SELECT COUNT(*)
        FROM users),2)
        AS active_user_pct;


-- =====================================================
-- KPI 4: Average Revenue Per User (ARPU)
-- =====================================================
SELECT 
    ROUND(
		((SELECT SUM(amount)
        FROM payments
        WHERE payment_status = 'Success'))
        /
        NULLIF(
            (SELECT COUNT(DISTINCT user_id)
             FROM subscriptions
             WHERE is_active = 1),0),2) AS ARPU;


-- =====================================================
-- KPI 5: Monthly Recurring Revenue (MRR)
-- =====================================================
SELECT 
    DATE_FORMAT(payment_date, '%Y-%m') AS revenue_month,
    SUM(amount) AS monthly_revenue
FROM payments
WHERE payment_status = 'Success'
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY revenue_month;


-- =====================================================
-- KPI 6: Month-over-Month Revenue Growth (%)
-- =====================================================
SELECT 
    revenue_month,
    monthly_revenue,
    prev_month_revenue,
    ROUND(
		(monthly_revenue-prev_month_revenue)
	/ NULLIF(
		prev_month_revenue,0)*100,2) as monthly_growth_pct
FROM    
    (SELECT  
        *,
        LAG(monthly_revenue) OVER(ORDER BY revenue_month) as prev_month_revenue
    FROM
        (SELECT 
            DATE_FORMAT(payment_date, '%Y-%m') AS revenue_month,
            SUM(amount) AS monthly_revenue
            FROM payments
            WHERE payment_status = 'Success'
            GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
            )x)y;


-- =====================================================
-- KPI 7: New Subscribers per Month
-- =====================================================
SELECT  
    COUNT(user_id) as new_customers,
    DATE_FORMAT(first_time,'%Y-%m') as sub_started
FROM    
    (SELECT  user_id,
    MIN(start_date) as first_time
    FROM subscriptions
    GROUP BY user_id)x
GROUP BY sub_started
ORDER BY sub_started;


-- =====================================================
-- KPI 8: Monthly Churn Rate (%)
-- =====================================================
SELECT 
    churn_month,
    ROUND(
        churned_customers / NULLIF(active_base,0) * 100,2)
        as monthly_churn_rate
FROM    
    (SELECT 
        C.churn_month,
        c.churned_customers,
        (SELECT 
            COUNT(DISTINCT s.user_id)
            FROM subscriptions s
            WHERE s.start_date < STR_TO_DATE(CONCAT(c.churn_month,'-01'),'%Y-%m-%d')
            AND (s.end_date is NULL or
            s.end_date >= STR_TO_DATE(CONCAT(c.churn_month,'-01'),'%Y-%m-%d'))) as active_base
FROM            
    (SELECT
        DATE_FORMAT(end_date,'%Y-%m') as churn_month,
        COUNT(DISTINCT user_id) as churned_customers
        FROM subscriptions
        WHERE end_date is NOT NULL
        GROUP BY churn_month)c
    ORDER BY c.churn_month)x;


-- =====================================================
-- KPI 9: Payment Success Rate (%)
-- =====================================================
SELECT
    ROUND(
         (SELECT COUNT(*)
        	FROM payments
            WHERE payment_status='Success')
            /
            NULLIF((SELECT COUNT(*)
            FROM payments),0)
            * 100,2) as payment_success_rate;


-- =====================================================
-- KPI 10: Average Subscription Duration
-- =====================================================
SELECT
    ROUND
        (AVG(TIMESTAMPDIFF(MONTH,start_date,COALESCE(end_date,CURRENT_DATE()))),2) 
         as avg_sub_duration
FROM subscriptions;


-- =====================================================
-- END OF FILE: 01_core_kpis.sql
-- STATUS: Phase 2 (Core KPIs) Completed
-- =====================================================

