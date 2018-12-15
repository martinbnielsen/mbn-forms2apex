
SELECT x.file_name, xt.*
            FROM   f2a_files x,
                   XMLTABLE('declare default element namespace "http://xmlns.oracle.com/Forms"; /Module'
                     PASSING XMLTYPE(x.content)
                     COLUMNS 
                       version      VARCHAR2(100)  PATH '@version'
                         ) xt
            WHERE x.id = 153921334134762799300825704146261389094  ;
            

alter table f2a_modules add (version_no varchar2(20));

delete f2a_modules;

select * from f2a_projects;

DECLARE
  P_PROJECT_ID NUMBER;
  P_FILE_ID NUMBER;
BEGIN
  P_PROJECT_ID := 153921334134757963597547245629562564390;
  P_FILE_ID := 153921334134762799300825704146261389094;

delete f2a_modules;

  F2A_FILES_PKG.PROCESS_SINGLE_FILE(
    P_PROJECT_ID => P_PROJECT_ID,
    P_FILE_ID => P_FILE_ID
  );
--rollback; 
END;
/

select *
from logger_logs_5_min 
order by 1 desc;


select extra from logger_logs where id = 76;
SELECT xt.*
FROM logger_logs x,
       XMLTABLE('/Item'
         PASSING xmltype(x.extra)
         COLUMNS 
           name       VARCHAR2(100) PATH '@Name',
           prompt     VARCHAR2(100) PATH '@Prompt'
             ) xt
     where x.id = 76;        