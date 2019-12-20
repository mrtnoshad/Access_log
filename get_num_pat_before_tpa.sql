
CREATE OR REPLACE TABLE noshad_test.num_pat AS(
WITH

    -- Generate ADT_cohort with actual times
  ADT_real_date AS
  (SELECT ADT.* except(time_in,time_out), DATETIME_SUB(ADT.time_in, INTERVAL TMP.JITTER_test DAY) as time_in,  
  DATETIME_SUB(ADT.time_out, INTERVAL TMP.JITTER_test DAY) as time_out
  
  FROM `noshad_test.ADT_cohort_jit` as ADT,
  `noshad_test.tmp_rnd_shift` as TMP
  
  WHERE ADT.jc_uid=TMP.ANON_ID
  
  ORDER BY ADT.jc_uid, ADT.pat_enc_csn_id_coded, time_in
  ),
  
    -- Generate AL with actual times
  AL_real_date AS
  (SELECT AL.*, DATETIME_SUB(AL.access_time_jittered, INTERVAL TMP.JITTER_test DAY) as access_time_real
  FROM `shc_access_log.shc_access_log_de` as AL,
  `noshad_test.tmp_rnd_shift` as TMP
  WHERE AL.rit_uid=TMP.ANON_ID
  ORDER BY AL.rit_uid
  ),
  
  --- Generate NUM of PAT PER DEP with times
  NUM_PAT_PER_DEP AS 
  (SELECT ADT_real_date.*, count(*) as num_tranx , 
    count(*)/ DATETIME_DIFF(ADT_real_date.time_out, ADT_real_date.time_in, MINUTE) as num_tranx_rate 
  FROM ADT_real_date, AL_real_date
  WHERE ADT_real_date.jc_uid=AL_real_date.rit_uid 
    AND ADT_real_date.time_in < AL_real_date.access_time_real 
    AND AL_real_date.access_time_real < ADT_real_date.time_out
  GROUP BY ADT_real_date.jc_uid, ADT_real_date.pat_enc_csn_id_coded, 
    ADT_real_date.department_id, ADT_real_date.tpaAdminTime, 
    ADT_real_date.time_in, ADT_real_date.time_out
  ORDER BY ADT_real_date.department_id)

  -- Main script
SELECT jc_uid, pat_enc_csn_id_coded, max(num_tranx_rate) as max_norm_num_tranx
FROM NUM_PAT_PER_DEP
WHERE time_in < tpaAdminTime
GROUP BY jc_uid, pat_enc_csn_id_coded
)
