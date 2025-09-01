WITH base as (
    select
        user,
        token_mint_address,
        symbol,
        case when type = 'MINT' then amount else 0 end as mints,
        case when type = 'BURN' then amount else 0 end as burns,
        
    from {{ ref('stg_token_mint_burn') }}
   
)

SELECT
    user,
    token_mint_address,
    symbol,
    SUM(mints) AS total_mints,
    SUM(burns) AS total_burns
FROM
    base
GROUP BY user, token_mint_address, symbol
ORDER BY 4 DESC
