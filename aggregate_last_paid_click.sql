WITH PaidClicks AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source,
        s.medium,
        s.campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM sessions s
    LEFT JOIN leads l ON s.visitor_id = l.visitor_id
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),
CampaignCosts AS (
    SELECT 
        campaign_date, 
        utm_source, 
        utm_medium, 
        utm_campaign, 
        SUM(daily_spent) AS daily_spent
    FROM vk_ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign
),
AggregatedData AS (
    SELECT
        pc.visit_date,
        pc.source AS utm_source,
        pc.medium AS utm_medium,
        pc.campaign AS utm_campaign,
        COUNT(DISTINCT pc.visitor_id) AS visitors_count,
        COALESCE(SUM(cc.daily_spent), 0) AS total_cost,
        COUNT(DISTINCT pc.lead_id) FILTER (WHERE pc.lead_id IS NOT NULL) AS leads_count,
        COUNT(DISTINCT pc.lead_id) FILTER (WHERE pc.closing_reason = 'Успешно реализовано' OR pc.status_id = 142) AS purchases_count,
        COALESCE(SUM(pc.amount) FILTER (WHERE pc.closing_reason = 'Успешно реализовано' OR pc.status_id = 142), 0) AS revenue
    FROM PaidClicks pc
    LEFT JOIN CampaignCosts cc ON 
        pc.visit_date = cc.campaign_date AND
        pc.source = cc.utm_source AND
        pc.medium = cc.utm_medium AND
        pc.campaign = cc.utm_campaign
    GROUP BY pc.visit_date, pc.source, pc.medium, pc.campaign
)
SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    visitors_count,
    total_cost,
    leads_count,
    purchases_count,
    revenue
FROM AggregatedData
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC
LIMIT 15;