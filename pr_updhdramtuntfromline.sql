   PROCEDURE pr_updhdramtuntfromline (
      p_claim_header_sid   IN     claim_header.claim_header_sid%TYPE,
      p_created_by         IN     claim_header.created_by%TYPE,
      p_err_code              OUT VARCHAR2,
      p_err_msg               OUT VARCHAR2)
   IS
      v_billed_amt_null_flg    VARCHAR2 (1) DEFAULT NULL;
   BEGIN
      -- Populate the flag Y for NULL and N for not null , for  amt and unit in claim_header.
      --   Begin Comment - Raji(MITEAM)-03142008- STO4_Raji_MI_To handle as per claim header table
      BEGIN
         SELECT DECODE (TRIM (total_billed_amount), 0, 'Y', 'N')
           INTO v_billed_amt_null_flg
           FROM claim_header
          WHERE claim_header_sid = p_claim_header_sid;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_billed_amt_null_flg := NULL;
         WHEN TOO_MANY_ROWS
         THEN
            v_billed_amt_null_flg := NULL;
      END;

      IF v_billed_amt_null_flg = 'Y'
      THEN
         null;
      ELSE
         p_err_code := '0';
         p_err_msg :=
               'Sucessful update of Amt/Unit for claim_header_sid: '
            || p_claim_header_sid;
      END IF;

      --Return success
      p_err_code := '0';
      p_err_msg :=
            'Sucessful update of Amt/Unit for claim_header_sid: '
         || p_claim_header_sid;
   EXCEPTION
      WHEN no_data_found
      THEN
         p_err_code := SQLCODE;
         p_err_msg := SQLERRM
   END pr_updhdramtuntfromline;