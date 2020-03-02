# Access_log
Access_log data, Moore Project

## Steps to Run the code:

### Department and Provider Business:

*Generate features:*
* Create the cohort table (run cohort_v2.sql)
* Run adt_summary.sql to create a table of summarized arrival/discharge/transfer information
* Generate shc_access_log_de_dep_id which is the same as sch_access_log, but also includes the department_id information joined
* Run the Jupiter notebook department_busyness.ipynp
* Run the Jupiter notebook prov_busyness.ipynp

*Plot the results:*
* Download the features
* Run Jupiter notebook busyness_results.ipynp

### Team Experience (Individual and Shared):
* Create the cohort table (run cohort_v2.sql) if haven’t created before
* Generate activity log for the cohort patients with limited access log: all of the logs related to the cohort patients within 60 min before and after tpa time (run create_cohort_AL_60.sql); need this for the team experience features 
* Generate t2tpa 
* Run Team_experience.ipynp

### Event time Analysis
* Run clinical_event_times.sql to generate the table of cohort event times.
* Run the jupyter notebook event_and_action_analysis.Ipynp
