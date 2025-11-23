CREATE OR REPLACE 
PACKAGE F2A_UTILS_PKG AS 

  function get_mapping(p_mapping_type in f2a_mapping_types.mapping_type%type,
                       p_from_value in f2a_mapping_types.from_value%type) return f2a_mapping_types.to_value%type;
  
  function get_module_type_id (p_module_type in f2a_module_types.module_type%TYPE) return f2a_module_types.module_type_id%TYPE;


END F2A_UTILS_PKG;
/