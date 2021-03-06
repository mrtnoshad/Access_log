CREATE OR REPLACE TABLE noshad.aim2_top_events AS
(

(SELECT event_type, count(*) as num 
FROM `som-nero-phi-jonc101.noshad.aim2_event_list_all_v1` 
WHERE event_type like 'ADT%'
GROUP BY event_type
ORDER BY num DESC
LIMIT 5
)

UNION ALL

(SELECT event_type, count(*) as num 
FROM `som-nero-phi-jonc101.noshad.aim2_event_list_all_v1` 
WHERE event_type like 'Order Med%'
GROUP BY event_type
ORDER BY num DESC
LIMIT 20
)

UNION ALL

(SELECT event_type, count(*) as num 
FROM `som-nero-phi-jonc101.noshad.aim2_event_list_all_v1` 
WHERE event_type like 'Order Procedure%'
GROUP BY event_type
ORDER BY num DESC
LIMIT 40
)

UNION ALL

(SELECT event_type, count(*) as num 
FROM `som-nero-phi-jonc101.noshad.aim2_event_list_all_v1` 
WHERE event_type like 'Medication Given%'
GROUP BY event_type
ORDER BY num DESC
LIMIT 10
)

UNION ALL

(SELECT event_type, count(*) as num 
FROM `som-nero-phi-jonc101.noshad.aim2_event_list_all_v1` 
WHERE event_type like 'Lab Result%'
GROUP BY event_type
ORDER BY num DESC
LIMIT 20
)



UNION ALL

(SELECT event_type, count(*) as num 
FROM `som-nero-phi-jonc101.noshad.aim2_event_list_all_v1` 
WHERE event_type like 'Access log%'
GROUP BY event_type
ORDER BY num DESC
LIMIT 100
)

)
