CREATE OR REPLACE FUNCTION fn_schema_privileges(
    p_grant_revoke VARCHAR,
    p_role_name  VARCHAR,
    p_all        BOOLEAN default True,
    p_connect    BOOLEAN default False,
    p_create     BOOLEAN default False,
    p_delete     BOOLEAN default False,
    p_execute    BOOLEAN default False,
    p_insert     BOOLEAN default False,
    p_references BOOLEAN default False,
    p_select     BOOLEAN default False,
    p_temporary  BOOLEAN default False,
    p_trigger    BOOLEAN default False,
    p_truncate   BOOLEAN default False,
    p_update     BOOLEAN default False,
    p_usage      BOOLEAN default False
)
RETURNS void
AS $$
DECLARE
    cursor_row RECORD;
    from_to    VARCHAR;
    tbl_privileges VARCHAR;
    seq_privileges VARCHAR;
    fun_privileges VARCHAR;
    sch_privileges VARCHAR;
BEGIN
 -- Descr:GRANT or REVOKE privileges for all objects in all schemas.
 -- Doesn't work with outside schema objects like types, domains, tablespaces.
 --
 -- Usage:SELECT fn_schema_privileges('GRANT', 'my_role', True);
 --       SELECT fn_schema_privileges('GRANT', 'my_role', False, False, False, False, False, False, True);
 --
    p_grant_revoke := upper(trim(both from p_grant_revoke));
    p_role_name    := upper(trim(both from p_role_name));
    IF p_all THEN
        tbl_privileges := 'ALL PRIVILEGES';
        seq_privileges := 'ALL PRIVILEGES';
        fun_privileges := 'ALL PRIVILEGES';
        sch_privileges := 'ALL PRIVILEGES';
    ELSE
        IF p_create  THEN sch_privileges := 'CREATE';  END IF;
        IF p_delete  THEN tbl_privileges := 'DELETE';  END IF;
        IF p_execute THEN fun_privileges := 'EXECUTE'; END IF;
        IF p_insert  THEN tbl_privileges := COALESCE(tbl_privileges    || ',', '') || 'INSERT'; END IF;
        IF p_references THEN tbl_privileges := COALESCE(tbl_privileges || ',', '') || 'REFERENCES'; END IF;
        IF p_select THEN
            tbl_privileges := COALESCE(tbl_privileges || ',', '') || 'SELECT';
            seq_privileges := COALESCE(seq_privileges || ',', '') || 'SELECT';
        END IF;
        IF p_trigger  THEN tbl_privileges := COALESCE(tbl_privileges || ',', '') || 'TRIGGER';  END IF;
        IF p_truncate THEN tbl_privileges := COALESCE(tbl_privileges || ',', '') || 'TRUNCATE'; END IF;
        IF p_update THEN
            tbl_privileges := COALESCE(tbl_privileges || ',', '') || 'UPDATE';
            seq_privileges := COALESCE(seq_privileges || ',', '') || 'SELECT';
        END IF;
        IF p_usage THEN
            seq_privileges := COALESCE(seq_privileges || ',', '') || 'USAGE';
            sch_privileges := COALESCE(sch_privileges || ',', '') || 'USAGE';
        END IF;
    END IF;

    IF p_grant_revoke = 'GRANT' THEN
        from_to := ' TO ';
    ELSE
        from_to := ' FROM ';
    END IF;

    FOR cursor_row IN
        SELECT
         upper(trim(both from p_grant_revoke)) || ' ' || upper(trim(both from tbl_privileges)) || ' ON ALL TABLES    IN SCHEMA ' || QUOTE_IDENT(n.nspname) || from_to || QUOTE_IDENT( p_role_name ) AS tables_sql
        ,upper(trim(both from p_grant_revoke)) || ' ' || upper(trim(both from seq_privileges)) || ' ON ALL SEQUENCES IN SCHEMA ' || QUOTE_IDENT(n.nspname) || from_to || QUOTE_IDENT( p_role_name ) AS sequences_sql
        ,upper(trim(both from p_grant_revoke)) || ' ' || upper(trim(both from fun_privileges)) || ' ON ALL FUNCTIONS IN SCHEMA ' || QUOTE_IDENT(n.nspname) || from_to || QUOTE_IDENT( p_role_name ) AS functions_sql
        ,upper(trim(both from p_grant_revoke)) || ' ' || upper(trim(both from sch_privileges)) || ' ON SCHEMA '                  || QUOTE_IDENT(n.nspname) || from_to || QUOTE_IDENT( p_role_name ) AS schema_sql
        FROM pg_catalog.pg_namespace n
        WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'
    LOOP
        EXECUTE cursor_row.tables_sql    ;
        EXECUTE cursor_row.sequences_sql ;
        EXECUTE cursor_row.functions_sql ;
        EXECUTE cursor_row.schema_sql    ;
    END LOOP;
END$$
LANGUAGE plpgsql VOLATILE;
