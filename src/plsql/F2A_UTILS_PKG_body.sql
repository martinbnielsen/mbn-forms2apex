create or replace PACKAGE F2A_APEX_PKG AS 

  PROCEDURE create_ui_defaults(p_project_id in f2a_projects.id%TYPE);

  FUNCTION create_lov_json(p_project_id in f2a_projects.id%TYPE) return CLOB;
  
  FUNCTION create_plsql(p_project_id in f2a_projects.id%TYPE) return CLOB;

END F2A_APEX_PKG;
/