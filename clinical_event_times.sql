CREATE OR REPLACE TABLE noshad.clinical_event_times AS
Select cohort.*, min(LR.result_time_jittered) as LabResultTime,
FROM (
select 
      op.jc_uid, op.pat_enc_csn_id_coded as pat_enc_csn_id_coded,
      admit.event_type, admit.pat_class, admit.effective_time_jittered as emergencyAdmitTime, 
      min(Lab_order.order_inst_jittered) as LabOrderTime,
      min(opCT.order_inst_jittered) as ctHeadOrderTime,
      min(Rad.result_time_jittered) as ctHeadResult,
      --om.med_description as tpaDescription, 
      min(om.order_time_jittered) as tpaOrderTime,
      min(mar.taken_time_jittered) as tpaAdminTime,
      inpatient.pat_class as inptClass, min(inpatient.effective_time_jittered) as inpatientAdmitTime,
    from
      starr_datalake2018.order_proc as op, 
      starr_datalake2018.adt as admit, 
      starr_datalake2018.order_proc as opCT,
      starr_datalake2018.order_med as om,
      starr_datalake2018.mar as mar,
      starr_datalake2018.adt as inpatient,
      starr_datalake2018.encounter as enc
     LEFT JOIN starr_datalake2018.radiology_report_meta as Rad on (op.pat_enc_csn_id_coded = Rad.pat_enc_csn_id_coded)
     LEFT JOIN starr_datalake2018.order_proc as Lab_order on (op.pat_enc_csn_id_coded = Lab_order.pat_enc_csn_id_coded)
     
    where op.display_name like 'Patient on TPA%'
      and op.pat_enc_csn_id_coded = admit.pat_enc_csn_id_coded
      and op.pat_enc_csn_id_coded = opCT.pat_enc_csn_id_coded
      and op.pat_enc_csn_id_coded = om.pat_enc_csn_id_coded
      and op.pat_enc_csn_id_coded = inpatient.pat_enc_csn_id_coded
      and op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded
      and om.order_med_id_coded = mar.order_med_id_coded
      
      --and 
      and admit.event_type_c = 1 -- Admission
      and admit.pat_class_c = '112' -- Emergency Services
      and opCT.proc_code like 'IMGCTH%' -- CT Head orders
      and Lab_order.proc_code like 'LAB%'
      --and LAB.proc_code like 'LAB%'
      --and om.medication_id = 86145 -- ALTEPLASE 100mg infusion
      and ((om.med_description like '%ALTEPLASE%' AND om.med_description like '%FOR STROKE%') 
      OR om.med_description like '%ALTEPLASE 100%')--'%ALTEPLASE 100%')
      and inpatient.pat_class_c = '126' -- Inpatient
      and datetime_diff(om.order_time_jittered, admit.effective_time_jittered, MINUTE) <= 270  -- within 4.5 hours
    group by 
      op.jc_uid, op.pat_enc_csn_id_coded, 
      admit.event_type, admit.pat_class, admit.effective_time_jittered, 
      --om.med_description,
      inpatient.pat_class
    order by emergencyAdmitTime
) as cohort
LEFT JOIN `starr_datalake2018.lab_result` as LR on (cohort.pat_enc_csn_id_coded = LR.pat_enc_csn_id_coded)
WHERE LR.proc_code like 'LAB%'
GROUP BY jc_uid, pat_enc_csn_id_coded, event_type, pat_class,
      emergencyAdmitTime, 
     LabOrderTime,
ctHeadOrderTime,
ctHeadResult,
      --om.med_description as tpaDescription, 
 tpaOrderTime,
tpaAdminTime,
inptClass, inpatientAdmitTime
