-- One row per deployed contract (a client's runtime instance of a template),
-- enriched with the template it instantiates. A conformed dimension that
-- resolves contract_id → client + template + version + conventions.
select
    c.contract_id,
    c.client_id,
    c.contract_template_id,
    c.contract_version,
    c.contract_hash,
    c.status                  as contract_status,
    c.created_at              as deployed_at,
    t.template_hash,
    t.description             as template_description,
    t.conventions
from {{ ref('stg_contracts') }} c
left join {{ ref('stg_contract_templates') }} t
    on  t.contract_template_id = c.contract_template_id
    and t.contract_version     = c.contract_version
