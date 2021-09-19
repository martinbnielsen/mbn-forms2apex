alter table f2a_modules add (description varchar2(200), usage_count number, 
last_used_date date, size_b number, example_flag varchar2(1), complexity_type_id number, estimate_h number);

alter table f2a_modules add constraint f2a_modules_fk1 foreign key (complexity_type_id) references f2a_complexity_types;
alter table f2a_modules drop (description);

create index f2a_modules_fk1_i on f2a_modules (complexity_type_id);

select *
from f2a_projects;

select * from f2a_modules
where module_type_id = 6;

select *
from f2a_module_types;

insert into f2a_modules (
  project_id,
  module_type_id,
  module_name,
  title,
  usage_count,
  last_used_date,
  size_b,
  example_flag,
  complexity_type_id,
  estimate_h,
  migrate_flag)
select
    41 project_id,
    6 module_type_id,
    a.navn,
    a.betegnelse_lang,
    a.antal_anvendelser,
    a.senest_anvendt,
    a.size_b,
    decode(a.eksempel,'J','Y') example_flag,
    ct.id,
    a.estimat_d * 7,
    'Y' migrate_flag
from
    ase_aks_moduler a
left join f2a_complexity_types ct on substr(ct.complexity_type,1,1) = a.kompleksitet;