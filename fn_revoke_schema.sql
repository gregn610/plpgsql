CREATE OR REPLACE FUNCTION fn_revoke_schema(p_role_name VARCHAR)
RETURNS void
AS $$
DECLARE cursor_row RECORD;
BEGIN
    PERFORM fn_schema_privileges('REVOKE', p_role_name);
END$$
LANGUAGE plpgsql VOLATILE;
