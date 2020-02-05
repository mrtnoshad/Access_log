Select demo.rit_uid, 
  (sum( case when gender = 'Male' then 1 else 0 ) as Male
From noshad.cohort_v2 as cohort
Left join `starr_datalake2018.demographic` as demo 
On (cohort.jc_uid=demo.rit_uid)
GROUP By demo.rit_uid


