drop table if exists noshad_test.cohort_AL_adt;
create table noshad_test.cohort_AL_adt as

(select 
      ADT.jc_uid, ADT.pat_enc_csn_id_coded, ADT.department_id, ADT.in_event_type, 
        ADT.out_event_type, ADT.in_time, ADT.out_time
  
  from noshad_test.adt_summary as ADT,
       noshad_test.cohort_AL_user_role as CH
  
  where ADT.pat_enc_csn_id_coded in (CH.pat_enc_csn_id_coded)
  group by ADT.jc_uid, ADT.pat_enc_csn_id_coded, ADT.department_id, ADT.in_event_type, 
        ADT.out_event_type, ADT.in_time, ADT.out_time
  order by ADT.pat_enc_csn_id_coded, ADT.in_time
)




    
