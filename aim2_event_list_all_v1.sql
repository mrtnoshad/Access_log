CREATE OR REPLACE TABLE noshad.aim2_event_list_all_v1 as
SELECT 

jc_uid, 
enc_id, 
event_type  as event_type, 
event_time, 
emergencyAdmitTime,  
tpaAdminTime, 
DATETIME_DIFF(CAST(event_time AS DATETIME), emergencyAdmitTime, MINUTE) AS time_diff, 
MP.unique_role as user_type

FROM
(

-- ADT Table

(
SELECT ADT.jc_uid as jc_uid, 
  ADT.pat_enc_csn_id_coded as enc_id, 
  'ADT - ' || ADT.event_type || ' - ' || ADT.department_id as event_type,
  CAST(ADT.event_type_c AS STRING) as event_id,
  ADT.event_type as event_name,
  ADT.effective_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime,
  ' 0 ' as prov_id
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `starr_datalake2018.adt` AS ADT
  ON ADT.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded

) 

UNION ALL




-- Order Medication Table
(
SELECT OM0.jc_uid as jc_uid, 
  OM0.pat_enc_csn_id_coded as enc_id, 
  'Order Med - ' || OM0.med_description as event_type,
  CAST(OM0.order_med_id_coded AS STRING) as event_id,
  OM0.med_description as event_name,
  OM0.order_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime,
  OM0.authr_prov_map_id as prov_id
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `starr_datalake2018.order_med` AS OM0
  ON OM0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded

) 
 
UNION ALL


-- Order Procedure Table
( SELECT OP0.jc_uid as jc_uid, 
  OP0.pat_enc_csn_id_coded as enc_id, 
  'Order Procedure - ' || OP0.description as event_type,
  OP0.proc_code as event_id,
  OP0.description as event_name,
  OP0.order_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime,
  OP0.authrzing_prov_map_id as prov_id
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `starr_datalake2018.order_proc` AS OP0
  ON OP0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded
)

UNION ALL

-- MAR Table
(
SELECT MAR0.jc_uid as jc_uid, 
  MAR0.pat_enc_csn_id_coded as enc_id, 
  'Medication Given - ' || OM.med_description   as event_type,
  CAST(MAR0.order_med_id_coded AS STRING) as event_id,
  MAR0.mar_action as event_name,
  MAR0.taken_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime,
  OM.authr_prov_map_id as prov_id
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `starr_datalake2018.mar` AS MAR0
  ON MAR0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded
  LEFT JOIN `datalake_47618.order_med` AS OM
  ON OM.order_med_id_coded = MAR0.order_med_id_coded
)

UNION ALL

-- Lab Results Table
(
SELECT LR0.rit_uid as jc_uid, 
  LR0.pat_enc_csn_id_coded as enc_id, 
  'Lab Result - ' || LR0.proc_code as event_type,
  LR0.proc_code as event_id,
  LR0.lab_name as event_name,
  LR0.order_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime,
  LR0.auth_prov_map_id as prov_id
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `starr_datalake2018.lab_result` AS LR0
  ON LR0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded
)

UNION ALL

-- Access Log Data
(select 

  al.rit_uid as jc_uid, 
  cohort.pat_enc_csn_id_coded as enc_id, 
  'Access log - ' || metric_name as event_type,
  CAST(al.metric_id AS STRING) as event_id,
  CAST(al.metric_name AS STRING) as event_name,
  CAST(al.access_time_jittered AS DATETIME) as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime,
  al.user_deid as prov_id

  from noshad.cohort_v2 as cohort
  join `shc_access_log.shc_access_log_de` as al on cohort.jc_uid  = al.rit_uid 
  -- only capture the access logs within 60 min before and after the cohort
where  datetime_diff(al.access_time_jittered, cohort.tpaAdminTime, MINUTE) >= -360 --up to 6 hours before tpa admin time 
  and datetime_diff(al.access_time_jittered, cohort.tpaAdminTime, MINUTE) <= 0
)

) AS EV

-- JOIN WITH PROV_TYPE MAPPING 
left join noshad.user_map as MP
on MP.prov_map_id= EV.prov_id

WHERE CAST(event_time AS DATETIME) <= tpaAdminTime
GROUP BY jc_uid, enc_id, event_type, event_time, emergencyAdmitTime, time_diff, tpaAdminTime, user_type
ORDER BY jc_uid, enc_id, event_time
