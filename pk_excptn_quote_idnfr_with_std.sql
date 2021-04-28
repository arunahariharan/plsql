CREATE OR REPLACE PACKAGE pk_rule_excptn_quote_idnfr
AS
   PROCEDURE pr_rule_excptn_quote_idnfr (p_procedure_iid          IN     NUMBER,
                                 p_prcdr_ctgry_lkpcd   IN     VARCHAR2,
                                 p_err_code               OUT NUMBER,
                                 p_err_msg                OUT VARCHAR2,
								 p_recipient_id        IN     VARCHAR2,
							     p_street1                OUT VARCHAR2,
							     p_street2                OUT VARCHAR2,
							     p_street3                OUT VARCHAR2,
							     p_city_town              OUT VARCHAR2,
							     p_state_prvnc            OUT VARCHAR2,
							     p_postal_code            OUT VARCHAR2);
END pk_rule_excptn_quote_idnfr;
/

CREATE OR REPLACE PACKAGE BODY pk_rule_excptn_quote_idnfr
AS
BEGIN
   PROCEDURE pr_rule_excptn_quote_idnfr (p_procedure_iid          IN     NUMBER,
                                 p_prcdr_ctgry_lkpcd   IN     VARCHAR2,
                                 p_err_code               OUT NUMBER,
                                 p_err_msg                OUT VARCHAR2,
								 p_recipient_id        IN     VARCHAR2,
							     p_street1                OUT VARCHAR2,
							     p_street2                OUT VARCHAR2,
							     p_street3                OUT VARCHAR2,
							     p_city_town              OUT VARCHAR2,
							     p_state_prvnc            OUT VARCHAR2,
							     p_postal_code            OUT VARCHAR2)
  IS
    v_procedure_iid         PROCEDURE.procedure_iid%TYPE;
	v_prcdr_code            PROCEDURE.prcdr_code%TYPE;
	v_cnt                    NUMBER;
  BEGIN
    v_procedure_iid := p_procedure_iid;

         SELECT prcdr_code
           INTO v_prcdr_code
           FROM PROCEDURE
          WHERE procedure_iid = v_procedure_iid;

      SELECT COUNT (*)
        INTO v_cnt
        FROM procedure_status x, procedure_detail y, PROCEDURE z
       WHERE     x.procedure_iid = y.procedure_iid
             AND x.prcdr_dtl_sid = y.prcdr_dtl_sid
             AND y.procedure_iid = z.procedure_iid
             AND z.prcdr_code = v_prcdr_code
             AND z.prcdr_ctgry_lkpcd = p_prcdr_ctgry_lkpcd
             AND SYSDATE BETWEEN x.from_date AND x.TO_DATE
             AND x.oprtnl_flag = 'A'
             AND x.status_cid = 1;

      IF v_cnt > 0
      THEN
         p_err_code := 4;
         p_err_msg :=
               'In Review record EXISTS for Code '
            || p_procedure_iid
            || ' and Prcdr Ctgry : '
            || p_prcdr_ctgry_lkpcd;
      END IF;
	  
	BEGIN
	  SELECT ad.street1, 
			  ad.street2, 
			  ad.street3, 
			  ad.city_town_name,
			  ad.state_prvnc_code,
			  ad.postal_code          
		INTO  p_street1,
			  p_street2,
			  p_street3,
			  p_city_town,
			  p_state_prvnc,
			  p_postal_code                                                    
		FROM  (SELECT src.PrvdrLctnXPrvdrLctnStSid,
				src.PrvdrLctnXPrvdrLctnSid,
				src.BillingProviderNPI,
				src.PrvdrLctnIID,
				rownum AS rno
			  FROM
				( SELECT DISTINCT(PLXPLS.PRVDR_LCTN_X_PRVDR_LCTN_ST_SID) AS "PrvdrLctnXPrvdrLctnStSid",
				  PLXPL.PRVDR_LCTN_X_PRVDR_LCTN_SID                      AS "PrvdrLctnXPrvdrLctnSid",
				  PD.NATIONAL_PRVDR_IDNTFR                               AS "BillingProviderNPI",
				  DECODE(P1.BSNS_ENTITY_TYPE_LKPCD,'P',REPLACE(PD.LAST_NAME,',','')
				  ||REPLACE(pd.FIRST_NAME,',',''),'O',REPLACE(PD.ORG_BSNS_NAME,',',''))                     AS "Billing Provider Name",
				  TO_CHAR(PLXPLS.FROM_DATE, 'MM/dd/yyyy')                                                   AS "Start Date",
				  TO_CHAR(PLXPLS.TO_DATE, 'MM/dd/yyyy')                                                     AS "End Date",
				  ST.STATUS_NAME                                                                            AS "Status",
				  DECODE(PLXPLS.OPRTNL_FLAG,'A','Active','I','Inactive')                                    AS "Operational Status",
				  DECODE(PLXPLS.OPRTNL_FLAG,'I', TO_CHAR (PLXPLS.MODIFIED_DATE,'MM/dd/yyyy hh24:mi:ss'),'') AS "Inactivation Date",
				  TO_CHAR(PLXPLS.MODIFIED_DATE, 'MM-dd-yyyy hh24:mi:ss')                                    AS "ModifiedDate",
				  DECODE(PLXPLS.OPRTNL_FLAG,'I', PLXPLS.MODIFIED_DATE,'')                                   AS "FilterInactivationDate",
				  PLXPL.CHILD_PRVDR_LCTN_IID                                                                AS "PrvdrLctnIID",
				  P1.PRVDR_MMIS_IDNTFR                                                                      AS "MMIS_ID"
				FROM
				  PROVIDER_LOCATION PL,
				  PRVDR_LCTN_X_PRVDR_LCTN_STATUS PLXPLS,
				  PRVDR_LCTN_X_PRVDR_LCTN PLXPL,
				  PROVIDER P,
				  PROVIDER_DETAIL PD,
				  STATUS ST,
				  PROVIDER P1,
				  PROVIDER_LOCATION PLP,
				  PROVIDER_LOCATION_DETAIL PLD,
				  PRVDR_LCTN_STATUS PLS
				WHERE p.prvdr_mmis_idntfr = p_recipient_id
				AND pls.STATUS_CID = 1
				AND pls.OPRTNL_FLAG = 'A'
				AND TRUNC(v_pa_srvc_frm_dt) BETWEEN pls.from_date AND pls.to_date
				AND PLS.PRVDR_LCTN_IID =  PL.PRVDR_LCTN_IID
				AND PLXPL.PRVDR_LCTN_X_PRVDR_LCTN_SID = PLXPLS.PRVDR_LCTN_X_PRVDR_LCTN_SID
				AND PLXPLS.STATUS_CID                 = ST.STATUS_CID
				AND PD.NATIONAL_PRVDR_IDNTFR          > 0
				AND PL.PRVDR_LCTN_IID                 = PLXPL.CHILD_PRVDR_LCTN_IID
				AND PLP.PRVDR_SID                     = P.PRVDR_SID
				AND PLD.PRVDR_LCTN_IID                = PLP.PRVDR_LCTN_IID
				AND PLD.PRVDR_LCTN_IID                = PLXPL.PARENT_PRVDR_LCTN_IID
				AND TRUNC(SYSDATE) BETWEEN PLD.FROM_DATE AND PLD.TO_DATE
				AND PL.PRVDR_SID = P1.PRVDR_SID
				AND P1.PRVDR_SID = PD.PRVDR_SID
				AND TRUNC(SYSDATE) BETWEEN PD.FROM_DATE AND PD.TO_DATE
				AND PD.STATUS_CID        = 2
				AND PLXPL.ASSOC_TYPE_CID = 3
				AND ST.OPRTNL_FLAG       = 'A'
				AND PD.OPRTNL_FLAG       = 'A'
				AND PLD.OPRTNL_FLAG      = 'A'
				AND PLD.STATUS_CID       = 2
				AND PLXPLS.OPRTNL_FLAG   = 'A'
				AND ST.STATUS_TYPE_CID   = 1
				AND ST.STATUS_CID        =2
				AND TRUNC(v_pa_srvc_frm_dt) BETWEEN PLXPLS.from_date AND PLXPLS.to_date    
				ORDER BY
				  UPPER(Status) DESC
				)SRC
			  ) t1 ,
			  prvdr_lctn_x_address plxa,
			  address ad
			WHERE t1.rno         =1
			AND t1.PrvdrLctnIID=plxa.prvdr_lctn_iid
			AND plxa.status_Cid  =2
			AND plxa.oprtnl_flag ='A'
			AND TRUNC(v_pa_srvc_frm_dt) BETWEEN plxa.from_date AND plxa.to_date
			AND plxa.adrs_type_cid=2
			AND plxa.adrs_Sid     =ad.adrs_sid
			AND ad.oprtnl_flag    ='A';         
	EXCEPTION
	 WHEN OTHERS
	  THEN
		  p_street1:=NULL;
		  p_street2:=NULL;
		  p_street3:=NULL;
		  p_city_town:=NULL;
		  p_state_prvnc:=NULL;
		  p_postal_code:=NULL; 
    END;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	  RETURN NULL;
    WHEN OTHERS THEN
	  pk_common_dmlerr_logging.pr_cndtnl_err_log(NULL, FALSE);
  END pr_rule_excptn_quote_idnfr;
END pk_rule_excptn_quote_idnfr;
/
