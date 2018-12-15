-- drop objects
drop table f2a_projects cascade constraints;
drop table f2a_imports cascade constraints;
drop procedure f2a_tags_sync;
drop table f2a_tags cascade constraints;
drop table f2a_tags_tsum cascade constraints;
drop table f2a_tags_sum cascade constraints;

-- create tables
create table f2a_projects (
    id                             number not null constraint f2a_projects_id_pk primary key,
    security_group_id              number not null,
    name                           varchar2(255) not null,
    description                    varchar2(4000),
    start_date                     date,
    deadline_date                  date,
    created                        date not null,
    created_by                     varchar2(255) not null,
    updated                        date not null,
    updated_by                     varchar2(255) not null
)
;

create table f2a_imports (
    id                             number not null constraint f2a_imports_id_pk primary key,
    project_id                     number
                                   constraint f2a_imports_project_id_fk
                                   references f2a_projects on delete cascade,
    security_group_id              number not null,
    file_type                      varchar2(4000),
    mime_type                      varchar2(300),
    filename                       varchar2(500) not null,
    content                        clob,
    created                        date not null,
    created_by                     varchar2(255) not null,
    updated                        date not null,
    updated_by                     varchar2(255) not null
)
;


-- tag framework
create table f2a_tags (
    id                    number not null primary key,
    tag                   varchar2(255) not null enable,
    content_pk            number,
    content_table         varchar2(128),
    created               timestamp with local time zone not null,
    created_by            varchar2(255) not null,
    updated               timestamp with local time zone,
    updated_by            varchar2(255) )
;

create or replace trigger f2a_tags_biu
before insert or update on f2a_tags
for each row
begin
   if inserting then 
      if :new.id is null then 
        :new.id := to_number(sys_guid(),'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
      end if;
      :new.created := localtimestamp;
      :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
   end if; 
   if updating then 
      :new.created := localtimestamp; 
      :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
   end if; 
end f2a_tags_biu; 
/

create table f2a_tags_tsum (
    tag                    varchar2(255),
    content_table          varchar2(128),
    tag_count              number,
    constraint f2a_tags_tspk primary key (tag,content_table) )
;

create table f2a_tags_sum (
    tag                    varchar2(255),
    tag_count              number,
    constraint f2a_tags_spk primary key (tag) )
;

create or replace procedure f2a_tags_sync (
    p_new_tags          in varchar2,
    p_old_tags          in varchar2,
    p_content_table     in varchar2,
    p_content_pk        in number )
as
    type tags is table of varchar2(255) index by varchar2(255);
    type tag_values is table of varchar2(32767) index by binary_integer;
    l_new_tags_a    tags;
    l_old_tags_a    tags;
    l_new_tags      tag_values;
    l_old_tags      tag_values;
    l_merge_tags    tag_values;
    l_dummy_tag     varchar2(255);
    i               integer;
    function string_to_table (
        str    in varchar2,
        sep    in varchar2 default ':')
        return tag_values
    is
        temp         tag_values;
        l_str        varchar2(32767) := str;
        pos          pls_integer;
        i            pls_integer := 1;
        l_sep_length pls_integer := length(sep);
    begin
        if str is null or sep is null then
            return temp;
        end if;
        if substr( l_str, 1, l_sep_length ) = sep then
            l_str := substr( l_str, l_sep_length + 1 );
        end if;
        if substr( l_str, length( l_str ) - l_sep_length + 1 ) = sep then
            l_str := substr( l_str, 1, length( l_str ) - l_sep_length );
        end if;
        loop
            pos := instr( l_str, sep );
            exit when nvl(pos,0) = 0;
            temp(i) := substr( l_str, 1, pos-1 );
            l_str := substr( l_str, pos + l_sep_length );
            i := i + 1;
        end loop;
        temp(i) := trim(l_str);
        return temp;
    exception when others then return temp;
    end;
begin
    l_old_tags := string_to_table(p_old_tags,',');
    l_new_tags := string_to_table(p_new_tags,',');
    if l_old_tags.count &gt; 0 then --do inserts and deletes
        --build the associative arrays
        for i in 1..l_old_tags.count loop
            l_old_tags_a(l_old_tags(i)) := l_old_tags(i);
        end loop;
        for i in 1..l_new_tags.count loop
            l_new_tags_a(l_new_tags(i)) := l_new_tags(i);
        end loop;
        --do the inserts
        for i in 1..l_new_tags.count loop
            begin
                l_dummy_tag := l_old_tags_a(l_new_tags(i));
            exception when no_data_found then
                insert into f2a_tags (tag, content_pk, content_table )
                values (trim(l_new_tags(i)), p_content_pk, p_content_table );
                l_merge_tags(l_merge_tags.count + 1) := l_new_tags(i);
            end;
        end loop;
        --do the deletes
        for i in 1..l_old_tags.count loop
            begin
                l_dummy_tag := l_new_tags_a(l_old_tags(i));
            exception when no_data_found then
                delete from f2a_tags where content_pk = p_content_pk and tag = l_old_tags(i);
                l_merge_tags(l_merge_tags.count + 1) := l_old_tags(i);
            end;
        end loop;
    else --just do inserts
        if l_new_tags.exists(1) then
          for i in 1..l_new_tags.count loop
              insert into f2a_tags (tag, content_pk, content_table )
              values (trim(l_new_tags(i)), p_content_pk, p_content_table );
              l_merge_tags(l_merge_tags.count + 1) := l_new_tags(i);
          end loop;
        end if;
    end if;
    for i in 1..l_merge_tags.count loop
        merge into f2a_tags_tsum s
        using (select count(*) tag_count
                 from f2a_tags
                where tag = l_merge_tags(i) and content_table = p_content_table ) t
        on (s.tag = l_merge_tags(i) and s.content_table = p_content_table )
        when not matched then insert (tag, content_table, tag_count)
                              values (trim(l_merge_tags(i)), p_content_table, t.tag_count)
        when matched then update set s.tag_count = t.tag_count;
        merge into f2a_tags_sum s
        using (select sum(tag_count) tag_count
                 from f2a_tags_tsum
                where tag = l_merge_tags(i) ) t
        on (s.tag = l_merge_tags(i) )
        when not matched then insert (tag, tag_count)
                              values (trim(l_merge_tags(i)), t.tag_count)
        when matched then update set s.tag_count = t.tag_count;
    end loop; 
end f2a_tags_sync;
/

-- triggers
create or replace trigger f2a_projects_biu
    before insert or update 
    on f2a_projects
    for each row
begin
    if :new.id is null then
        :new.id := to_number(sys_guid(), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    end if;
    if :new.security_group_id is null then
        :new.security_group_id := 0;
    end if;
    if inserting then
        :new.created := sysdate;
        :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
    end if;
    :new.updated := sysdate;
    :new.updated_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
end f2a_projects_biu;
/

create or replace trigger f2a_imports_biu
    before insert or update 
    on f2a_imports
    for each row
begin
    if :new.id is null then
        :new.id := to_number(sys_guid(), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    end if;
    if :new.security_group_id is null then
        :new.security_group_id := 0;
    end if;
    if inserting then
        :new.created := sysdate;
        :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
    end if;
    :new.updated := sysdate;
    :new.updated_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
end f2a_imports_biu;
/


-- indexes
create index f2a_imports_i1 on f2a_imports (project_id);
-- load data
 
insert into f2a_projects (
    id,
    name,
    description,
    start_date,
    deadline_date
) values (
    142765361048391701677808780792094828487,
    'Availability Optimization',
    'Vulputate porttitor ligula. Nam semper diam suscipit elementum sodales. Proin sit amet massa eu lorem commodo ullamcorper.Interdum et malesuada fames ac ante ipsum primis in faucibus. Ut id nulla ac sapien suscipit tristique ac volutpat risus.Phasellus vitae ligula commodo, dictum lorem sit amet, imperdiet ex. Etiam.',
    sysdate - 61,
    sysdate - 68
);

insert into f2a_projects (
    id,
    name,
    description,
    start_date,
    deadline_date
) values (
    142765361048392910603628395421269534663,
    'Cloud Optimization',
    'Arcu in massa pharetra, id mattis risus rhoncus.Cras vulputate porttitor ligula. Nam semper diam suscipit elementum sodales. Proin sit amet massa eu lorem commodo ullamcorper.Interdum et malesuada fames ac ante ipsum primis in faucibus. Ut id nulla ac sapien suscipit tristique ac volutpat risus.Phasellus vitae ligula commodo, dictum lorem sit amet, imperdiet ex. Etiam cursus porttitor tincidunt. Vestibulum ante ipsumprimis in faucibus orci luctus et ultrices posuere cubilia Curae; Proin vulputate placerat pellentesque.',
    sysdate - 17,
    sysdate - 4
);

insert into f2a_projects (
    id,
    name,
    description,
    start_date,
    deadline_date
) values (
    142765361048394119529448010050444240839,
    'User Group Advertising',
    'Tincidunt. Vestibulum ante ipsumprimis in faucibus orci luctus et ultrices posuere cubilia Curae; Proin vulputate placerat pellentesque. Proin viverra lacinialectus, quis consectetur mi venenatis nec. Donec convallis sollicitudin elementum. Nulla facilisi. In posuere blandit leoeget malesuada. Vivamus efficitur ipsum tellus, quis posuere mi maximus vitae. Quisque tortor odio, feugiat eget sagittisvel, pretium ut metus. Duis et commodo arcu, in vestibulum tellus. In sollicitudin nisi mi, pharetra gravida ex semper ut.Donec.',
    sysdate - 23,
    sysdate - 34
);

insert into f2a_projects (
    id,
    name,
    description,
    start_date,
    deadline_date
) values (
    142765361048395328455267624679618947015,
    'Documentation Review',
    'Sapien suscipit tristique ac volutpat risus.Phasellus vitae ligula commodo, dictum lorem sit amet, imperdiet ex. Etiam cursus porttitor tincidunt. Vestibulum ante ipsumprimis in faucibus orci luctus et ultrices.',
    sysdate - 12,
    sysdate - 57
);

commit;
-- load data
 
-- Generated by Quick SQL Friday May 04, 2018  19:52:03
 
/*
projects /insert 4
   name /nn
   description
   start_date date
   deadline_date date
   imports 
      file_type / nn vc20
      mime_type vc300
      filename /nn vc500
      content clob

# settings = { prefix: "F2A", PK: "TRIG", auditCols: true, SecurityGroupID: true, drop: true, language: "EN", APEX: true, tags: true }
*/

-- drop objects
--drop table f2a_file_status_codes cascade constraints;
drop table f2a_files cascade constraints;
drop table f2a_modules cascade constraints;
drop table f2a_module_items cascade constraints;

-- create tables
create table f2a_file_status_codes (
    security_group_id              number not null,
    status_code                    varchar2(20) not null constraint f2a_file_status_status_code_pk primary key,
    status_name                    varchar2(60),
    created                        date not null,
    created_by                     varchar2(255) not null,
    updated                        date not null,
    updated_by                     varchar2(255) not null
)
;

create table f2a_files (
    id                             number not null constraint f2a_files_id_pk primary key,
    security_group_id              number not null,
    file_name                      varchar2(255)
                                   constraint f2a_files_file_name_unq unique,
    content_type                   varchar2(255),
    status_code                    varchar2(20)
                                   constraint f2a_files_status_code_fk
                                   references f2a_file_status_codes (status_code) on delete cascade,
    description                    varchar2(4000),
    file_type                      varchar2(4000) constraint f2a_files_file_type_cc
                                   check (file_type in ('FORM','LIBRARY','MENU','REPORT')),
    content                        clob,
    project_id                     number
                                   constraint f2a_files_project_id_fk
                                   references f2a_projects(id) on delete cascade,
    created                        date not null,
    created_by                     varchar2(255) not null,
    updated                        date not null,
    updated_by                     varchar2(255) not null
)
;

create table f2a_modules (
    id                             number not null constraint f2a_modules_id_pk primary key,
    security_group_id              number not null,
    module_type                    varchar2(4000) constraint f2a_modules_module_type_cc
                                   check (module_type in ('BLOCK','QUERY','PROGRAM','MENU')),
    module_name                    varchar2(255),
    content_type                   varchar2(100),
    content                        clob,
    query_based                    varchar2(1) constraint f2a_modules_query_based_cc
                                   check (query_based in ('Y','N')),
    created                        date not null,
    created_by                     varchar2(255) not null,
    updated                        date not null,
    updated_by                     varchar2(255) not null
)
;

create table f2a_module_items (
    id                             number not null constraint f2a_module_items_id_pk primary key,
    security_group_id              number not null,
    item_type                      varchar2(255),
    item_name                      varchar2(255),
    component_type                 varchar2(100),
    item_label                     varchar2(255),
    item_length                    number,
    item_help                      varchar2(4000),
    database_item                  varchar2(4000) constraint f2a_module_item_database_it_cc
                                   check (database_item in ('Y','N')),
    created                        date not null,
    created_by                     varchar2(255) not null,
    updated                        date not null,
    updated_by                     varchar2(255) not null
)
;


-- triggers
create or replace trigger f2a_files_biu
    before insert or update 
    on f2a_files
    for each row
begin
    if :new.id is null then
        :new.id := to_number(sys_guid(), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    end if;
    if :new.security_group_id is null then
        :new.security_group_id := 0;
    end if;
    if inserting then
        :new.created := sysdate;
        :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
    end if;
    :new.updated := sysdate;
    :new.updated_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
end f2a_files_biu;
/

create or replace trigger f2a_file_status_codes_biu
    before insert or update 
    on f2a_file_status_codes
    for each row
begin
    if :new.status_code is null then
        :new.status_code := to_number(sys_guid(), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    end if;
    if :new.security_group_id is null then
        :new.security_group_id := 0;
    end if;
    if inserting then
        :new.created := sysdate;
        :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
    end if;
    :new.updated := sysdate;
    :new.updated_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
end f2a_file_status_codes_biu;
/

create or replace trigger f2a_modules_biu
    before insert or update 
    on f2a_modules
    for each row
begin
    if :new.id is null then
        :new.id := to_number(sys_guid(), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    end if;
    if :new.security_group_id is null then
        :new.security_group_id := 0;
    end if;
    if inserting then
        :new.created := sysdate;
        :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
    end if;
    :new.updated := sysdate;
    :new.updated_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
end f2a_modules_biu;
/

create or replace trigger f2a_module_items_biu
    before insert or update 
    on f2a_module_items
    for each row
begin
    if :new.id is null then
        :new.id := to_number(sys_guid(), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    end if;
    if :new.security_group_id is null then
        :new.security_group_id := 0;
    end if;
    if inserting then
        :new.created := sysdate;
        :new.created_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
    end if;
    :new.updated := sysdate;
    :new.updated_by := nvl(sys_context('APEX$SESSION','APP_USER'),user);
end f2a_module_items_biu;
/


-- indexes
create index f2a_files_i1 on f2a_files (project_id);
create index f2a_files_i2 on f2a_files (status_code);
-- load data
 
-- Generated by Quick SQL Saturday June 09, 2018  18:16:40
 
/*
file_status_codes 
  status_code vc20 /pk
  status_name
  
files
  file_name vc255 /unique
  content_type vc255
  status_code /fk f2a_file_status_codes
  description
  file_type /check FORM,LIBRARY,MENU,REPORT
  content clob
  project_id /fk f2a_projects(id)
  
modules
  module_type /check BLOCK,QUERY,PROGRAM,MENU
  module_name
  content_type vc100
  content clob
  query_based vc1 /check Y,N
 
  
module_items
  item_type vc255
  item_name
  component_type vc100
  item_label vc255
  item_length num
  item_help
  database_item /check Y,N

# settings = { prefix: "f2a", PK: "TRIG", auditCols: true, SecurityGroupID: true, DB: "11g", drop: true, language: "EN", APEX: true }
*/
