SELECT offer_number
, base_product_number_std
, ms_denorm
, brochure_type_id
,Sum(CASE WHEN fs_meta_store = 0 THEN total_stores ELSE 0 END) AS if_stores
,Sum(CASE WHEN fs_meta_store = 1 THEN total_stores ELSE 0 END) AS fs_stores
,Sum(CASE WHEN fs_meta_store = 0 THEN spm ELSE 0 END) AS if_spm
,Sum(CASE WHEN fs_meta_store = 1 THEN spm ELSE 0 END) AS fs_spm
,ceiling((fs_spm / if_spm)/0.05)*0.05 AS fs_ratio
,fs_stores / Cast(if_stores AS FLOAT) AS fs_if_stores
	FROM(
		SELECT	pk.offer_number
				, pk.base_product_number_std
				,brochure_type_id 
				,CASE WHEN meta_store_id  > 100 THEN 1 ELSE 0 end AS fs_meta_store
				,CASE WHEN meta_store_id  > 100 THEN meta_store_id - 100 ELSE meta_store_id end AS ms_denorm
				,CASE WHEN fs_number IS NOT NULL THEN 1 ELSE 0 END AS pa
				,total_stores
				,wk1_sales_all_stores_per_mill AS spm
				,wk1_sales_inc_event
		FROM	DXWI_PROD_GPF_PL_PLAY_PEN.promopl01_ms_wk1_sales_actual AS sls
		INNER JOIN DXWI_PROD_GPF_PL_PLAY_PEN.promopl01_promotions_key AS pk
		ON sls.offer_number = pk.offer_number

		LEFT JOIN (
					SELECT	DISTINCT item_id, fs_start_date, fs_end_date, fs_number
					FROM	DXWI_PROD_GPF_pl_PLAY_PEN.vw_PFC_PRDT_FTR_CAPC
					WHERE fs_number = 64 --PA fs_number is not always 64
				) AS pa
		ON pk.base_product_number_std = pa.item_id
		AND pk.offer_start_date = pa.fs_start_date

		WHERE  1=1
		AND offer_start_date BETWEEN 1180901 AND 1190101
		AND wk1_sales_inc_event > 500
		AND pa = 1
		) AS abc
GROUP BY 1,2,3,4
HAVING fs_spm >0 AND if_spm > 0
--AND fs_stores / Cast(if_stores AS FLOAT) BETWEEN 0.5 AND 1.5
AND fs_stores > 10 AND if_stores > 10
