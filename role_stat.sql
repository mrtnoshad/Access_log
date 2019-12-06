drop table if exists noshad_test.role_stat;
create table noshad_test.role_stat as
(select user_role, count(user_role) as role_count
  from noshad_test.cohort_AL_user_name
  group by user_role
  order by role_count desc)

