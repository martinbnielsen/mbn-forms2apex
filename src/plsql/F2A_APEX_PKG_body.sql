create or replace PACKAGE BODY F2A_APEX_PKG AS

  C_NL CONSTANT VARCHAR2(1) := CHR(10);

  PROCEDURE add_line(p_clob IN OUT CLOB,
                     p_line IN VARCHAR2) IS
  BEGIN
   dbms_lob.append(p_clob, p_line || C_NL);
  END;

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

  FUNCTION create_lov_json(p_project_id in f2a_projects.id%TYPE) return CLOB AS
  BEGIN
    -- TODO: Implementation required for FUNCTION F2A_APEX_PKG.create_lov_json
    RETURN NULL;
  END create_lov_json;

  FUNCTION create_plsql(p_project_id in f2a_projects.id%TYPE) return CLOB AS
  BEGIN
    -- TODO: Implementation required for FUNCTION F2A_APEX_PKG.create_plsql
    RETURN NULL;
  END create_plsql;

END F2A_APEX_PKG;
/