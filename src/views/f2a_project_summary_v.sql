create or replace view f2a_project_summary_v as
  select project_id, module_type_id, complexity_type_id, count(*) no_of_modules
  from f2a_modules
  where module_type_id = (select module_type_id from f2a_module_types where module_type = 'FORM')
  and project_id not in (select project_id from f2a_project_summary)
  group by project_id, module_type_id, complexity_type_id
  union 
  select project_id, module_type_id, complexity_type_id, no_of_modules
  from f2a_project_summary;