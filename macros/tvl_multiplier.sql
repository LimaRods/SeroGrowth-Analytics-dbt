-- macros/tvl_multiplier.sql
{% macro tvl_multiplier(address,symbol_col) %}

CASE
  -- Solstice
  WHEN {{ address }} = '6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG' AND {{ symbol_col }} = 'USX'        THEN 5
  WHEN {{ address }} = '3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC' AND  {{ symbol_col }} = 'eUSX'       THEN 1

  --Orca
  WHEN  {{ address }} = '2e3WeM4WwdEqwTtRnWN3gJSbhNg1P6Aj2y7kEdfrYbix' AND {{ symbol_col }} = 'USX'   THEN 10 -- ORCA USX/USDC
  WHEN  {{ address }} = '2e3WeM4WwdEqwTtRnWN3gJSbhNg1P6Aj2y7kEdfrYbix' AND {{ symbol_col }} = 'USDC'   THEN 5 -- ORCA USX/USDC
  WHEN  {{ address }} = 'AUr5EVRwGDsKB2EeS1V63ncjHXDNRDLVfBP47qNvPoVf' AND {{ symbol_col }} = 'eUSX'   THEN 2 -- ORCA eUSX/USX
  WHEN  {{ address }} = 'AUr5EVRwGDsKB2EeS1V63ncjHXDNRDLVfBP47qNvPoVf' AND {{ symbol_col }} = 'USX'   THEN 10 -- ORCA eUSX/USX

 -- Raydium
 WHEN  {{ address }} = 'EWivkwNtcxuPsU6RyD7Pfvs7u9Yv8nQ79tJ7xgGyPrp6' AND {{ symbol_col }} = 'USX'   THEN 10 -- Raydium USX/USDC
  WHEN  {{ address }} = 'EWivkwNtcxuPsU6RyD7Pfvs7u9Yv8nQ79tJ7xgGyPrp6' AND {{ symbol_col }} = 'USDC'   THEN 5 -- Raydium USX/USDC
  WHEN  {{ address }} = 'BkvKpstxgeEJYzvFnWWuAbTDcrFMJBty3kXxUfGG9D7n' AND {{ symbol_col }} = 'eUSX'   THEN 2 -- Raydium eUSX/USX
  WHEN  {{ address }} = 'BkvKpstxgeEJYzvFnWWuAbTDcrFMJBty3kXxUfGG9D7n' AND {{ symbol_col }} = 'USX'   THEN 10 -- Raydium eUSX/USX\


  -- Exponent
  WHEN  {{ address }} = 'Gz6LTebmfQqjbQD4C5NzqFN6PVWRd9pG3BJ4p4xHeDxF' AND {{ symbol_col }} = 'ELP-eUSX-11MAR26'   THEN 10 
  WHEN  {{ address }} = 'DDoYyEUcdkHV5a4NCPXDRL9f93NgPbqK9ZANAGL627wF' AND {{ symbol_col }} = 'YT-eUSX-11MAR26'   THEN 15 
  WHEN  {{ address }} = '6K6bDA3f2heMYZQzbu3GDzx73zEXCeWZ58msfc1kDA6n' AND {{ symbol_col }} = 'ELP-USX-09FEB26'   THEN 20 
  WHEN  {{ address }} = 'HQmMS5W34VcMtR85akhZgvypy7iqVWRXi282vwdf9eTX' AND {{ symbol_col }} =  'YT-USX-09FEB26'  THEN 30 
  ELSE 1
END

{% endmacro %}

--