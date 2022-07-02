with pl_drop_off as (
  select
  distinct
  noteable_id

  from
  core.notes

  where
  noteable_type like 'Shipment'
  and lower(notes.message) like '%#plcarton%'
  )

, pl_shipments as(

select
distinct
documentable_id
, bi_shipments.arrival_date::date as arrival_date

from
core.documents
left join legacy.bi_shipments
on bi_shipments.shipment_id = documents.documentable_id

where
documentable_type like 'Shipment'
and document_type_id in (5,66,46)
and bi_shipments.departure_date > '2020-08-21'
and documents.archived_at is null
--and pl_drop_off.noteable_id is null
--and bi_shipments.arrival_date > current_timestamp()
--and transportation_mode_blended_name in ('Air', 'Ocean FCL')

order by
arrival_date asc
  )
, pl_uploads as (
  select
distinct
documentable_id
, max(documents.created_at) as created_at

from
core.documents
left join legacy.bi_shipments
on bi_shipments.shipment_id = documents.documentable_id

where
documentable_type like 'Shipment'
and document_type_id in (5,66,46)
and bi_shipments.departure_date > '2020-08-21'
and documents.archived_at is null


  group by 1
  )
, pl_notes as (
    select
  distinct
  noteable_id
  , max(notes.created_at) as created_at

  from
  core.notes

  where
  noteable_type like 'Shipment'
  and lower(notes.message) like '%#plcarton%'

  group by 1
  )
, air_pickups as (

select
distinct
bi_shipments.shipment_id

from
legacy.bi_shipments

where
(bi_shipments.actual_port_pickup_date < current_timestamp())
and bi_shipments.transportation_mode_blended_name like 'Air'
--and shipment_id = 886662
)

, ocean_completions as (
  select
  distinct
  shipment_id

  from
  legacy.bi_shipments

  where
   bi_shipments.completed_at is not null
  and transportation_mode_blended_name like '%Ocean%'

  )
, hand_off as (
  select
  distinct
  noteable_id

  from
  core.notes

  where
  message like '%#tablevalidate%%Data Services%'
)
, pending_note as (
  select
  noteable_id
  , notes.created_at
  , message
  , rank() over(partition by noteable_id order by notes.created_at desc) as rank
  , first_name
  , last_name
  from core.notes
  join legacy.bi_flexport_users on notes.broker_id = bi_flexport_users.id
  where noteable_type = 'Shipment'
  and email like 'c-%'
  and office_resolved = 'san_francisco'

), need_carton_count as (
  select
  distinct
  noteable_id

  from
  core.notes

  where
  noteable_type like 'Shipment'
  and lower(notes.message) like '%#needciplcartoncount%'
  and datediff(days,created_at,current_timestamp()) < 2
  )

, customs_invoice as (
  select
  shipment_id
  , sum(coalesce(frozen_price_base, estimated_price_base)) as invoiced_customs

  from
  legacy.bi_service_items

  where
  title = 'Import Customs Clearance'
  and coalesce(frozen_price_base, estimated_price_base) > 0

  group by
  1

), flexport_import_broker as (
  select
    distinct legal_name
  , bi_shipments.shipment_id
    , rank() over(partition by bi_shipments.shipment_id order by involved_party_memberships.created_at desc) as rank

  from
  core.involved_party_groups
  left join core.involved_party_memberships on
  core.involved_party_groups.id = core.involved_party_memberships.involved_party_group_id
  left join core.company_entities on
  core.involved_party_memberships.company_entity_id = core.company_entities.id
  left join legacy.bi_shipments on
  legacy.bi_shipments.shipment_id = core.involved_party_groups.shipment_id

  where
    membership_type = 13

)

select
bi_shipments.shipment_id
, 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as shipment_link
, case when ((pl_drop_off.noteable_id is not null) and (pl_uploads.created_at < pl_notes.created_at)) then 'Complete' else 'No' end as pl_count_digitized
--, [pending_note.created_at:pst]::date || ' ' ||  left(pending_note.first_name, 1) || left(pending_note.last_name, 3) || ': ' ||  pending_note.message as ninja_pending_note
, bi_shipments.arrival_date::date as shipment_arrival_date
, pl_uploads.created_at::date as latest_pl_upload
, pl_notes.created_at::date as latest_pl_hashtag
, bi_shipments.transportation_mode_name
, case when customs_invoice.invoiced_customs > 0 then 1 else 0 end as customs_invoiced
--, supply_shipments.squad_office

from
legacy.bi_shipments
inner join pl_shipments
on pl_shipments.documentable_id = bi_shipments.shipment_id
left join pl_drop_off
on pl_drop_off.noteable_id = bi_shipments.shipment_id
join legacy.supply_shipments
on supply_shipments.shipment_id = bi_shipments.shipment_id
left join air_pickups
on air_pickups.shipment_id = bi_shipments.shipment_id
left join ocean_completions
on ocean_completions.shipment_id = bi_shipments.shipment_id
left join pl_uploads
on pl_uploads.documentable_id = bi_shipments.shipment_id
left join pl_notes
on pl_notes.noteable_id = bi_shipments.shipment_id
left join hand_off
on hand_off.noteable_id  = bi_shipments.shipment_id
left join pending_note on bi_shipments.shipment_id = pending_note.noteable_id and pending_note.rank = 1  and pending_note.created_at > scheduled_origin_pickup_date
left join need_carton_count on need_carton_count.noteable_id = bi_shipments.shipment_id
left join customs_invoice
on customs_invoice.shipment_id = legacy.bi_shipments.shipment_id
left join flexport_import_broker on flexport_import_broker.shipment_id = legacy.bi_shipments.shipment_id and flexport_import_broker.rank = 1 and lower(legal_name) like '%flexport%'

where
(customs_invoiced = 0 or uses_customs_service = 'FALSE' or flexport_import_broker.shipment_id is not null or supply_shipments.destination_country_name in ('Canada', 'United States'))
and pl_count_digitized like 'No'
and shipment_arrival_date is not null
and (datediff(days, shipment_arrival_date, current_timestamp()) < 14)
and air_pickups.shipment_id is null
and ocean_completions.shipment_id is null
and hand_off.noteable_id is null
and bi_shipments.completed_at is null
and bi_shipments.client_id NOT IN (11522, 36919, 12441, 14163)
and need_carton_count.noteable_id is null


order by
shipment_arrival_date asc