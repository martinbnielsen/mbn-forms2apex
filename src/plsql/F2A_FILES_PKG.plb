/*------------------------------------------------------------------------------
  Package Body: F2A_FILES_PKG
  Description : Implements file processing helpers for Forms to APEX migration.
------------------------------------------------------------------------------*/
create or replace PACKAGE BODY f2a_files_pkg AS

  /*----------------------------------------------------------------------------
    Function: CLOB_REPLACE
    Purpose : Replace all occurrences of a pattern in a CLOB, supporting large
              substitution payloads.
    @param  AINPUT IN CLOB        - source CLOB to update.
    @param  APATTERN IN VARCHAR2  - text to find.
    @param  ASUBSTITUTE IN CLOB   - replacement content.
    @return CLOB - updated CLOB content.
  ----------------------------------------------------------------------------*/
  function CLOB_REPLACE(
    AINPUT      CLOB,
    APATTERN    VARCHAR2,
    ASUBSTITUTE CLOB
  ) return CLOB is
  FCLOB   CLOB := AINPUT;
  FOFFSET INTEGER;
  FCHUNK  CLOB;
  begin
    if length(ASUBSTITUTE) > 32000 then
      FOFFSET := 1;
      FCLOB := replace(FCLOB, APATTERN, '###CLOBREPLACE###');
      while FOFFSET <= length(ASUBSTITUTE) loop
        FCHUNK := substr(ASUBSTITUTE, FOFFSET, 32000) || '###CLOBREPLACE###';
        FCLOB := regexp_replace(FCLOB, '###CLOBREPLACE###', FCHUNK);
        FOFFSET := FOFFSET + 32000;
      end loop;
      FCLOB := regexp_replace(FCLOB, '###CLOBREPLACE###', '');
    else 
      FCLOB := replace(FCLOB, APATTERN, ASUBSTITUTE);
    end if;
    return FCLOB;
  end;

    /*--------------------------------------------------------------------------
      Function: format_logic
      Purpose : Normalize encoded logic line breaks to native newlines.
      @param  p_str IN CLOB - encoded program logic content.
      @return CLOB - logic content with native newlines.
    --------------------------------------------------------------------------*/
    FUNCTION format_logic(p_str IN CLOB) return CLOB IS
    BEGIN
      return(
        clob_replace(p_str, '&#10;', chr(10))
        );
    END;
    
    /*--------------------------------------------------------------------------
      Function: format_html
      Purpose : Convert encoded line breaks to HTML line break tags.
      @param  p_str IN VARCHAR2 - encoded text to render in HTML.
      @return VARCHAR2 - text with `<br>` line breaks.
    --------------------------------------------------------------------------*/
    FUNCTION format_html(p_str IN VARCHAR2) return VARCHAR2 IS
    BEGIN
      return(replace(p_str, '&#10;', '<br>'));
    END;

    /*--------------------------------------------------------------------------
      Function: blob_to_clob
      Purpose : Convert a BLOB payload to a CLOB for downstream processing.
      @param  blob_in IN BLOB - binary payload to convert.
      @return CLOB - converted character payload.
    --------------------------------------------------------------------------*/
    FUNCTION blob_to_clob (
        blob_in IN BLOB
    ) RETURN CLOB IS

        v_clob      CLOB;
        v_varchar   VARCHAR2(32767);
        v_start     PLS_INTEGER := 1;
        v_buffer    PLS_INTEGER := 32767;
    BEGIN
        dbms_lob.createtemporary(v_clob,true);
        FOR i IN 1..ceil(dbms_lob.getlength(blob_in) / v_buffer) LOOP
            v_varchar := utl_raw.cast_to_varchar2(dbms_lob.substr(blob_in,v_buffer,v_start) );

            dbms_lob.writeappend(v_clob,length(v_varchar),v_varchar);
            v_start := v_start + v_buffer;
        END LOOP;

        RETURN v_clob;
    END blob_to_clob;

    /*--------------------------------------------------------------------------
      Procedure: process_single_file
      Purpose  : Parse a specific Forms XML file and persist module metadata.
      @param  p_project_id IN f2a_projects.id%TYPE - target project identifier.
      @param  p_file_id    IN f2a_files.id%TYPE   - file identifier to process.
    --------------------------------------------------------------------------*/
    PROCEDURE process_single_file (
        p_project_id IN f2a_projects.id%TYPE,
        p_file_id    IN f2a_files.id%TYPE
    )
        IS
      l_module_id f2a_modules.id%TYPE;
      l_block_id  f2a_modules.id%TYPE;
      l_item_id   f2a_modules.id%TYPE;
    BEGIN
      -- Todo: handle upload of the same file

      -- For each module
      FOR m IN (SELECT x.file_name, dbms_lob.getlength(x.content) size_b, xt.*
          FROM   f2a_files x,
                 XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module'
                   PASSING XMLTYPE(x.content)
                   COLUMNS 
                     version      VARCHAR2(100)  PATH '@version'
                       ) xt
          WHERE x.id = p_file_id) LOOP

          -- FORM
          FOR f IN (
              SELECT x.file_name, xt.*
              FROM   f2a_files x,
                     XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule'
                       PASSING XMLTYPE(x.content)
                       COLUMNS 
                         name      VARCHAR2(100)  PATH '@Name',
                         title     VARCHAR2(1000) PATH '@Title'
                           ) xt
              WHERE x.id = p_file_id) LOOP

            insert into f2a_modules (module_type_id, module_name, file_id, project_id, title, version_no, size_b)
            values (f2a_utils_pkg.get_module_type_id('FORM'), f.name, p_file_id, p_project_id, f.title, m.version, m.size_b)
            returning id into l_module_id;

            -- Form Level triggers
            FOR t IN (
                SELECT x.file_name, xt.*
                FROM   f2a_files x,
                       XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule/Trigger'
                         PASSING XMLTYPE(x.content)
                         COLUMNS 
                           name      VARCHAR2(1000)  PATH '@Name',
                           trigger_text  CLOB PATH '@TriggerText'
                             ) xt
                WHERE x.id = p_file_id) LOOP

                insert into f2a_modules (module_type_id, module_name, file_id, project_id, content, parent_id)
                values (f2a_utils_pkg.get_module_type_id('TRIGGER'), t.name, p_file_id, p_project_id, format_logic(t.trigger_text), l_module_id);
            END LOOP;

            -- LOVS
            FOR l IN (
                SELECT x.file_name, xt.*
                FROM   f2a_files x,
                       XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule/RecordGroup'
                         PASSING XMLTYPE(x.content)
                         COLUMNS 
                           name      VARCHAR2(100)  PATH '@Name',
                           query     VARCHAR2(1000) PATH '@RecordGroupQuery'
                             ) xt
                WHERE x.id = p_file_id) LOOP

                insert into f2a_modules (module_type_id, module_name, file_id, project_id, content, parent_id)
                values (f2a_utils_pkg.get_module_type_id('LOV'), l.name, p_file_id, p_project_id, l.query, l_module_id);
            END LOOP;

            -- BLOCKS
            FOR b IN (
                SELECT x.file_name, xt.*
                FROM   f2a_files x,
                       XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule/Block'
                         PASSING XMLTYPE(x.content)
                         COLUMNS 
                           name       VARCHAR2(100) PATH '@Name',
                           datasource VARCHAR2(100) PATH '@QueryDataSourceName',
                           block      XMLTYPE PATH '*'
                             ) xt
                WHERE x.id = p_file_id) LOOP

                insert into f2a_modules (module_type_id, module_name, file_id, project_id, content, parent_id)
                values (f2a_utils_pkg.get_module_type_id('BLOCK'), b.name, p_file_id, p_project_id, b.datasource, l_module_id)
                returning id into l_block_id;

                -- Block level triggers
                FOR t IN (
                    SELECT xt.*
                    FROM dual x,
                           XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Trigger'
                             PASSING b.block
                             COLUMNS 
                               name             VARCHAR2(1000) PATH '@Name',
                               trigger_text     clob PATH '@TriggerText'
                                 ) xt) LOOP

                    insert into f2a_modules (project_id, module_type_id, module_name, content, parent_id)
                    values (p_project_id, f2a_utils_pkg.get_module_type_id('TRIGGER'), t.name, format_logic(t.trigger_text), l_block_id)
                    returning id into l_item_id;

                END LOOP;

                -- Items
                FOR i IN (
                    SELECT xt.*
                    FROM dual x,
                           XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Item'
                             PASSING b.block
                             COLUMNS 
                               name        VARCHAR2(100) PATH '@Name',
                               prompt      VARCHAR2(100) PATH '@Prompt',
                               label       VARCHAR2(100) PATH '@Label',
                               column_name VARCHAR2(100) PATH '@ColumnName',
                               item_type   VARCHAR2(100) PATH '@ItemType',
                               data_type   VARCHAR2(100) PATH '@DataType',
                               Required_flag VARCHAR2(20) PATH '@Required',
                               tooltip     VARCHAR2(4000) PATH '@Tooltip',
                               formula     VARCHAR2(4000) PATH '@Formula',
                               MaximumLength NUMBER PATH '@MaximumLength',
                               InitializeValue VARCHAR2(500) PATH '@InitializeValue',
                               FormatMask VARCHAR2(100) PATH '@FormatMask',
                               item             XMLTYPE PATH '*'
                                 ) xt) LOOP

                    insert into f2a_modules (project_id, module_type_id, content_type, module_name, item_label, parent_id, data_type, required_flag, help_text, item_length, database_item, content, InitializeValue, FormatMask)
                    values (p_project_id, f2a_utils_pkg.get_module_type_id('ITEM'), i.item_type, i.name, format_html(NVL(i.prompt, i.label)), l_block_id, i.data_type, i.required_flag, i.tooltip, i.MaximumLength, i.column_name, i.formula, i.InitializeValue, i.FormatMask)
                    returning id into l_item_id;

                    -- Item level triggers
                    FOR t IN (
                        SELECT xt.*
                        FROM dual x,
                               XMLTABLE('declare default element namespace \"http://xmlns.oracle.com/Forms\"; /Item'
                                 PASSING i.item
                                 COLUMNS 
                                   name         VARCHAR2(100) PATH '@Name',
                                   trigger_text VARCHAR2(100) PATH '@TriggerText'
                                     ) xt) LOOP

                        insert into f2a_modules (project_id, module_type_id, module_name, item_label, parent_id)
                        values (p_project_id, f2a_utils_pkg.get_module_type_id('TRIGGER'), t.name, format_logic(t.trigger_text), l_item_id);

                    END LOOP;

                END LOOP;

                -- Datasources - connecting the item to the tabel columns
                -- <DataSourceColumn Type="Query" DSCType="NUMBER" DSCLength="0" DSCPrecision="7" DSCName="PRODUCT_ID" DSCScale="0" DSCMandatory="true"/>
                FOR ds IN (
                    SELECT xt.*
                    FROM dual x,
                           XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /DataSourceColumn'
                             PASSING b.block
                             COLUMNS 
                               data_source_type       VARCHAR2(100) PATH '@Type',
                               DSCName                VARCHAR2(100) PATH '@DSCName'
                                 ) xt) LOOP

                    IF ds.data_source_type = 'Query' THEN
                      update f2a_modules_v 
                      set database_item = ds.DSCName
                     where parent_id = l_block_id
                     and module_type = 'ITEM'
                     and module_name = ds.DSCName;
                    END IF;
                END LOOP;
                
                
            END LOOP; -- Blocks

            -- Program units
            FOR p IN (
                SELECT x.file_name, xt.*
                FROM   f2a_files x,
                       XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule/ProgramUnit'
                         PASSING XMLTYPE(x.content)
                         COLUMNS 
                           name                 VARCHAR2(100)   PATH '@Name',
                           program_unit_type    VARCHAR2(1000)  PATH '@ProgramUnitType',
                           Program_Unit_Text    CLOB PATH '@ProgramUnitText'
                             ) xt
                WHERE x.id = p_file_id) LOOP

                insert into f2a_modules (module_type_id, module_name, content_type, file_id, project_id, content, parent_id)
                values (f2a_utils_pkg.get_module_type_id('PROGRAM_UNIT'), p.name, p.program_unit_type, p_file_id, p_project_id, format_logic(p.Program_Unit_Text), l_module_id);
            END LOOP;

        END LOOP; -- Forms

      END LOOP; -- Modules

      logger.log('processing file ' || p_file_id);
      UPDATE f2a_files
      SET
          status_code = 'PROCESSED'
      WHERE id = p_file_id;

    EXCEPTION
      WHEN OTHERS THEN
        logger.log_error(SQLERRM);
        UPDATE f2a_files
        SET
          status_code = 'ERROR'
        WHERE id = p_file_id;

        RAISE;
    END;

    /*--------------------------------------------------------------------------
      Procedure: process_files
      Purpose  : Process all files uploaded via DROPZONE_UPLOAD and queue
                 background parsing jobs.
      @param  p_project_id IN f2a_projects.id%TYPE - target project identifier.
    --------------------------------------------------------------------------*/
    PROCEDURE process_files (
        p_project_id   IN f2a_projects.id%TYPE
    ) AS
        l_job_id    VARCHAR2(1000);
        l_file_id   f2a_files.id%TYPE;
    BEGIN
        -- TODO: Implementation required for procedure F2A_FILES_PKG.process_files

        -- Store the new file
        FOR f IN ( SELECT *
                   FROM apex_collections
                   WHERE collection_name = 'DROPZONE_UPLOAD'
        ) LOOP

            -- TODO: better handling of filename overlap
            DELETE f2a_files
            WHERE project_id = p_project_id
                  AND file_name = f.c001;

            INSERT INTO f2a_files (
                file_name,
                content_type,
                status_code,
                file_type,
                content,
                project_id
            ) VALUES (
                f.c001,
                f.c002,
                'INSERTED',
                NULL,
                blob_to_clob(f.blob001),
                p_project_id
            ) RETURNING id INTO l_file_id;

            COMMIT;
            l_job_id := 'f2a_process_file_' || f2a_job_s.nextval;
            dbms_scheduler.create_job(l_job_id,program_name => 'f2a_process_file');
            dbms_scheduler.set_job_argument_value(l_job_id,1,TO_CHAR(p_project_id) );
            dbms_scheduler.set_job_argument_value(l_job_id,2,TO_CHAR(l_file_id) );
            dbms_scheduler.enable(l_job_id);
            COMMIT;
        END LOOP;

        -- Remove the files in the collection

        apex_collection.truncate_collection('DROPZONE_UPLOAD');
    END process_files;

    /*--------------------------------------------------------------------------
      Procedure: set_module_stats
      Purpose  : Refresh summary statistics for modules within a project.
      @param  p_project_id IN f2a_projects.id%TYPE - project whose stats refresh.
    --------------------------------------------------------------------------*/
  procedure set_module_stats (p_project_id in f2a_projects.id%type) is
  begin

    update f2a_modules m
    set blocks# =  (select count(*)
          from (select i.module_type
            from f2a_modules_v i
            start with i.parent_id = m.id
            connect by prior i.id = i.parent_id
            )
            where module_type = 'BLOCK')
    where project_id = p_project_id
    and parent_id is null;

    update f2a_modules m
    set items# =  (select count(*)
          from (select i.module_type
            from f2a_modules_v i
            start with i.parent_id = m.id
            connect by prior i.id = i.parent_id
            )
            where module_type = 'ITEM')
    where project_id = p_project_id
    and parent_id is null;

    update f2a_modules m
    set triggers# =  (select count(*)
          from (select i.module_type
            from f2a_modules_v i
            start with i.parent_id = m.id
            connect by prior i.id = i.parent_id
            )
            where module_type = 'TRIGGER')
    where project_id = p_project_id
    and parent_id is null;

    update f2a_modules m
    set program_units# =  (select count(*)
          from (select i.module_type
            from f2a_modules_v i
            start with i.parent_id = m.id
            connect by prior i.id = i.parent_id
            )
            where module_type = 'PROGRAM_UNIT')
    where project_id = p_project_id
    and parent_id is null;

    update f2a_modules m
    set program_unit_lines# =  (select sum(lines)
          from (select i.module_type, length(regexp_replace(regexp_replace(i.content,'^.*$','1',1,0,'m'),'\s','')) lines
            from f2a_modules_v i
            start with i.parent_id = m.id
            connect by prior i.id = i.parent_id
            )
            where module_type = 'PROGRAM_UNIT')
    where project_id = p_project_id
    and parent_id is null;

    update f2a_modules m
    set trigger_lines# =  (select sum(lines)
          from (select i.module_type, length(regexp_replace(regexp_replace(i.content,'^.*$','1',1,0,'m'),'\s','')) lines
            from f2a_modules_v i
            start with i.parent_id = m.id
            connect by prior i.id = i.parent_id
            )
            where module_type = 'TRIGGER')
    where project_id = p_project_id
    and parent_id is null;    
  end;

END f2a_files_pkg;
/
