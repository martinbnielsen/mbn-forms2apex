DECLARE
    l_workspace      apex_workspaces.workspace%TYPE        := 'MBNDATA';
    l_application_id apex_applications.application_id%TYPE := 135;
    l_workspace_id   apex_applications.workspace_id%TYPE;
  BEGIN
    SELECT workspace_id
    INTO l_workspace_id
    FROM apex_workspaces
    WHERE workspace = l_workspace;
    
    apex_util.set_security_group_id(p_security_group_id => l_workspace_id);

    APEX_APPLICATION_INSTALL.SET_WORKSPACE(l_workspace);
    apex_application_install.set_auto_install_sup_obj( p_auto_install_sup_obj => true );

    APEX_APPLICATION_INSTALL.SET_APPLICATION_ID(l_application_id);
    APEX_APPLICATION_INSTALL.GENERATE_OFFSET;
END;
/


@src/apex/f101_forms2apex.sql