(select prov_map_id, max(count_of_role) as count_of_role
  from
    (select prov_map_id, name as user_role, count(*) as count_of_role
    from starr_datalake2018.treatment_team 
    group by prov_map_id, user_role
    order by prov_map_id, count_of_role Desc)
  group by prov_map_id
  order by prov_map_id)
