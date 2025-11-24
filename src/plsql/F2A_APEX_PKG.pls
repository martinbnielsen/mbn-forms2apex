/*------------------------------------------------------------------------------
  Package Specification: F2A_APEX_PKG
  Description         : APEX generation utilities for Forms migration.
------------------------------------------------------------------------------*/
create or replace PACKAGE F2A_APEX_PKG AS 

  /*--------------------------------------------------------------------------
    Procedure: create_ui_defaults
    Purpose  : Synchronize APEX UI defaults based on migrated module metadata.
    @param  p_project_id IN f2a_projects.id%TYPE - project whose defaults sync.
  --------------------------------------------------------------------------*/
  PROCEDURE create_ui_defaults(p_project_id in f2a_projects.id%TYPE);

  /*--------------------------------------------------------------------------
    Function: create_lov_json
    Purpose : Build LOV metadata in JSON format for the given project.
    @param  p_project_id IN f2a_projects.id%TYPE - project context identifier.
    @return CLOB - JSON representation of LOV metadata.
  --------------------------------------------------------------------------*/
  FUNCTION create_lov_json(p_project_id in f2a_projects.id%TYPE) return CLOB;

  /*--------------------------------------------------------------------------
    Function: create_plsql
    Purpose : Generate PL/SQL source code for the migrated application.
    @param  p_project_id IN f2a_projects.id%TYPE - project context identifier.
    @return CLOB - generated PL/SQL source.
  --------------------------------------------------------------------------*/
  FUNCTION create_plsql(p_project_id in f2a_projects.id%TYPE) return CLOB;

END F2A_APEX_PKG;
/
