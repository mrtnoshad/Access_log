CREATE OR REPLACE TABLE `noshad.cohort_AL_60` AS
(
-- generate cohort AL
With AL as
(select *
  from noshad.cohort_v2 as cohort
  join `shc_access_log.shc_access_log_de` as al on cohort.jc_uid  = al.rit_uid 
  -- only capture the access logs within 60 min before and after the cohort
where datetime_diff(al.access_time_jittered, cohort.tpaAdminTime, MINUTE) >= -60 
  and datetime_diff(al.access_time_jittered, cohort.tpaAdminTime, MINUTE) < 60
)

-- add user info role to access log from user map 
select AL.* , MP.unique_role as user_role 
  from AL
  left join noshad.user_map as MP
  on MP.prov_map_id=AL.user_deid
)
