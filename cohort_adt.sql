drop table if exists noshad.cohort_AL_adt;
create table noshad.cohort_AL_adt as

(select 
      ADT.jc_uid, ADT.pat_enc_csn_id_coded, ADT.department_id, ADT.in_time, ADT.out_time
  
  from noshad.adt_summary as ADT,
       noshad.cohort_AL_60 as CH
  
  where ADT.pat_enc_csn_id_coded in (CH.pat_enc_csn_id_coded)
  group by ADT.jc_uid, ADT.pat_enc_csn_id_coded, ADT.department_id, ADT.in_time, ADT.out_time
  order by ADT.pat_enc_csn_id_coded, ADT.in_time
)




    
