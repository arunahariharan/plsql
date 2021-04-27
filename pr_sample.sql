CREATE OR REPLACE PROCEDURE pr_sample
AS
v_sysdate DATE;
BEGIN
 SELECT SYSDATE INTO v_sysdate FROM dual;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
  pk_common_dmlerr_logging.pr_cndtnl_err_log(NULL, FALSE);
END;
/
