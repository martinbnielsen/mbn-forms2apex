create or replace PACKAGE f2a_files_pkg AS

    FUNCTION format_logic(p_str IN VARCHAR2) Return VARCHAR2;
    
    FUNCTION blob_to_clob (
        blob_in IN BLOB
    ) RETURN CLOB;

    PROCEDURE process_single_file (
        p_project_id IN f2a_projects.id%TYPE,
        p_file_id   IN f2a_files.id%TYPE
    );

    PROCEDURE process_files (
        p_project_id   IN f2a_projects.id%TYPE
    );

END f2a_files_pkg;