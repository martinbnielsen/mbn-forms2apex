create or replace view f2a_modules_v as
select mt.module_type, ct.complexity_type, m.*
from f2a_modules m
join f2a_module_types mt on mt.module_type_id = m.module_type_id
left join f2a_complexity_types ct on ct.id = m.complexity_type_id;