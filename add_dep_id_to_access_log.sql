CREATE Table noshad.shc_access_log_de_dep_id AS
(SELECT AL.*, ADT.department_id 
  FROM `shc_access_log.shc_access_log_de` as AL
  LEFT JOIN `noshad.adt_summary` as ADT
  ON ADT.jc_uid  = AL.rit_uid
  WHERE  
    ADT.in_time < AL.access_time_jittered 
    AND AL.access_time_jittered  < ADT.out_time)
    
# Then run the following to remove the duplicate access log information
CREATE TABLE `noshad.shc_access_log_de_dep_id_merged` AS
(SELECT * Except (department_id), min(department_id) as department_id  FROM `som-nero-phi-jonc101.noshad.shc_access_log_de_dep_id` 
GROUP BY rit_uid, process_id,metric_id, metric_name, user_deid,workstation_id,csn,access_action_c,access_action_name, deployment_id,
audit_session_id, access_time_jittered_utc,access_time_jittered)
