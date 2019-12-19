CREATE TABLE `noshad_test.ADT_cohort_test_to_be_del` as
(SELECT ADT.* except(time_in,time_out), DATETIME_SUB(ADT.time_in, INTERVAL TMP.JITTER_test DAY) as time_in,  DATETIME_SUB(ADT.time_out, INTERVAL TMP.JITTER_test DAY) as time_out
FROM `noshad_test.ADT_cohort_jit` as ADT,
  `noshad_test.tmp_rnd_shift` as TMP
WHERE ADT.jc_uid=TMP.ANON_ID
ORDER BY ADT.jc_uid, ADT.pat_enc_csn_id_coded, time_in
)
