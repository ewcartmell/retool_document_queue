with an_drop_off as (
  select
  distinct
  messageable_id
   , platform_messages.created_ts

  from
  entities.platform_messages

  where
  PLATFORM_MESSAGES.messageable_type like 'shipment'
  and lower(platform_messages.body) like '%#anmblnumber%'

)

, an_shipments as (

select
distinct
documentable_id
, bi_shipments.arrival_date::date as arrival_date
  , transportation_mode_blended_name

from
legacy.prep_documents
left join legacy.bi_shipments
on bi_shipments.shipment_id = prep_documents.documentable_id

where
documentable_type like 'Shipment'
and document_type_id in (7,146,93,86)
and bi_shipments.departure_date > '2020-08-21'
--and mbl_drop_off.noteable_id is null
--and bi_shipments.arrival_date > current_timestamp()
and transportation_mode_blended_name in ('Ocean FCL')

order by
arrival_date asc

)

select
bi_shipments.shipment_id
, 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as shipment_link
, case when an_drop_off.messageable_id is not null then 'Complete' else 'No' end as an_digitized
, bi_shipments.arrival_date::date as shipment_arrival_date
--, supply_shipments.squad_office
, PREP_SHIPMENT_LOCATION_HIERARCHY.final_port as Import_Port

from
legacy.bi_shipments
inner join an_shipments
on an_shipments.documentable_id = bi_shipments.shipment_id
left join an_drop_off
on an_drop_off.messageable_id = bi_shipments.shipment_id
left join legacy.supply_shipments
on supply_shipments.shipment_id = bi_shipments.shipment_id

LEFT JOIN LEGACY.PREP_SHIPMENT_LOCATION_HIERARCHY
  on BI_SHIPMENTS.SHIPMENT_ID = PREP_SHIPMENT_LOCATION_HIERARCHY.SHIPMENT_ID

where
an_digitized like 'No'
--((mbl_drop_off.messageable_id is null) or (hbl_drop_off.messageable_id is null or hbl_shipments.partner_hbl is null) or (pl_drop_off.messageable_id is null))
--and supply_shipments.squad_office in ('new_york', 'los_angeles', 'chicago', 'seattle', 'san_francisco', 'philadelphia', 'atlanta', 'dallas', 'shenzhen', 'shanghai', 'hong_kong', 'copenhagen', 'london', 'hamburg')
and shipment_arrival_date is not null
and bi_shipments.completed_at is null
and bi_shipments.client_id NOT IN (11522, 36919, 12441, 14163)


order by
shipment_arrival_date asc

-- client 28169 is LCL Team
-- AN doc types 7,146,93,86