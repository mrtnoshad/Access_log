CREATE OR REPLACE TABLE noshad.aim2_event_list_v2 as
SELECT jc_uid, enc_id, event_type, event_time, emergencyAdmitTime,  tpaAdminTime, DATETIME_DIFF(CAST(event_time AS DATETIME), emergencyAdmitTime, MINUTE) AS time_diff
FROM
(
(
SELECT OM0.jc_uid as jc_uid, 
  OM0.pat_enc_csn_id_coded as enc_id, 
  'OM-' || SUBSTR(OM0.med_description, 1,3) as event_type,
  CAST(OM0.order_med_id_coded AS STRING) as event_id,
  OM0.med_description as event_name,
  OM0.order_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `datalake_47618.order_med` AS OM0
  ON OM0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded

)

UNION ALL

( SELECT OP0.jc_uid as jc_uid, 
  OP0.pat_enc_csn_id_coded as enc_id, 
  'OP-' || SUBSTR(OP0.proc_code, 1,3) as event_type,
  OP0.proc_code as event_id,
  OP0.description as event_name,
  OP0.order_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `datalake_47618.order_proc` AS OP0
  ON OP0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded
)

UNION ALL


(
SELECT MAR0.jc_uid as jc_uid, 
  MAR0.pat_enc_csn_id_coded as enc_id, 
  'MAR-'  || SUBSTR(MAR0.mar_action, 1,3) as event_type,
  CAST(MAR0.order_med_id_coded AS STRING) as event_id,
  MAR0.mar_action as event_name,
  MAR0.taken_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `datalake_47618.mar` AS MAR0
  ON MAR0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded
)

UNION ALL

(
SELECT LR0.rit_uid as jc_uid, 
  LR0.pat_enc_csn_id_coded as enc_id, 
  'LR-' || SUBSTR(LR0.proc_code, 1,3) as event_type,
  LR0.proc_code as event_id,
  LR0.lab_name as event_name,
  LR0.order_time_jittered as event_time,
  cohort.emergencyAdmitTime as emergencyAdmitTime,
  Cohort.tpaAdminTime as tpaAdminTime
  
  FROM `noshad.cohort_v2` as Cohort
  LEFT JOIN `datalake_47618.lab_result` AS LR0
  ON LR0.pat_enc_csn_id_coded = Cohort.pat_enc_csn_id_coded
)
)
WHERE CAST(event_time AS DATETIME) <= tpaAdminTime
GROUP BY jc_uid, enc_id, event_type, event_time, emergencyAdmitTime, time_diff, tpaAdminTime
ORDER BY jc_uid, enc_id, event_time
