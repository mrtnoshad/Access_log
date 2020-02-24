CREATE OR REPLACE TABLE noshad.Feature_dep_busy_all_actions as (
WITH

    -- Generate ADT_cohort with actual times and only ED
  ADT_real_date AS
  (SELECT ADT.* except(time_in,time_out,tpaAdminTime), DATETIME_SUB(ADT.time_in, INTERVAL TMP.JITTER DAY) as time_in,  
  DATETIME_SUB(ADT.time_out, INTERVAL TMP.JITTER DAY) as time_out, 
  DATETIME_SUB(ADT.tpaAdminTime, INTERVAL TMP.JITTER DAY) as tpaAdminTime,
  DATETIME_SUB(DATETIME_SUB(ADT.tpaAdminTime, INTERVAL TMP.JITTER DAY), INTERVAL 60 MINUTE) as tpa_60_before,
  DATETIME_ADD(DATETIME_SUB(ADT.tpaAdminTime, INTERVAL TMP.JITTER DAY), INTERVAL 60 MINUTE) as tpa_60_after,
  EXTRACT(DATE FROM DATETIME_SUB(ADT.tpaAdminTime, INTERVAL TMP.JITTER DAY)) as tpa_date
  
  FROM `noshad.ADT_cohort_jit` as ADT,
  `noshad.tmp` as TMP
  
  WHERE ADT.jc_uid=TMP.ANON_ID
    AND ADT.department_id = 2001002
  
  ORDER BY ADT.jc_uid, ADT.pat_enc_csn_id_coded, time_in
  ),
  
  
    -- Generate AL with actual times
  AL_real_date AS
  (SELECT AL.*, 
      DATETIME_SUB(AL.access_time_jittered, INTERVAL TMP.JITTER DAY) as access_time_real,
      EXTRACT(DATE FROM DATETIME_SUB(AL.access_time_jittered, INTERVAL TMP.JITTER DAY)) as access_date
  FROM `noshad.shc_access_log_de_dep_id` as AL,
  `noshad.tmp` as TMP
  WHERE AL.rit_uid=TMP.ANON_ID
    AND AL.department_id = 2001002
  ORDER BY AL.rit_uid
  )
  

    SELECT ADT_real_date.jc_uid, ADT_real_date.pat_enc_csn_id_coded, count(*) as dep_busy_all_actions, 

    FROM  ADT_real_date LEFT JOIN AL_real_date on (tpa_date=access_date)

    WHERE 

        AL_real_date.access_time_real BETWEEN ADT_real_date.tpa_60_before AND ADT_real_date.tpa_60_after 
        
    GROUP By ADT_real_date.jc_uid, ADT_real_date.pat_enc_csn_id_coded
)

