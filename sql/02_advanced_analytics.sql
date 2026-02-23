-- =====================================================
-- NETFLIX SUBSCRIPTION ANALYTICS
-- FILE: 02_advanced_analytics.sql
-- PURPOSE: Revenue & Customer Intelligence KPIs
-- =====================================================


-- =====================================================
-- KPI 11: Revenue by Plan + % Contribution
-- =====================================================
SELECT
    plan_name,
    total_revenue,
    ROUND(total_revenue / NULLIF(SUM(total_revenue) OVER(),0) *100,2)
    as revenue_cont_pct
FROM    
    (SELECT 
        pl.plan_name,
        SUM(p.amount) as total_revenue
    FROM payments p
    INNER JOIN subscriptions s
    ON p.subscription_id=s.subscription_id
    INNER JOIN plans pl
    ON pl.plan_id=s.plan_id
    WHERE p.payment_status='Success'
    GROUP BY pl.plan_name) x
ORDER BY total_revenue DESC;


-- =====================================================
-- KPI 12: ARPA (Average Revenue Per Account) by Plan
-- =====================================================
SELECT  
        y.plan_id,
        x.plan_name,
        y.active_users,
        x.total_revenue,
        ROUND(total_revenue / NULLIF(active_users,0),2) as ARPA
FROM               
    (SELECT
        plan_id,
        COUNT(DISTINCT user_id) as active_users
        FROM subscriptions
        WHERE is_active=1
        GROUP BY plan_id)y
    INNER JOIN
    (SELECT 
        pl.plan_id,
        pl.plan_name,
        SUM(p.amount) as total_revenue
    FROM payments p
    INNER JOIN subscriptions s
    ON p.subscription_id=s.subscription_id
    INNER JOIN plans pl
    ON pl.plan_id=s.plan_id
    WHERE p.payment_status='Success'
    GROUP BY pl.plan_name,pl.plan_id)x
ON x.plan_id=y.plan_id
ORDER BY ARPA DESC;


-- =====================================================
-- KPI 13: Customer Lifetime Value (CLV)
-- =====================================================
SELECT
    AVG(lifetime_revenue) as avg_lifetime_revenue
FROM    
    (SELECT 
        u.user_id,
        COALESCE(SUM(amount),0) as lifetime_revenue
    FROM users u
    LEFT JOIN payments p
    ON u.user_id=p.user_id
    AND p.payment_status='Success'
    GROUP BY user_id)x ;


-- =====================================================
-- KPI 14: Plan-wise Churn Rate (%)
-- =====================================================
SELECT
    x.plan_id,
    ROUND(COALESCE(x.churned_users,0)
    / NULLIF(y.total_users,0) *100,2)
    as churn_rate
FROM
    (SELECT 
        plan_id,
        COUNT(DISTINCT user_id) as churned_users
    FROM subscriptions
    WHERE end_date is NOT NULL
    GROUP BY plan_id)x
LEFT JOIN
    (SELECT
        plan_id,
        COUNT(DISTINCT user_id) as total_users
        FROM subscriptions
        GROUP BY plan_id)y
ON x.plan_id=y.plan_id
ORDER BY churn_rate DESC;


-- =====================================================
-- KPI 15: Revenue Segmentation 
-- =====================================================
SELECT
    revenue_segment,
    total_users,
    total_revenue,
    ROUND(
        total_revenue / NULLIF(SUM(total_revenue) OVER(),0) *100,2)
        as revenue_cont_pct
FROM
    (SELECT
        revenue_segment,
        COUNT(user_id) as total_users,
        SUM(lifetime_revenue) as total_revenue
FROM
    (SELECT
        user_id,
        lifetime_revenue,
        NTILE(5) OVER(ORDER BY lifetime_revenue DESC) as revenue_segment
FROM 
    (SELECT 
        u.user_id,
        COALESCE(SUM(amount),0) as lifetime_revenue
    FROM users u
    LEFT JOIN payments p
    ON u.user_id=p.user_id
    AND p.payment_status='Success'
    GROUP BY user_id)x)y
GROUP BY revenue_segment)z;


-- =====================================================
-- END OF FILE: 02_advanced_analytics.sql
-- STATUS: Phase 3 (Advanced Analytics) Completed
-- =====================================================
