select m.module_name, i.item_name, i.item_label, i.item_length
from f2a_modules m
join f2a_module_items i on i.module_id = m.id
where m.module_type = 'BLOCK'
and m.module_name like 'S_%';

DECLARE
  l_workspace_id NUMBER;
BEGIN
    l_workspace_id := apex_util.find_security_group_id (p_workspace => 'FORMS2APEX');
    apex_util.set_security_group_id (p_security_group_id => l_workspace_id);

    APEX_UI_DEFAULT_UPDATE.SYNCH_TABLE (
        p_table_name            => 'S_ORD');
    
    APEX_UI_DEFAULT_UPDATE.UPD_TABLE (
        p_table_name            => 'S_ORD',
        p_form_region_title     => 'Order form',
        p_report_region_title   => 'Orders');

    APEX_UI_DEFAULT_UPDATE.UPD_COLUMN (
        p_table_name            => 'S_ORD',
        p_column_name           => 'CUSTOMER_NAME',
        p_label                 => 'Kunde navn',
        p_display_width         => 30);
        
    COMMIT;
END;
/