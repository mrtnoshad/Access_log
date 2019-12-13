drop table if exists noshad_test.adt_summary;
create table noshad_test.adt_summary as
(select ADT_in.jc_uid, ADT_in.pat_enc_csn_id_coded, ADT_in.department_id, ADT_in.in_event_type, 
        ADT_out.out_event_type, ADT_in.event_time_jittered as in_time, ADT_out.event_time_jittered as out_time
  
  from starr_datalake2018.adt as ADT_in,
       starr_datalake2018.adt as ADT_out
  
  where ADT_in.jc_uid = ADT_out.jc_uid
    and ADT_in.pat_enc_csn_id_coded = ADT_out.pat_enc_csn_id_coded
    and ADT_in.department_id = ADT_out.department_id
    and ( ADT_in.in_event_type = 'Admission' or ADT_in.in_event_type = 'Transfer In')
    and ( ADT_out.out_event_type = 'Discharge' or ADT_out.out_event_type = 'Transfer Out')
)

