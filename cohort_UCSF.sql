-- This is the UCSF approach to building the stroke cohort and clinical process steps for the Moore Project.
-- Written by Robert Thombley, UCSF
-- Date: 11/13/2019


-- 1) Create reference list of TPA Medications. This must be built internally, as the MEDICATION_IDs are site-dependent. Differentiating alteplase 100mg/50mg from alteplase 2mg (cathflo)
-- is critical at this stage. My approach is to take all of the medications that are like 'alteplase' and then filter out any medication_ids on inspection that are clearly cathflo or
-- not stroke related.  The goal of this step is simply to have a reference list of medication ids, implementation may differ by site.

drop table if exists #STROKE_TPA_MED_IDS
select MEDICATION_ID, NAME into #STROKE_TPA_MED_IDS 
from CLARITY_MEDICATION where NAME like '%ALTEPLASE%' 
and MEDICATION_ID not in (/* LIST OF MEDICATION IDS THAT ARE FOR CATHFLO */)
				

-- 2) Create reference list of ICD9/10 diagnosis codes for AIS (acute ischemic stroke).  This is based off the Joint Commission list of ischemic stroke diagnosis codes (icd9 & 10).
-- REF_BILL_CODE should be the field that holds the ICD code, but it may vary by site.
  
drop table if exists #STROKE_DX
select DX_ID, REF_BILL_CODE, REF_BILL_CODE_SET_C into #STROKE_DX from (
select * from CLARITY_EDG a where REF_BILL_CODE_SET_C =1 and (REF_BILL_CODE IN ('433.01', '433.10','433.11','433.21', '433.31','433.81','433.91','434.00','434.01','434.11','434.91','436')
OR CURRENT_ICD9_LIST IN ('433.01', '433.10','433.11','433.21', '433.31','433.81','433.91','434.00','434.01','434.11','434.91','436'))
union
select * from CLARITY_EDG a where REF_BILL_CODE_SET_C =2 and (REF_BILL_CODE IN ('I63.00','I63.011','I63.012','I63.013','I63.019','I63.02','I63.031','I63.032','I63.033',
																			'I63.039','I63.09','I63.10','I63.111','I63.112','I63.113','I63.119','I63.12','I63.131',
																			'I63.132','I63.133','I63.139','I63.19','I63.20','I63.211','I63.212','I63.213','I63.219',
																			'I63.22','I63.231','I63.232','I63.233','I63.239','I63.29','I63.30','I63.311','I63.312',
																			'I63.313','I63.319','I63.321','I63.322','I63.323','I63.329','I63.331','I63.332','I63.333',
																			'I63.339','I63.341','I63.342','I63.343','I63.349','I63.39','I63.40','I63.411','I63.412',
																			'I63.413','I63.419','I63.421','I63.422','I63.423','I63.429','I63.431','I63.432','I63.433',
																			'I63.439','I63.441','I63.442','I63.443','I63.449','I63.49','I63.50','I63.511','I63.512',
																			'I63.513','I63.519','I63.521','I63.522','I63.523','I63.529','I63.531','I63.532','I63.533',
																			'I63.539','I63.541','I63.542','I63.543','I63.549','I63.59','I63.6','I63.81','I63.89','I63.9',
																			-- INCLUDE NON-BILLABLE CODES TOO			
																			'I63','I63.0','I63.01','I63.03','I63.1','I63.11','I63.13','I63.2','I63.21','I63.23','I63.3',
																			'I63.31','I63.32','I63.33','I63.34','I63.4','I63.41','I63.42','I63.43','I63.44','I63.5','I63.51','I63.52','I63.53','I63.54','I63.8'
																			) x

-- 3) Identify all times where TPA (as defined in step 1) was used. These are the raw encounters of interest. There may be multiple instances of tpa given for a single encounter (initial vs bolus dose), 
-- this code just grabs the 1st one.

drop table if exists #tpa_cases
select * into #tpa_cases from 
	( select 
	ROW_NUMBER() over (partition by mar.MAR_ENC_CSN ORDER BY mar.TAKEN_TIME ASC, mar.ORDER_MED_ID ASC) as n,
	(select z.name from ZC_MAR_RSLT z where mar.MAR_ACTION_C = z.RESULT_C) as ACTION_NAME, 
	mar.ORDER_MED_ID as MAR_ORDER_MED_ID, mar.LINE as MARLINE, mar.TAKEN_TIME, 
	meds.MEDICATION_ID as MAR_MED_ID, 
	mar.MAR_ACTION_C, 
	meds.NAME as MED_NAME,
	om.*
	from MAR_ADMIN_INFO mar
	inner join ORDER_MED om on om.ORDER_MED_ID = mar.ORDER_MED_ID
	inner join #STROKE_TPA_MED_IDS meds on meds.MEDICATION_ID = om.medication_id
	inner join PAT_ENC pe on pe.PAT_ENC_CSN_ID = mar.MAR_ENC_CSN
	where pe.ENC_TYPE_C = '3' and mar.MAR_ACTION_C IN (1, 102, 113, 137, 134, 13, 127, 123, 12, 114, 111, 108, 105, 119) 
	) x  
 where x.n = 1


 -- 4) Identify all stroke encounter ids amongst the TPA reference list, as determined by having at least 1 diagnosis code in the Joint Commission list.
 
 -- This step additionally checks that the found encounters have: 
 -- an ED admission that is not through the transfer center (pat_class_c = '103' and event_type_c = '1')
 -- an inpatient admission (pat_class_c = '101'), 
 -- are UCSF patients (SERV_AREA_ID = 10)
 -- and completed encounters (CODING_STATUS_C = 4)
 -- for patients over age 18 at the time the encounter began (datediff(year, pat.birth_date, peh.ADT_ARRIVAL_TIME) >= 18)
 

drop table if exists #stroke_csns
--111
select DISTINCT csn.PAT_ID, csn.PAT_ENC_CSN_ID
into #stroke_csns
from #tpa_cases csn
inner join PAT_ENC_HSP peh on peh.PAT_ENC_CSN_ID = csn.PAT_ENC_CSN_ID
inner join HSP_ACCOUNT hsp on hsp.PRIM_ENC_CSN_ID = csn.pat_enc_csn_id
inner join HSP_ACCT_DX_LIST dx  on hsp.hsp_account_id = dx.hsp_account_id
inner join #STROKE_DX cms on cms.DX_ID = dx.DX_ID
inner join CLARITY_LOC loc on hsp.DISCH_LOC_ID = loc.loc_id
inner join CLARITY_SA sa on loc.SERV_AREA_ID = sa.SERV_AREA_ID
inner join PATIENT pat on pat.pat_id = csn.pat_id
inner join CLARITY_ADT admit on csn.pat_enc_csn_id = admit.pat_enc_csn_id
inner join CLARITY_ADT inpatient on inpatient.pat_enc_csn_id = csn.pat_enc_csn_id
where admit.event_type_c = 1 -- Admission
  and admit.pat_class_c = '103' -- UCSF Emergency Services
  and inpatient.pat_class_c = '101' -- Inpatient
  and datediff(year,pat.BIRTH_DATE, peh.ADT_ARRIVAL_TIME) >= 18
  and sa.SERV_AREA_ID = 10
  and hsp.CODING_STATUS_C = 4

-- 5) Join #tpa_cases & #stroke_csns to create the stroke list. This is our cohort.
drop table if exists #stroke_time
select a.PAT_ENC_CSN_ID, year(peh.ADT_ARRIVAL_TIME) as year, 
	c.medication_id, c.DISPLAY_NAME, c.MED_NAME, 
	peh.ADT_ARRIVAL_TIME as ARRIVAL_TIME, c.TAKEN_TIME as TPA_ADMINISTRATION_TIME, 
	c.ORDER_INST as TPA_ORDER_TIME, 
	datediff(minute, peh.ADT_ARRIVAL_TIME, c.TAKEN_TIME) as D2N_CALC
 into #stroke_time
 from #stroke_csns a
 inner join #tpa_cases c
 on a.PAT_ENC_CSN_ID = c.PAT_ENC_CSN_ID
 inner join PAT_ENC_HSP peh
 on peh.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID



 -- 6) Identify imaging scans during the diagnostic window. 
 -- Define imaging types of interest.  Found that non-con CT scans are not present during the diagnostic window for the bulk of the test events.
 -- Looking it the data, there are a number of other types of imaging orders being placed (CT ANGIOGRAM/CT BRAIN/MR BRAIN). The list of proc_ids was selected by 
 -- inspecting the results.  It will be site dependent how this is implemented.  Please see the attached spreadsheet for additional information.

 drop table if exists #angio
select PROC_ID, PROC_NAME,
case when PROC_ID IN (/* LIST OF NON-CON SCAN PROC_IDs */) then 1 else 0 end as NC_SCAN
 into #angio 
 from CLARITY_EAP where PROC_ID IN (/* LIST OF STROKE IMAGING PROCEDURES - SEE SPREADSHEET */) 


-- Find all of the matching imaging studies.  
-- This is stratified by whether or not the scan is NON_CON or CONTRAST. 
-- Scans that are not completed (STUDY_STATUS_C <> '99') are excluded
-- Scans that are CANCELLED (IS_CANCELED_YN <> 'N', NULL) are excluded
-- Scans that are not in procedure category 11 or 12 (CT/MRI orderables) are excluded

drop table if exists #img_studies
select t.PAT_ENC_CSN_ID, ORDER_ID, NC_SCAN, a.PROC_ID, a.PROC_NAME, ORDERING_DTTM, BEGIN_EXAM_DTTM, row_number() over (partition by t.PAT_ENC_CSN_ID, NC_SCAN ORDER BY ORDERING_DTTM ASC, BEGIN_EXAM_DTTM ASC) as ordering,
row_number() over (partition by t.PAT_ENC_CSN_ID ORDER BY ORDERING_DTTM ASC, BEGIN_EXAM_DTTM ASC) as ORDERING_ALL_TEST
into #img_studies 
from V_IMG_STUDY a
inner join #stroke_time t
on t.PAT_ENC_CSN_ID = a.ORDERING_CSN_ID
inner join #angio ang on a.PROC_ID = ang.PROC_ID
left join EDP_PROC_CAT_INFO b
on a.PROC_CAT_ID = b.PROC_CAT_ID
where (IS_CANCELED_YN is null or IS_CANCELED_YN = 'N')
and a.PROC_CAT_ID IN ('11','12') and STUDY_STATUS_C = '99'

-- Join this data to the cohort definition table #stroke_time.
-- Various stratifcations are included here: 1st non-con, 1st not non-con, 1st of any matching 

drop table if exists #scan_timing
select a.*, nc.PROC_NAME as NON_CON_PROCEDURE, nc.ORDERING_DTTM as NON_CON_ORDER_TIME, nc.BEGIN_EXAM_DTTM as NON_CON_EXAM_TIME,
 con.PROC_NAME as OTHER_STROKE_PROCEDURE, con.ORDERING_DTTM as OTHER_STROKE_ORDER_TIME, con.BEGIN_EXAM_DTTM as OTHER_STROKE_EXAM_TIME,
 a1.PROC_NAME as FIRST_PROCEDURE, a1.ORDERING_DTTM as FIRST_IMG_ORDER_TIME, a1.BEGIN_EXAM_DTTM as FIRST_EXAM_TIME 
into #scan_timing
from #stroke_time a
left outer join #img_studies nc
on (nc.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID and nc.ordering = 1 and nc.NC_SCAN = 1)
left outer join #img_studies con
on (con.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID and con.ordering = 1 and con.NC_SCAN = 0)
left outer join #img_studies a1
on (a1.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID and a1.ordering_all_test = 1)

-- 7) The flowsheets table has a flattened hierarchy structure.  In order to allow us to find, say, all of the flo_meas_ids that are part
-- of GCS documentation, we will need a map between the grouping's FLO_MEAS_ID and the component FLO_MEAS_IDS. #GRP_NAMES is that map.

drop table if exists #flo_test
select DISTINCT FLO_MEAS_ID, FLO_MEAS_NAME 
into #flo_test 
from (
	select n.ROW_TYP_C, n.FLO_MEAS_ID, n.FLO_MEAS_NAME, n.DISP_NAME, MEAS_VALUE 
	from IP_FLWSHT_REC fsd
	inner join IP_FLWSHT_MEAS m
	on m.FSD_ID = fsd.FSD_ID
	inner join PAT_ENC_HSP b
	on fsd.INPATIENT_DATA_ID = b.INPATIENT_DATA_ID
	inner join IP_FLO_GP_DATA n
	on m.FLO_MEAS_ID = n.FLO_MEAS_ID
	inner join #stroke_time t
	on t.PAT_ENC_CSN_ID = b.PAT_ENC_CSN_ID
	) x

drop table if exists #meas_id_map
select distinct FLO_PREF_GROUP_ID, id as FLO_MEAS_ID into #meas_id_map
from (
	select FLO_PREF_GROUP_ID, id, row_Number() over (partition by ID order by CONTACT_DATE DESC) as bn from #flo_test b
	left join IP_FLO_OVRTM_SNGL a
	on a.id = b.FLO_MEAS_ID 
	where FLO_PREF_GROUP_ID is not null) x 
where x.bn = 1

-- CREATE GROUP to COMPONENT MAPPING
drop table if exists #GRP_NAMES
select grp.FLO_MEAS_NAME as GROUP_NAME, map.flo_PREF_GROUP_ID as GROUP_ID,
	ind.FLO_MEAS_NAME as COMPONENT_NAME, map.flo_meas_id as COMPONENT_ID 
into #GRP_NAMES
from #meas_id_map map 
left join IP_FLO_GP_DATA grp
on map.flo_pref_group_id = grp.flo_meas_id
left join IP_FLO_GP_DATA ind
on map.FLO_MEAS_ID = ind.flo_meas_id

-- Example usage:
-- select * from #GRP_NAMES where COMPONENT_NAME like '%stroke%'

-- Important: 
-- TRIAGE START TIME: FLO_MEAS_ID = '######' (site dependent), ##TRAIGE_START_TIME in this code
-- triage complete ##TRIAGE_END_TIME, 
-- ED NEURO (wdl) 
-- gcs group id: ##GCS_GROUP_ID
-- neuro, simple, group: ##NEURO_SIMPLE_GROUP_ID
-- nih ss, group: ##NIHSS_GROUP_ID
-- tpa ordered group id: 
-- NIH STROKE SCALE group id: 
-- Triage Group ID: 

drop table if exists #triage_v1

	select b.PAT_ENC_CSN_ID, g.GROUP_ID, min(ENTRY_TIME) as EARLIEST_TIME, max(ENTRY_TIME) as LATEST_TIME
	into #triage_v1
	from IP_FLWSHT_REC fsd
	inner join IP_FLWSHT_MEAS m
	on m.FSD_ID = fsd.FSD_ID
	inner join PAT_ENC_HSP b
	on fsd.INPATIENT_DATA_ID = b.INPATIENT_DATA_ID
	inner join #stroke_time t
	on t.PAT_ENC_CSN_ID = b.PAT_ENC_CSN_ID
	inner join IP_FLO_GP_DATA n
	on m.FLO_MEAS_ID = n.FLO_MEAS_ID
	left join #GRP_NAMES g
	on g.component_id = n.FLO_MEAS_ID
	where  g.group_id IN ('##TRIAGE_GROUP') --Triage Group ID
	group by b.PAT_ENC_CSN_ID, g.GROUP_ID

drop table if exists #triage_v2
	select b.PAT_ENC_CSN_ID, 
			min(case when n.FLO_MEAS_ID = '##TRIAGE_START_TIME' then ENTRY_TIME else NULL end) as EARLIEST_TIME, 
			max(case when n.FLO_MEAS_ID = '##TRIAGE_END_TIME' then ENTRY_TIME else NULL end) as LATEST_TIME 
	into #triage_v2
	from IP_FLWSHT_REC fsd
	inner join IP_FLWSHT_MEAS m
	on m.FSD_ID = fsd.FSD_ID
	inner join PAT_ENC_HSP b
	on fsd.INPATIENT_DATA_ID = b.INPATIENT_DATA_ID
	inner join #stroke_time t
	on t.PAT_ENC_CSN_ID = b.PAT_ENC_CSN_ID
	inner join IP_FLO_GP_DATA n
	on m.FLO_MEAS_ID = n.FLO_MEAS_ID
	left join #GRP_NAMES g
	on g.component_id = n.FLO_MEAS_ID
	where n.FLO_MEAS_ID IN ('##TRIAGE_START_TIME','##TRIAGE_END_TIME') -- Triage Start Time flo_meas_id, Triage complete flo_meas_id
	group by b.PAT_ENC_CSN_ID

-- Measuring triage start time in two different ways since some of the cases are defined one way, others defined another.
drop table if exists #triage_times
select a.*, 
		coalesce(v1.EARLIEST_TIME,v2.EARLIEST_TIME) as TRIAGE_START_TIME, 
		coalesce(v1.LATEST_TIME, v2.LATEST_TIME) as TRIAGE_END_TIME
into #triage_times
from #stroke_time a
left join #triage_v1 v1
on v1.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID
left join #triage_v2 v2
on v2.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID

-- 8) Add GCS/NIHSS taken time
-- Get all of the neuro exam data in one table
drop table if exists #neuro_exams
select b.PAT_ENC_CSN_ID, g.GROUP_ID, g.GROUP_NAME, count(DISTINCT(m.ENTRY_TIME)) as cnt, min(m.ENTRY_TIME) as EARLIEST_TIME
into #neuro_exams
from IP_FLWSHT_REC fsd
inner join IP_FLWSHT_MEAS m
on m.FSD_ID = fsd.FSD_ID
inner join PAT_ENC_HSP b
on fsd.INPATIENT_DATA_ID = b.INPATIENT_DATA_ID
inner join IP_FLO_GP_DATA n
on m.FLO_MEAS_ID = n.FLO_MEAS_ID
left join #GRP_NAMES g
on g.component_id = n.FLO_MEAS_ID
inner join #triage_times t
on t.PAT_ENC_CSN_ID = b.PAT_ENC_CSN_ID
where g.group_id IN ('##NIHSS_GROUP_ID','##NEURO_SIMPLE_GROUP_ID','##GCS_GROUP_ID')
group by b.PAT_ENC_CSN_ID, g.GROUP_ID, g.GROUP_NAME

-- Identify the times of each test
drop table if exists #neuro_testing
select a.*,
--n.cnt as NIHSS_CNT, 
--s.cnt as NEURO_CNT, 
--g.cnt as GCS_CNT, 
case when n.EARLIEST_TIME is not null then 'NIHSS'
	when g.EARLIEST_TIME is not null then 'GCS'
	when s.EARLIEST_TIME is not null then 'SIMPLE NEURO'
	else NULL
end as TEST_PERFORMED,
s.EARLIEST_TIME as NEURO_TIME,
g.EARLIEST_TIME as GCS_TIME,
n.EARLIEST_TIME as NIHSS_TIME,
coalesce(n.EARLIEST_TIME, g.EARLIEST_TIME, s.EARLIEST_TIME) as ASSIGNED_TEST_TIME
into #neuro_testing
from #triage_times a
left join #neuro_exams n 
on (n.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID and n.GROUP_ID = '##NIHSS_GROUP_ID') 
left join #neuro_exams g
on (g.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID and g.GROUP_ID = '##GCS_GROUP_ID') 
left join #neuro_exams s
on (s.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID and s.GROUP_ID = '##NEURO_SIMPLE_GROUP_ID') 

-- ID code stroke times, if they exist at the site
drop table if exists #CODE_STROKE_LONG
	select t.PAT_ENC_CSN_ID, b.ADT_ARRIVAL_TIME, n.FLO_MEAS_ID, min(MEAS_VALUE) as MEAS_VAL, min(ENTRY_TIME) as MIN_ENTRY
	into #CODE_STROKE_LONG
	from IP_FLWSHT_REC fsd
	inner join IP_FLWSHT_MEAS m
	on m.FSD_ID = fsd.FSD_ID
	inner join PAT_ENC_HSP b
	on fsd.INPATIENT_DATA_ID = b.INPATIENT_DATA_ID
	inner join IP_FLO_GP_DATA n
	on m.FLO_MEAS_ID = n.FLO_MEAS_ID
	inner join #stroke_time t
	on t.PAT_ENC_CSN_ID = b.PAT_ENC_CSN_ID
	where n.FLO_MEAS_ID IN ('##CODE_STROKE_ID_1','##CODE_STROKE_ID_2')	
	group by t.PAT_ENC_CSN_ID, b.ADT_ARRIVAL_TIME, n.FLO_MEAS_ID


-- Convert the different code stroke measurements into 1 variable
drop table if exists #CODE_STROKE_WIDE
	select a.*, coalesce(dt.CALENDAR_DT, t.MIN_ENTRY) + 
		CAST(DATEADD(s, CAST(t.MEAS_VAL as NUMERIC), 0) as DATETIME) as CODE_STROKE_TIME 
	INTO #CODE_STROKE_WIDE
	from #stroke_time a
	left join #CODE_STROKE_LONG d
	on (a.PAT_ENC_CSN_ID = d.PAT_ENC_CSN_ID and d.FLO_MEAS_ID = '##CODE_STROKE_ID_1')
	left join DATE_DIMENSION dt
	on d.MEAS_VAL = dt.EPIC_DTE
	left join #CODE_STROKE_LONG t
	on (a.PAT_ENC_CSN_ID = t.PAT_ENC_CSN_ID and t.FLO_MEAS_ID = '##CODE_STROKE_ID_2')

-- ID LAST KNOWN WELL TIME, if measured
drop table if exists #LAST_KNOWN_WELL
	select t.PAT_ENC_CSN_ID, b.ADT_ARRIVAL_TIME, n.FLO_MEAS_ID, min(MEAS_VALUE) as MEAS_VAL, min(ENTRY_TIME) as MIN_ENTRY
	into #LAST_KNOWN_WELL
	from IP_FLWSHT_REC fsd
	inner join IP_FLWSHT_MEAS m
	on m.FSD_ID = fsd.FSD_ID
	inner join PAT_ENC_HSP b
	on fsd.INPATIENT_DATA_ID = b.INPATIENT_DATA_ID
	inner join IP_FLO_GP_DATA n
	on m.FLO_MEAS_ID = n.FLO_MEAS_ID
	inner join #stroke_time t
	on t.PAT_ENC_CSN_ID = b.PAT_ENC_CSN_ID
	where n.FLO_MEAS_ID IN ('##LAST_KNOWN_WELL_ID_1','##LAST_KNOWN_WELL_ID_2')	
	group by t.PAT_ENC_CSN_ID, b.ADT_ARRIVAL_TIME, n.FLO_MEAS_ID

-- Convert from long form to wide form (merge into a single variable)
drop table if exists #LAST_KNOWN_WELL_WD
	select a.*, coalesce(dt.CALENDAR_DT, t.MIN_ENTRY) + 
		CAST(DATEADD(s, CAST(t.MEAS_VAL as NUMERIC), 0) as DATETIME) as LAST_KNOWN_WELL_TIME 
	into #LAST_KNOWN_WELL_WD
	from #stroke_time a
	left join #LAST_KNOWN_WELL d
	on (a.PAT_ENC_CSN_ID = d.PAT_ENC_CSN_ID and d.FLO_MEAS_ID = '##LAST_KNOWN_WELL_ID_1')
	left join DATE_DIMENSION dt
	on d.MEAS_VAL = dt.EPIC_DTE
	left join #LAST_KNOWN_WELL t
	on (a.PAT_ENC_CSN_ID = t.PAT_ENC_CSN_ID and t.FLO_MEAS_ID = '##LAST_KNOWN_WELL_ID_2')


-- ID LDA Placement Times. This allows us to determine the IV lines that were placed.
drop table if exists #LDA_INFO
select x.PAT_ENC_CSN_ID, x.IP_LDA_ID, x.NAME, x.N_LINES, x.earliest_line, x.IV_ON_ARRIVAL,
		peh.ADT_ARRIVAL_TIME,
		case 
			when IV_ON_ARRIVAL = 1 then ADT_ARRIVAL_TIME
			else dt.CALENDAR_DT + CAST(DATEADD(s, CAST(x.IV_TIME_PLACED as NUMERIC), 0) as DATETIME)
		end as PLACEMENT_TIME
	into #LDA_INFO
	from 
	(
	select a.PAT_ENC_CSN_ID, a.IP_LDA_ID, z.NAME, 
		count(distinct(a.IP_LDA_ID)) as n_lines,
		min(a.PLACEMENT_INSTANT) as earliest_line, 
		max(case when e.FLO_MEAS_ID = '##IV_ON_ARRIVAL_INDICATOR_ID' and e.MEAS_VALUE = 'Yes' then 1 else 0 end) as IV_ON_ARRIVAL,
		min(case when e.FLO_MEAS_ID = '##IV_DATE_PLACED_ID' and e.MEAS_VALUE IS NOT NULL then e.MEAS_VALUE else NULL end) as IV_DATE_PLACED,
		min(case when e.FLO_MEAS_ID = '##IV_TIME_PLACED_ID' and e.MEAS_VALUE > 0 then e.MEAS_VALUE else NULL end) as IV_TIME_PLACED
	from IP_LDA_NOADDSINGLE a
	inner join #stroke_time t
	on t.PAT_ENC_CSN_ID = a.PAT_ENC_CSN_ID
	left outer join IP_FLO_LDA_TYPES b
	on a.FLO_MEAS_ID = b.ID and b.CONTACT_DATE_REAL = a.LDA_GROUP_CDR
	left outer join IP_FLOWSHEET_ROWS c
	on a.IP_LDA_ID = c.IP_LDA_ID
	left outer join IP_FLWSHT_REC d
	on c.INPATIENT_DATA_ID = d.INPATIENT_DATA_ID
	left outer join IP_FLWSHT_MEAS e
	on e.OCCURANCE = c.LINE  and d.FSD_ID = e.FSD_ID
	left outer join IP_FLO_GP_DATA g
	on g.FLO_MEAS_ID = e.FLO_MEAS_ID
	left outer join ZC_LINES_GROUP z
	on z.LINES_GROUP_C = b.LDA_TYPE_OT_C
	where b.LDA_TYPE_OT_C IN ('7','14') 
	group BY a.PAT_ENC_CSN_ID, a.IP_LDA_ID, z.NAME
	) x
	left join DATE_DIMENSION dt
	on dt.EPIC_DTE = x.IV_DATE_PLACED
	left join PAT_ENC_HSP peh
	on x.PAT_ENC_CSN_ID = peh.PAT_ENC_CSN_ID

-- Extract earliest placement time
drop table if exists #LDA_TIMES
select PAT_ENC_CSN_ID, min(PLACEMENT_TIME) as EARLIEST_PLACEMENT
into #LDA_TIMES
from #LDA_INFO
group by PAT_ENC_CSN_ID


-- ID LAB ORDERING AND RESULTING TIMES

drop table if exists #LAB_TIMES
select x.PAT_ENC_CSN_ID, min(ORDER_TIME) as EARLIEST_LAB_DRAW, min(RESULT_TIME) as EARLIEST_RESULT_TIME
into #LAB_TIMES
from (
select child.ORDER_PROC_ID, child.PAT_ENC_CSN_ID, child.ORDER_TIME, child.RESULT_TIME
from ORDER_INSTANTIATED a
inner join ORDER_PROC child
on child.ORDER_PROC_ID = a.INSTNTD_ORDER_ID
inner join ORDER_PROC parent
on parent.ORDER_PROC_ID = a.ORDER_ID
inner join #scan_timing t
on t.PAT_ENC_CSN_ID = child.PAT_ENC_CSN_ID
and child.ORDER_TYPE_C = 7 -- LAB
and child.LAB_STATUS_C = 3 -- FINAL RESULT
) x
group by x.PAT_ENC_CSN_ID

-- XX) BRING PATHWAY TOGETHER
drop table if exists #MOORE_COHORT
select  
a.PAT_ENC_CSN_ID,
row_number() over (order by a.PAT_ENC_CSN_ID) as CSN_STAND_IN,
a.YEAR,
e.LAST_KNOWN_WELL_TIME,
a.ARRIVAL_TIME,
d.CODE_STROKE_TIME,
c.TRIAGE_START_TIME, 
c.TRIAGE_END_TIME, 
f.EARLIEST_PLACEMENT as FIRST_IV_PLACEMENT_TIME,
a.NON_CON_PROCEDURE, 
a.NON_CON_ORDER_TIME,
a.NON_CON_EXAM_TIME,
a.FIRST_PROCEDURE as FIRST_IMAGING_PROCEDURE, 
a.FIRST_IMG_ORDER_TIME as FIRST_IMAGING_ORD_TIME,
a.FIRST_EXAM_TIME as FIRST_IMAGING_EXAM_TIME,
b.TEST_PERFORMED as NEURO_TEST_PERFORMED, 
b.ASSIGNED_TEST_TIME as FIRST_NEURO_TEST_TIME, 
g.EARLIEST_LAB_DRAW as FIRST_LAB_DRAW_TIME,
g.EARLIEST_RESULT_TIME as FIRST_LAB_RESULT_TIME,
a.TPA_ORDER_TIME,
a.TPA_ADMINISTRATION_TIME,
a.D2N_CALC
into #MOORE_COHORT
from #scan_timing a
left join #neuro_testing b on a.PAT_ENC_CSN_ID = b.PAT_ENC_CSN_ID
left join #triage_times c  on a.PAT_ENC_CSN_ID = c.PAT_ENC_CSN_ID
left join #CODE_STROKE_WIDE d on a.PAT_ENC_CSN_ID = d.PAT_ENC_CSN_ID
left join #LAST_KNOWN_WELL_WD e on a.PAT_ENC_CSN_ID = e.PAT_ENC_CSN_ID
left join #LDA_TIMES f on a.PAT_ENC_CSN_ID = f.PAT_ENC_CSN_ID
left join #LAB_TIMES g on a.PAT_ENC_CSN_ID = g.PAT_ENC_CSN_ID
ORDER BY YEAR, a.PAT_ENC_CSN_ID


/* Example usage:

Identify timing between process steps:
select PAT_ENC_CSN_ID, YEAR,
datediff(minute,a.ARRIVAL_TIME, a.NON_CON_ORDER_TIME) as DOOR_TO_NON_CON_ORDER,
datediff(minute,a.ARRIVAL_TIME, a.NON_CON_EXAM_TIME) as DOOR_TO_NON_CON,
datediff(minute,a.ARRIVAL_TIME, c.TRIAGE_START_TIME) as DOOR_TO_TRIAGE,
datediff(minute,a.ARRIVAL_TIME, b.ASSIGNED_TEST_TIME) as DOOR_TO_NIHSS,
datediff(minute,a.ARRIVAL_TIME, a.FIRST_EXAM_TIME) as DOOR_TO_ANY_IMG,
datediff(minute,a.ARRIVAL_TIME, a.TPA_ORDER_TIME) as DOOR_TO_TPA_ORDER
from #MOORE_COHORT

*/
