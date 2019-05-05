create or replace PACKAGE BODY f2a_files_pkg AS

    -- Format proigram logic
    FUNCTION format_logic(p_str IN VARCHAR2) Return VARCHAR2 IS
    BEGIN
      Return(
        replace(p_str, '&#10;', chr(10))
        );
    END;
    
    -- Convert BLOB to CLOB
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

    -- Process a single file

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
      FOR m IN (SELECT x.file_name, xt.*
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
              
            insert into f2a_modules (module_type, module_name, file_id, project_id, title, version_no)
            values ('FORM', f.name, p_file_id, p_project_id, f.title, m.version)
            returning id into l_module_id;
        
            -- Form Level triggers
            FOR t IN (
                SELECT x.file_name, xt.*
                FROM   f2a_files x,
                       XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule/Trigger'
                         PASSING XMLTYPE(x.content)
                         COLUMNS 
                           name      VARCHAR2(100)  PATH '@Name',
                           trigger_text     VARCHAR2(1000) PATH '@TriggerText'
                             ) xt
                WHERE x.id = p_file_id) LOOP
                
                insert into f2a_modules (module_type, module_name, file_id, project_id, content, parent_id)
                values ('TRIGGER', t.name, p_file_id, p_project_id, format_logic(t.trigger_text), l_module_id);
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
                
                insert into f2a_modules (module_type, module_name, file_id, project_id, content, parent_id)
                values ('LOV', l.name, p_file_id, p_project_id, l.query, l_module_id);
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
                
                insert into f2a_modules (module_type, module_name, file_id, project_id, content, parent_id)
                values ('BLOCK', b.name, p_file_id, p_project_id, b.datasource, l_module_id)
                returning id into l_block_id;
                
                -- Block level triggers
                FOR t IN (
                    SELECT xt.*
                    FROM dual x,
                           XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Trigger'
                             PASSING b.block
                             COLUMNS 
                               name             VARCHAR2(100) PATH '@Name',
                               trigger_text     VARCHAR2(100) PATH '@TriggerText'
                                 ) xt) LOOP
                    
                    insert into f2a_modules (project_id, module_type, module_name, item_label, parent_id)
                    values (p_project_id, 'TRIGGER', t.name, format_logic(t.trigger_text), l_block_id)
                    returning id into l_item_id;
                    
                END LOOP;
                
                -- Items
                FOR i IN (
                    SELECT xt.*
                    FROM dual x,
                           XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Item'
                             PASSING b.block
                             COLUMNS 
                               name       VARCHAR2(100) PATH '@Name',
                               prompt     VARCHAR2(100) PATH '@Prompt',
                               item             XMLTYPE PATH '*'
                                 ) xt) LOOP
                    
                    insert into f2a_modules (project_id, module_type, content_type, module_name, item_label, parent_id)
                    values (p_project_id, 'ITEM', 'ITEM', i.name, i.prompt, l_block_id)
                    returning id into l_item_id;
                    
                    -- Item level triggers
                    FOR t IN (
                        SELECT xt.*
                        FROM dual x,
                               XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Item'
                                 PASSING i.item
                                 COLUMNS 
                                   name         VARCHAR2(100) PATH '@Name',
                                   trigger_text VARCHAR2(100) PATH '@TriggerText'
                                     ) xt) LOOP
                        
                        insert into f2a_modules (project_id, module_type, module_name, item_label, parent_id)
                        values (p_project_id, 'TRIGGER', t.name, format_logic(t.trigger_text), l_item_id);
                                     
                    END LOOP;
                    
                END LOOP;
            
                logger.log('block', p_extra => b.block.getClobVal());
            END LOOP;
            
            -- Program units
            FOR p IN (
                SELECT x.file_name, xt.*
                FROM   f2a_files x,
                       XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module/FormModule/ProgramUnit'
                         PASSING XMLTYPE(x.content)
                         COLUMNS 
                           name                 VARCHAR2(100)   PATH '@Name',
                           program_unit_type    VARCHAR2(1000)  PATH '@ProgramUnitType',
                           Program_Unit_Text    VARCHAR2(4000) PATH '@ProgramUnitText'
                             ) xt
                WHERE x.id = p_file_id) LOOP
                
                insert into f2a_modules (module_type, module_name, content_type, file_id, project_id, content, parent_id)
                values ('PROGRAM_UNIT', p.name, p.program_unit_type, p_file_id, p_project_id, format_logic(p.Program_Unit_Text), l_module_id);
            END LOOP;
            
        END LOOP; -- Forms
      
      END LOOP; -- Modules

      logger.log('processing file ' || p_file_id);
      UPDATE f2a_files
      SET
          status_code = 'PROCESSED'
      WHERE id = p_file_id;

    END;
    
  -- Process all files uploaded to the dropzone collection
  -- DROPZONE_UPLOAD, c001 = filename, c002 = content-type, n001 = size, 

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

END f2a_files_pkg;
/