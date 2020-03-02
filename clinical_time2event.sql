Select
DATETIME_DIFF(inpatientAdmitTime,emergencyAdmitTime, MINUTE) as t2inpatient,
DATETIME_DIFF(LabOrderTime,emergencyAdmitTime, MINUTE) as t2labOrder,
DATETIME_DIFF(LabResultTime,emergencyAdmitTime, MINUTE) as t2labResult,
DATETIME_DIFF(ctHeadOrderTime,emergencyAdmitTime, MINUTE) as t2CTorder,
DATETIME_DIFF(ctHeadResult,emergencyAdmitTime, MINUTE) as t2CTresult,
DATETIME_DIFF(tpaOrderTime,emergencyAdmitTime, MINUTE) as t2tpaOrder,
DATETIME_DIFF(tpaAdminTime,emergencyAdmitTime, MINUTE) as t2tpa 
FROM `noshad.clinical_event_times` 



