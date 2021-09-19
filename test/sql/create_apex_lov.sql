    create synonym wwv_flow_create_app_v3 for apex_210100.wwv_flow_create_app_v3;
    
declare
   l_workspace_id      number;
 begin
     l_workspace_id := apex_util.find_security_group_id (p_workspace => 'MBNDATA');
     apex_util.set_security_group_id (p_security_group_id => l_workspace_id);
 end;
/

-- Good LOV
declare
  l_ret VARCHAR2(1000);
begin
    l_ret := wwv_flow_create_app_v3.create_shared_lov(
                        p_app_id          => 213,
                        p_lov_type        => 'DYNAMIC',
                        p_named_lov       => 'LOV12',
                        p_dynamic_lov     => 'Select name, id from s_product order by name');
   htp.p('ret:' || l_ret);
end;
/

-- Bad LOV -  wwv_flow_lov_dev.create_lov_from_query does not support queries that contain more than 2 columns.
declare
  l_ret VARCHAR2(1000);
begin
    l_ret := wwv_flow_create_app_v3.create_shared_lov(
                        p_app_id          => 213,
                        p_lov_type        => 'DYNAMIC',
                        p_named_lov       => 'LOV11',
                        p_dynamic_lov     => 'Select name, id, short_desc from s_product order by name');
   htp.p('ret:' || l_ret);
end;
/

-- Static LOV
declare
  l_ret VARCHAR2(1000);
  l_list wwv_flow_create_app_v3.t_lov_list;
  l_lov wwv_flow_create_app_v3.t_lov;
begin
    l_list := wwv_flow_create_app_v3.t_lov_list();
    --l_list.extend(2);
    l_lov.display_value := 'Yes';
    l_lov.return_value := 'Y';
    l_list(1) := l_lov;
    l_lov.display_value := 'No';
    l_lov.return_value := 'N';
    l_list(2) := l_lov;
    
    
    l_ret := wwv_flow_create_app_v3.create_shared_lov(
                        p_app_id          => 213,
                        p_lov_type        => 'STATIC',
                        p_named_lov       => 'LOV_STATIC',
                        p_static_lov_list => l_list);
   htp.p('ret:' || l_ret);
end;
/

select * from s_product;

type t_lov is record(
    display_value    varchar2(4000),
    return_value     varchar2(4000),
    template         varchar2(4000),
    disp_cond_type   varchar2(255),
    disp_cond        varchar2(4000),
    disp_cond2       varchar2(4000) );

type t_lov_list is table of t_lov index by binary_integer;


select * from APEX_APPLICATION_LOVS where application_id = 213;

select *
from apex_dictionary
where column_id = 0
and apex_view_name like '%&NAME%';
select * from apex_application;