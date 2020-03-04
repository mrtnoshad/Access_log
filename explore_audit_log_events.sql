SELECT metric_name, count(*) as num FROM `som-nero-phi-jonc101.noshad.cohort_AL_60` 
--WHERE csn = 131117089410
WHERE
access_time_jittered <= tpaAdminTime
and not metric_name like 'SmartLink%'
GROUP BY metric_name 
ORDER BY num desc --access_time_jittered 


---- A grouped metric names:
select mg.name, count(*)
from `shc_access_log.shc_access_log_de` as al
   join `shc_access_log.access_log_metric` using (metric_id)
   join `shc_access_log.zc_metric_group` as mg using (metric_group_c)
group by mg.name
order by count(*) desc
limit 100
