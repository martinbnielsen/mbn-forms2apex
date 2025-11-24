/*------------------------------------------------------------------------------
  Package Specification: F2A_FILES_PKG
  Description         : File processing helpers for Forms to APEX migration.
------------------------------------------------------------------------------*/
create or replace PACKAGE f2a_files_pkg AS

    /*--------------------------------------------------------------------------
      Function: format_logic
      Purpose : Normalize encoded line breaks to native newlines.
      @param  p_str IN CLOB - encoded program logic content.
      @return CLOB - logic content with native newlines.
    --------------------------------------------------------------------------*/
    FUNCTION format_logic(p_str IN CLOB) return CLOB;

    /*--------------------------------------------------------------------------
      Function: format_html
      Purpose : Convert encoded line breaks to HTML line break tags.
      @param  p_str IN VARCHAR2 - encoded text to render in HTML.
      @return VARCHAR2 - text with `<br>` line breaks.
    --------------------------------------------------------------------------*/
    FUNCTION format_html(p_str IN VARCHAR2) return VARCHAR2;

    /*--------------------------------------------------------------------------
      Function: blob_to_clob
      Purpose : Convert a BLOB payload to a CLOB for text processing.
      @param  blob_in IN BLOB - binary payload to convert.
      @return CLOB - converted character payload.
    --------------------------------------------------------------------------*/
    FUNCTION blob_to_clob (
        blob_in IN BLOB
    ) RETURN CLOB;

    /*--------------------------------------------------------------------------
      Procedure: process_single_file
      Purpose  : Parse a single Forms XML file and populate module records.
      @param  p_project_id IN f2a_projects.id%TYPE - target project identifier.
      @param  p_file_id    IN f2a_files.id%TYPE   - file identifier to process.
    --------------------------------------------------------------------------*/
    PROCEDURE process_single_file (
        p_project_id IN f2a_projects.id%TYPE,
        p_file_id   IN f2a_files.id%TYPE
    );

    /*--------------------------------------------------------------------------
      Procedure: process_files
      Purpose  : Parse all Forms files for a project and load module metadata.
      @param  p_project_id IN f2a_projects.id%TYPE - target project identifier.
    --------------------------------------------------------------------------*/
    PROCEDURE process_files (
        p_project_id   IN f2a_projects.id%TYPE
    );

END f2a_files_pkg;
/
