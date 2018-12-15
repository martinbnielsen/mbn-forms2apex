select payload, devops_utils.blob_to_xml(payload)
from stage_ekapital_eindkomst.ei_package;

SELECT X.* 
FROM stage_ekapital_eindkomst.ei_package, 
XMLTABLE ('$d/*:IndkomstOplysningKlassiskAbonnentHent_O_O/*:IndkomstOplysningKlassiskAbonnentUddata/*:IndkomstOplysningVirksomhedSamling/*:IndkomstOplysningVirksomhed/*:IndberetningPligtigVirksomhedStruktur' passing devops_utils.blob_to_xml(payload) as "d" 
   COLUMNS 
    VirksomhedSENummer    VARCHAR(20)     PATH '*:IndberetningPligtigVirksomhed/*:VirksomhedSENummer'
) AS X;

SELECT X.* 
FROM stage_ekapital_eindkomst.ei_package, 
XMLTABLE ('$d/*:IndkomstOplysningKlassiskAbonnentHent_O_O/*:Kontekst/*:HovedOplysningerSvar' passing devops_utils.blob_to_xml(payload) as "d" 
   COLUMNS 
    TransaktionsID    VARCHAR(100)     PATH '*:TransaktionsID'
) AS X;

select file_name, xmltype(content) from f2a_files;

SELECT f.file_name, X.* 
FROM f2a_files f,
XMLTABLE (xmlnamespaces(default 'http://xmlns.oracle.com/Forms'),
          '$d//Module' passing xmltype(f.content) as "d" 
   COLUMNS 
    version VARCHAR2(100)    PATH '@version',
    name    VARCHAR(100)     PATH './FormModule/@Name'
) AS X;

select file_name, extractvalue (xmltype(content), '/*:Module@*:version')
from f2a_files;

SELECT X.* 
FROM f2a_files f, 
XMLTABLE ('$d/Module' passing xmltype(f.content) as "d" 
   COLUMNS 
   the_version    INTEGER     PATH '@version',
) AS X;

SELECT f.file_name, xmltype(f.content).extract('//Module/@version', 'http://xmlns.oracle.com/Forms').getStringVal()
FROM f2a_files f;

select x.col1.extract('//car/@model').getStringVal() ;

select payload, devops_utils.blob_to_xml(payload)
from stage_ekapital_eindkomst.ei_package;