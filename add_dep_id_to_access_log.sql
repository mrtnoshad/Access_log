CREATE Table noshad.shc_access_log_de_dep_id AS
(SELECT AL.*, ADT.department_id 
  FROM `shc_access_log.shc_access_log_de` as AL
  LEFT JOIN `noshad.adt_summary` as ADT
  ON ADT.jc_uid  = AL.rit_uid
  WHERE  
    ADT.in_time < AL.access_time_jittered 
    AND AL.access_time_jittered  < ADT.out_time)
