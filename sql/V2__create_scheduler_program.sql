begin
    dbms_scheduler.create_program
    (
    program_name=>'f2a_process_file',
    program_action=>'f2a_files_pkg.process_file',
    program_type=>'STORED_PROCEDURE',
    number_of_arguments=>1, enabled=>FALSE
    ) ;
    
    dbms_scheduler.DEFINE_PROGRAM_ARGUMENT(
    program_name=>'f2a_process_file',
    argument_position=>1,
    argument_type=>'VARCHAR2',
    DEFAULT_VALUE=>NULL);
    
    
    dbms_scheduler.enable('f2a_process_file');
end;
/
