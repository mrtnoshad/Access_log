SELECT metric_name, count(*) as num FROM `som-nero-phi-jonc101.noshad.cohort_AL_60` 
--WHERE csn = 131117089410
WHERE
access_time_jittered <= tpaAdminTime
and not metric_name like 'SmartLink%'
GROUP BY metric_name 
ORDER BY num desc --access_time_jittered 
