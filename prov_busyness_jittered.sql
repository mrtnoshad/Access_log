-- Generate table of unique cohort encounters with tpa times
  With
  
  U_Enc AS
  (SELECT pat_enc_csn_id_coded, user_deid, tpaAdminTime
  FROM `noshad.cohort_AL` as AL
  GROUP BY pat_enc_csn_id_coded, user_deid, tpaAdminTime
  )
  
  --- Generate NUM of unique encounters per user
SELECT U_Enc.*, count(DISTINCT AL.csn) as num_enc 
  FROM shc_access_log.shc_access_log_de as AL 
  Left join U_Enc
  Using (user_deid)
  WHERE 
     DATETIME_SUB(U_Enc.tpaAdminTime, INTERVAL 60 MINUTE) < AL.access_time_jittered
    AND AL.access_time_jittered < U_Enc.tpaAdminTime
    
  GROUP BY U_Enc.pat_enc_csn_id_coded, U_Enc.user_deid, U_Enc.tpaAdminTime
  ORDER BY U_Enc.tpaAdminTime
  

