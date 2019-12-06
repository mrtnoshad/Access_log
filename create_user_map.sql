drop table if exists noshad_test.user_map;
create table noshad_test.user_map as
(with 
  T1 as 
  (select prov_map_id, name as user_role, count(*) as count_of_role
    from starr_datalake2018.treatment_team 
    group by prov_map_id, user_role
    order by prov_map_id, count_of_role Desc),
  
  T2 as 
  (select prov_map_id, max(count_of_role) as count_of_role
   from T1 
   group by prov_map_id
  order by prov_map_id)

select prov_map_id, user_role, count_of_role
from T1
join T2 using (prov_map_id, count_of_role)
order by prov_map_id)

