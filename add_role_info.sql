drop table if exists noshad_test.cohort_AL_user_name_1;
create table noshad_test.cohort_AL_user_name_1 as
(select AL.* , MP.user_role  
  from noshad_test.cohort_AL as AL
  left join noshad_test.prov_id_map as MP
  on MP.prov_map_id=AL.user_deid)
