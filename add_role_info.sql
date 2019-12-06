drop table if exists noshad_test.cohort_AL_user_role;
create table noshad_test.cohort_AL_user_role as
(select AL.* , MP.user_role  
  from noshad_test.cohort_AL as AL
  left join noshad_test.user_map as MP
  on MP.prov_map_id=AL.user_deid)
