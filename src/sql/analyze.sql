declare
  v_count NUMBER;
begin
   select count(*)
   into v_count
   from user_scheduler_programs
   where program_name = 'F2A_PROCESS_FILE';

   if v_count > 0 THEN
        dbms_scheduler.drop_program
        (
        program_name=>'f2a_process_file'
        );
        end if;

    dbms_scheduler.create_program
    (
    program_name=>'f2a_process_file',
    program_action=>'f2a_files_pkg.process_single_file',
    program_type=>'STORED_PROCEDURE',
    number_of_arguments=>2, enabled=>FALSE
    ) ;
    
    dbms_scheduler.DEFINE_PROGRAM_ARGUMENT(
    program_name=>'f2a_process_file',
    argument_position=>1,
    argument_type=>'VARCHAR2',
    DEFAULT_VALUE=>NULL);
    
    dbms_scheduler.DEFINE_PROGRAM_ARGUMENT(
    program_name=>'f2a_process_file',
    argument_position=>2,
    argument_type=>'VARCHAR2',
    DEFAULT_VALUE=>NULL);   
    
    dbms_scheduler.enable('f2a_process_file');
end;
/

select *
from f2a_files
order by 1 desc;

select count(*) from f2a_files
where project_id = 42;

select * from f2a_files
where project_id = 42
and status_code != 'PROCESSED';

begin
  f2a_files_pkg.process_single_file(42, 67);
end;
/

begin
  for r in (select * from f2a_files
where project_id = 42
and status_code != 'PROCESSED') loop
f2a_files_pkg.process_single_file(42, r.id);
end loop;
end;
/

delete f2a_modules where project_id=42;
delete f2a_files where project_id=42;

select * from f2a_modules;

select count(*)
from f2a_modules where project_id=42;

select * from logger_logs_5_min order by 1 desc;

SELECT x.file_name, xt.*
                FROM   f2a_files x,
                       XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule/Trigger'
                         PASSING XMLTYPE(x.content)
                         COLUMNS 
                           name      VARCHAR2(1000)  PATH '@Name',
                           trigger_text     CLOB PATH '@TriggerText'
                             ) xt
                WHERE x.id = 67;
                
                alter table F2A_MODULES modify (title varchar2(500));
                

select m.*,
      (select count(*)
       from f2a_modules_v b
       where b.parent_id = m.id
       and b.module_type = 'BLOCK') no_of_blocks,
       (select count(*)
       from (select i.module_type
        from f2a_modules_v i
        start with i.parent_id = m.id
        connect by prior i.id = i.parent_id
        )
        where module_type = 'ITEM') no_of_items
from f2a_modules m
where project_id = :P0_PROJECT_ID
and parent_id is null;

select * from f2a_modules;

alter table f2a_modules add (blocks# number);
alter table f2a_modules add (items# number);
alter table f2a_modules add (triggers# number);
alter table f2a_modules add (program_units# number);
alter table f2a_modules add (trigger_lines# number);
alter table f2a_modules add (program_unit_lines# number);

update f2a_modules m
set blocks# =  (select count(*)
       from triggers(select i.module_type
        from f2a_modules_v i
        start with i.parent_id = m.id
        connect by prior i.id = i.parent_id
        )
        where module_type = 'BLOCK')
where project_id = 42
and parent_id is null;

update f2a_modules m
set items# =  (select count(*)
       from (select i.module_type
        from f2a_modules_v i
        start with i.parent_id = m.id
        connect by prior i.id = i.parent_id
        )
        where module_type = 'ITEM')
where project_id = 42
and parent_id is null;

update f2a_modules m
set triggers# =  (select count(*)
       from (select i.module_type
        from f2a_modules_v i
        start with i.parent_id = m.id
        connect by prior i.id = i.parent_id
        )
        where module_type = 'TRIGGER')
where project_id = 42
and parent_id is null;

update f2a_modules m
set program_units# =  (select count(*)
       from (select i.module_type
        from f2a_modules_v i
        start with i.parent_id = m.id
        connect by prior i.id = i.parent_id
        )
        where module_type = 'PROGRAM_UNIT')
where project_id = 42
and parent_id is null;

select * from f2a_module_types;

update f2a_modules m
set program_unit_lines# =  (select sum(lines)
       from (select i.module_type, length(regexp_replace(regexp_replace(i.content,'^.*$','1',1,0,'m'),'\s','')) lines
        from f2a_modules_v i
        start with i.parent_id = m.id
        connect by prior i.id = i.parent_id
        )
        where module_type = 'PROGRAM_UNIT')
where project_id = 42
and parent_id is null;

update f2a_modules m
set trigger_lines# =  (select sum(lines)
       from (select i.module_type, length(regexp_replace(regexp_replace(i.content,'^.*$','1',1,0,'m'),'\s','')) lines
        from f2a_modules_v i
        start with i.parent_id = m.id
        connect by prior i.id = i.parent_id
        )
        where module_type = 'TRIGGER')
where project_id = 42
and parent_id is null;

select length(regexp_replace(regexp_replace(content,'^.*$','1',1,0,'m'),'\s','')), m.* from f2a_modules_v m
where module_type = 'PROGRAM_UNIT'
and id = 696;


update f2a_modules m
set m.size_b = (select dbms_lob.getlength(f.content) from f2a_files f where f.id = m.file_id)
where project_id = :P0_PROJECT_ID
and parent_id is null;

select x.*,
      (select y.module_type from f2a_modules_v y where id = x.parent_id) parent_type,
      (select y.module_name from f2a_modules y where id = x.parent_id) parent_name
from (
  select *
  from f2a_modules_v m
  where project_id = 42
  start with parent_id is null
  connect by prior id = parent_id
) x
where x.module_type = 'TRIGGER'

