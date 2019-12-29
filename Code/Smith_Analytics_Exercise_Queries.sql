
# For each practice, only use the primary care specialty providers, otherwise bring in radiologists, etc.

# Make a fact table to source the research questions
DROP TABLE IF EXISTS tmp_pc;

CREATE TABLE tmp_pc AS
	SELECT
		t1.group_practice,
        t1.practice_name,
		t1.npi,
        t3.total_unique_benes,
        t2.awv_count,
        ROUND(t2.awv_count/t3.total_unique_benes,2) AS awv_prcnt,
        t3.beneficiary_average_age,
        t3.beneficiary_average_risk_score,
        t3.beneficiary_race_nonwhite_prcnt
	FROM
		(SELECT DISTINCT 
			npi,
			CASE 
				WHEN group_practice_pac_id IS NULL THEN npi
				ELSE group_practice_pac_id
				END AS group_practice,
            CASE
				WHEN organization_legal_name = '' THEN CONCAT(last_name,', ',first_name,', ',middle_name,', ',credential)
                WHEN organization_legal_name IS NULL THEN CONCAT(last_name,', ',first_name,', ',middle_name,', ',credential)
                ELSE organization_legal_name
                END AS practice_name
		FROM physician_compare 
        WHERE state = 'DE' 
        AND primary_specialty IN ('FAMILY PRACTICE','GENERAL PRACTICE','GERIATRIC MEDICINE','INTERNAL MEDICINE','PEDIATRIC MEDICINE')) t1
                
        LEFT JOIN (SELECT 
						npi,
						SUM(line_srvc_cnt) AS awv_count
				   FROM physician_supplier_hcpcs
                   WHERE hcpcs_code IN('G0438','G0439','G0468')
                   GROUP BY 1) t2 ON(t1.npi = t2.npi)
                   
	    LEFT JOIN (SELECT DISTINCT
					npi,
                    total_unique_benes,
                    beneficiary_average_risk_score,
                    beneficiary_average_age,
                    ROUND((IFNULL(beneficiary_race_black_count,0)+IFNULL(beneficiary_race_api_count,0)+IFNULL(beneficiary_race_hispanic_count,0)+IFNULL(beneficiary_race_natind_count,0)+IFNULL(beneficiary_race_other_count,0)) / (IFNULL(beneficiary_race_white_count,0)+IFNULL(beneficiary_race_black_count,0)+IFNULL(beneficiary_race_api_count,0)+IFNULL(beneficiary_race_hispanic_count,0)+IFNULL(beneficiary_race_natind_count,0)+IFNULL(beneficiary_race_other_count,0)),2) AS beneficiary_race_nonwhite_prcnt
				   FROM
					physician_supplier_agg) t3 ON(t1.npi = t3.npi)
   ;
        
# Q1 
SELECT COUNT(DISTINCT group_practice) FROM tmp_pc;

# Q2 
SELECT group_practice, practice_name, SUM(awv_count) FROM tmp_pc GROUP BY 1,2 ORDER BY 3 DESC LIMIT 1; 

# Q3 
## 	A. Performance by practice
	SELECT
        group_practice,
        practice_name,
        SUM(total_unique_benes) AS total_unique_benes,
        SUM(awv_count) AS awv_count,
        ROUND(SUM(awv_count) / SUM(total_unique_benes),2) AS awv_prcnt
	FROM
		tmp_pc
	WHERE 
		total_unique_benes IS NOT NULL
	GROUP BY
		1,2
	ORDER BY
		5 DESC;
        
#   B. Performance by provider within practice
	SELECT
        t1.group_practice,
        t1.practice_name,
        t1.npi,
        t2.nppes_provider_last_org_name AS last_name,
        t2.nppes_provider_first_name AS first_name,
        t2.nppes_credentials,
        t2.provider_type,
        SUM(t1.total_unique_benes) AS total_unique_benes,
        IFNULL(SUM(t1.awv_count),0) AS awv_count,
        IFNULL(ROUND(SUM(t1.awv_count) / SUM(t1.total_unique_benes),2),0) AS awv_prcnt
	FROM
		tmp_pc t1
        LEFT JOIN physician_supplier_agg t2 ON(t1.npi = t2.npi)
	WHERE 
		t1.total_unique_benes IS NOT NULL
	GROUP BY
		1,2,3,4,5,6,7
	ORDER BY
		1 ASC, 10 DESC;


		