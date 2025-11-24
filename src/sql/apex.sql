function create_shared_lov(
    p_app_id          in number           default g_app_id,
    p_lov_type        in varchar2,
    p_named_lov       in varchar2,
    p_dynamic_lov     in varchar2         default null,
    p_structured_lov  in t_structured_lov default null,
    p_static_lov_list in t_lov_list       default c_empty_t_lov_list ) return varchar2;


    grant execute on wwv_flow_create_app_v3 to forms2apex;
    create synonym wwv_flow_create_app_v3 for apex_210100.wwv_flow_create_app_v3;