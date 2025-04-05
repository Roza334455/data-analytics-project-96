WITH PaidClicks AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM sessions s
    LEFT JOIN leads l 
        ON s.visitor_id = l.visitor_id
    WHERE 
        l.lead_id IS NOT NULL
        AND s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

RankedClicks AS (
    SELECT
        *,
        ROW_NUMBER() OVER(
            PARTITION BY visitor_id 
            ORDER BY visit_date DESC
        ) AS visit_rank
    FROM PaidClicks
)
SELECT
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM RankedClicks
WHERE 
    visit_rank = 1
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;