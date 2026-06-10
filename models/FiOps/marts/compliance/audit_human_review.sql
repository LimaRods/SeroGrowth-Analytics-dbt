-- COMPLIANCE — human-in-the-loop log. Facts a human reviewed (reviewed_by set)
-- or that arrived below the auto-accept confidence bar (< 0.85). Proves the
-- review layer. When OPS.human_review_queue is populated, UNION it here for the
-- full requested→completed lifecycle.
select
    client_id,
    deal_id,
    contract_id,
    instrument_type,
    event_type,
    metadata:reviewed_by::string     as reviewed_by,
    metadata:confidence_score::float as confidence_score,
    case
        when metadata:reviewed_by is not null            then 'reviewed'
        when metadata:confidence_score::float < 0.85     then 'low_confidence'
    end                              as review_flag,
    business_date,
    occurred_at
from {{ ref('deal_events_current') }}
where metadata:reviewed_by is not null
   or metadata:confidence_score::float < 0.85
