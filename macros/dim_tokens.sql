{% macro token_metadata(mint_address) %}
    CASE 
        WHEN {{ mint_address }} IN ('5dXXpWyZCCPhBHxmp79Du81t7t9oh7HacUW864ARFyft') THEN 'USDT'
        WHEN {{ mint_address }} IN ('8iBux2LRja1PhVZph8Rw4Hi45pgkaufNEiaZma5nTD5g') THEN 'USDC'
        WHEN {{ mint_address }} IN ('7QC4zjrKA6XygpXPQCKSS9BmAsEFDJR6awiHSdgLcDvS', 
            'Abjx9zzdatgA18ezxRhveJVU65T7NbKqiByremdpQVR1') THEN 'USX'
        WHEN {{ mint_address }} IN ('Gkt9h4QWpPBDtbaF5HvYKCc87H5WCRTUtMf77HdTGHB',
            '2RSo4tLSFHrco9bwboomq9CGEvnPEVoBSkqZSh87xq1j') THEN 'eUSX'
            WHEN {{mint_address}} IN ('4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU') THEN 'TokenN'
        ELSE 'UNKNOWN'
    END
{% endmacro %}


{% macro token_decimals(mint_address) %}
    CASE 
        WHEN {{ mint_address }} = '5dXXpWyZCCPhBHxmp79Du81t7t9oh7HacUW864ARFyft' THEN 6
        WHEN {{ mint_address }} = '8iBux2LRja1PhVZph8Rw4Hi45pgkaufNEiaZma5nTD5g' THEN 6
        WHEN {{ mint_address }} = '7QC4zjrKA6XygpXPQCKSS9BmAsEFDJR6awiHSdgLcDvS' THEN 6
        WHEN {{ mint_address }} = 'Abjx9zzdatgA18ezxRhveJVU65T7NbKqiByremdpQVR1' THEN 6
        WHEN {{ mint_address }} = 'Gkt9h4QWpPBDtbaF5HvYKCc87H5WCRTUtMf77HdTGHB' THEN 6
        WHEN {{ mint_address }} = '2RSo4tLSFHrco9bwboomq9CGEvnPEVoBSkqZSh87xq1j' THEN 6
        ELSE NULL
    END
{% endmacro %}