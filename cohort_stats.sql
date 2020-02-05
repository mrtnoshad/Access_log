Select
  -- gender
  sum(case when (demo.gender = 'Male') then 1 else 0 end) as Male,
  sum(case when (demo.gender != 'Male') then 1 else 0 end) as Femal,
  -- age
  avg(DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(demo.birth_date_jittered AS DATETIME), YEAR) ) as mean_age,   
  sum( case when (DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(demo.birth_date_jittered AS DATETIME), YEAR)  < 50) then 1 else 0 end)  as age_less_than_50,   
  sum( case when (DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(demo.birth_date_jittered AS DATETIME), YEAR)  < 60) then 1 else 0 end)  as age_less_than_60,   
  sum( case when (DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(demo.birth_date_jittered AS DATETIME), YEAR)  < 70) then 1 else 0 end)  as age_less_than_70,
  sum( case when (DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(demo.birth_date_jittered AS DATETIME), YEAR)  < 80) then 1 else 0 end)  as age_less_than_80,
  sum( case when (DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(demo.birth_date_jittered AS DATETIME), YEAR)  >= 80) then 1 else 0 end)  as age_more_than_80,
  
  -- Language
  sum(case when (demo.language != 'English') then 1 else 0 end) as Non_English,
  
  -- Ethnecity
  sum(case when (demo.canonical_ethnicity = 'Non-Hispanic') then 1 else 0 end) as Non_Hispanic,
  sum(case when (demo.canonical_ethnicity = 'Hispanic/Latino') then 1 else 0 end) as Hispanic,
  --sum(case when (demo.canonical_race != 'Non-Hispanic') then 1 else 0 end) as Non_Hispanic,
  
  -- PCP
  sum(case when (demo.cur_pcp_prov_map_id IS NOT Null) then 1 else 0 end) as PCP_set,
  sum(case when (demo.cur_pcp_prov_map_id IS Null) then 1 else 0 end) as PCP_not_set,
  
  -- Prev enc
  sum(case when (demo.recent_conf_enc_jittered IS NOT Null) then 1 else 0 end) as Prev_enc,
  sum(case when (demo.recent_conf_enc_jittered IS Null) then 1 else 0 end) as No_Prev_enc,
  
  -- stroke year
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2010 then 1 else 0 end)  as stroke_year_2010,   
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2011 then 1 else 0 end)  as stroke_year_2011,  
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2012 then 1 else 0 end)  as stroke_year_2012,  
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2013 then 1 else 0 end)  as stroke_year_2013,  
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2014 then 1 else 0 end)  as stroke_year_2014,  
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2015 then 1 else 0 end)  as stroke_year_2015,  
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2016 then 1 else 0 end)  as stroke_year_2016,  
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2017 then 1 else 0 end)  as stroke_year_2017,  
  sum( case when EXTRACT(YEAR FROM CAST(cohort.tpaAdminTime AS DATETIME)) = 2018 then 1 else 0 end)  as stroke_year_2018,  
  
  -- Quarter of the year
  sum( case when EXTRACT(MONTH FROM CAST(cohort.tpaAdminTime AS DATETIME)) < 4 then 1 else 0 end)  as stroke_quarter_1,   
  sum( case when EXTRACT(MONTH FROM CAST(cohort.tpaAdminTime AS DATETIME)) < 7 then 1 else 0 end)  as stroke_quarter_2, 
  sum( case when EXTRACT(MONTH FROM CAST(cohort.tpaAdminTime AS DATETIME)) < 10 then 1 else 0 end)  as stroke_quarter_3, 
  sum( case when EXTRACT(MONTH FROM CAST(cohort.tpaAdminTime AS DATETIME)) <= 12 then 1 else 0 end)  as stroke_quarter_4, 
  
  -- Enc Arival
  sum( case when EXTRACT(HOUR FROM CAST(cohort.inpatientAdmitTime AS DATETIME)) < 6  then 1 else 0 end)  as stroke_time_upto_6,   
  sum( case when EXTRACT(HOUR FROM CAST(cohort.inpatientAdmitTime AS DATETIME)) < 12  then 1 else 0 end)  as stroke_time_upto_12,   
  sum( case when EXTRACT(HOUR FROM CAST(cohort.inpatientAdmitTime AS DATETIME)) < 18  then 1 else 0 end)  as stroke_time_upto_18,   
  sum( case when EXTRACT(HOUR FROM CAST(cohort.inpatientAdmitTime AS DATETIME)) < 24  then 1 else 0 end)  as stroke_time_upto_24,   
  
  -- time-to-TPA 
  avg(DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(cohort.emergencyAdmitTime AS DATETIME), MINUTE) ) as mean_time_2_tpa,  
  STDDEV(DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(cohort.emergencyAdmitTime AS DATETIME), MINUTE) ) as STD_time_2_tpa, 
  MIN(DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(cohort.emergencyAdmitTime AS DATETIME), MINUTE)) as MIN_time_2_tpa, 
  MAX(DATETIME_DIFF( CAST(cohort.tpaAdminTime AS DATETIME), CAST(cohort.emergencyAdmitTime AS DATETIME), MINUTE)) as MAX_time_2_tpa,
  
  
From noshad.cohort_v2 as cohort
Left join `starr_datalake2018.demographic` as demo 
On (cohort.jc_uid=demo.rit_uid)
--GROUP By demo.rit_uid


