/*------------------------------------------------------------------------------
  Package Body: F2A_APEX_PKG
  Description : Implements APEX generation utilities for Forms migration.
------------------------------------------------------------------------------*/
create or replace PACKAGE BODY F2A_APEX_PKG AS

  C_NL CONSTANT VARCHAR2(1) := CHR(10);

  /*----------------------------------------------------------------------------
    Procedure: add_line
    Purpose  : Append a line and newline delimiter to a target CLOB buffer.
    @param  p_clob IN OUT CLOB - target buffer to append to.
    @param  p_line IN VARCHAR2 - line content to append.
  ----------------------------------------------------------------------------*/
  PROCEDURE add_line(p_clob IN OUT CLOB,
                     p_line IN VARCHAR2) IS
  BEGIN
   dbms_lob.append(p_clob, p_line || C_NL);
  END;

  /*----------------------------------------------------------------------------
    Procedure: create_ui_defaults
    Purpose  : Synchronize APEX UI defaults based on migrated module metadata.
    @param  p_project_id IN f2a_projects.id%TYPE - project whose defaults sync.
  ----------------------------------------------------------------------------*/
  PROCEDURE create_ui_defaults(p_project_id in f2a_projects.id%TYPE) AS
  BEGIN

    -- Sync each used table
    FOR b in (select id, content
              from f2a_modules_v
              where project_id = p_project_id
              and module_type = 'BLOCK'
              and content is not null
              and migrate_flag = 'Y'
              order by 1) LOOP

       apex_ui_default_update.synch_table(p_table_name =>  b.content);
       
       FOR i IN (SELECT m.*
                 FROM f2a_modules_v m
                 WHERE m.parent_id = b.id
                 AND m.module_type = 'ITEM'
                 and migrate_flag = 'Y'
                 AND m.database_item IS NOT NULL) LOOP

        apex_ui_default_update.upd_column (
          p_table_name  => b.content,
          p_column_name => i.module_name,
          p_label       => i.item_label,
          p_required    => f2a_utils_pkg.get_mapping('BOOLEAN', i.required_flag),
          p_display_width => i.item_length,
          p_help_text => i.help_text,
          p_max_width => i.item_length,
          p_default_value => f2a_utils_pkg.get_mapping('DEFAULT_VALUE', i.initializevalue),
          p_mask_form => i.formatmask);

       END LOOP;

    END LOOP;

  END create_ui_defaults;

  /*----------------------------------------------------------------------------
    Function: create_lov_json
    Purpose : Build LOV metadata in JSON format for the given project.
    @param  p_project_id IN f2a_projects.id%TYPE - project context identifier.
    @return CLOB - JSON representation of LOV metadata.
  ----------------------------------------------------------------------------*/
  FUNCTION create_lov_json(p_project_id in f2a_projects.id%TYPE) return CLOB AS
  BEGIN
    -- TODO: Implementation required for FUNCTION F2A_APEX_PKG.create_lov_json
    RETURN NULL;
  END create_lov_json;

  /*----------------------------------------------------------------------------
    Function: create_plsql
    Purpose : Generate PL/SQL source code for the migrated application.
    @param  p_project_id IN f2a_projects.id%TYPE - project context identifier.
    @return CLOB - generated PL/SQL source.
  ----------------------------------------------------------------------------*/
  FUNCTION create_plsql(p_project_id in f2a_projects.id%TYPE) return CLOB AS
  BEGIN
    -- TODO: Implementation required for FUNCTION F2A_APEX_PKG.create_plsql
    RETURN NULL;
  END create_plsql;

END F2A_APEX_PKG;
/
