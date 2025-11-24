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
