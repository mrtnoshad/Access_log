drop table if exists noshad_test.user_map_1;
create table noshad_test.user_map_1 as
(
with
  T1 as -- find the counts of each role
  (select prov_map_id, name as user_role, count(*) as count_of_role
    from starr_datalake2018.treatment_team 
    group by prov_map_id, user_role
    order by prov_map_id, count_of_role Desc),
  
  T2 as -- take the roles with max occurences
  (select prov_map_id, max(count_of_role) as count_of_role
   from T1 
   group by prov_map_id
  order by prov_map_id),
  
  T3 as -- join the tables 
  (select prov_map_id, user_role, count_of_role
  from T1
  join T2 using (prov_map_id, count_of_role)
  order by prov_map_id)
  
-- in terms of ties in the previous max role, select only one according to the role name 
select prov_map_id, max(user_role) as unique_role, count_of_role
   from T3 
   group by prov_map_id, count_of_role
   order by prov_map_id
)
