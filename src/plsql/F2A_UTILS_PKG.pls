/*------------------------------------------------------------------------------
  Package Specification: F2A_UTILS_PKG
  Description         : Utility helpers for Forms to APEX migration.
------------------------------------------------------------------------------*/
CREATE OR REPLACE 
PACKAGE F2A_UTILS_PKG AS 

  /*--------------------------------------------------------------------------
    Function: get_mapping
    Purpose : Retrieve mapped value for a given mapping type and source value.
    @param  p_mapping_type IN f2a_mapping_types.mapping_type%type - mapping type.
    @param  p_from_value   IN f2a_mapping_types.from_value%type   - source value.
    @return f2a_mapping_types.to_value%type - mapped target value.
  --------------------------------------------------------------------------*/
  function get_mapping(p_mapping_type in f2a_mapping_types.mapping_type%type,
                       p_from_value in f2a_mapping_types.from_value%type) return f2a_mapping_types.to_value%type;
  
  /*--------------------------------------------------------------------------
    Function: get_module_type_id
    Purpose : Resolve module type identifiers by module type code.
    @param  p_module_type IN f2a_module_types.module_type%TYPE - module type code.
    @return f2a_module_types.module_type_id%TYPE - corresponding identifier.
  --------------------------------------------------------------------------*/
  function get_module_type_id (p_module_type in f2a_module_types.module_type%TYPE) return f2a_module_types.module_type_id%TYPE;


END F2A_UTILS_PKG;
/
