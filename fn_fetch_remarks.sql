CREATE OR REPLACE  FUNCTION fn_fetch_remarks (p_table_name IN VARCHAR2, p_key_value IN VARCHAR2)
   RETURN VARCHAR2
   IS
      t_value_array   nt_varchar_large;
      v_remark        VARCHAR2 (4000)  := '';
      v_remark1       VARCHAR2 (4000)  := '';
   BEGIN
      t_value_array := nt_varchar_large ();
      t_value_array := pk_reference_utility.fn_csv2array (p_key_value);

      FOR i IN 1 .. t_value_array.COUNT
      LOOP
         EXECUTE IMMEDIATE    ' SELECT remark FROM reference_inactivation_status  WHERE UPPER(master_tbl_name) = '
                           || ''''
                           || UPPER (p_table_name)
                           || ''''
                           || ' AND primary_key_value = '
                           || ''''
                           || t_value_array (i)
                           || ''''
                      INTO v_remark1;

         v_remark := v_remark || v_remark1;
      END LOOP;

      RETURN (v_remark);
   END fn_fetch_remarks;