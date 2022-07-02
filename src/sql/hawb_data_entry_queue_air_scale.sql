with hawb_drop_off as (
  select
  distinct
  messageable_id

  from
  entities.platform_messages

  where
  messageable_type like 'shipment'
  and lower(platform_messages.body) like '%#hawbcarton%'
--  and messageable_id = 1337344

), transcribed_docs as (

select
distinct
  REGEXP_SUBSTR(transcribed_documents.source_doc_fid, '[0-9]+') as document_id

from nis_transcription.transcribed_documents

    where lower(document_type) like 'hawb'


  ), transcribed_hawb as (

select
distinct
documentable_id as shipment_id

from
legacy.prep_documents
inner join transcribed_docs on transcribed_docs.document_id = prep_documents.document_id

where
lower(documentable_type) like 'shipment'
and document_type_id in (6)

), in_house_hawb as (
  select
  shipment_id
  , hawbs
  , pieces

  from
  legacy.bi_air_shipments

  where
  ((lower(hawbs) like '%flx%')or (lower(hawbs) like '%flex%'))
  and pieces is not null
  and pieces != ''
--    and shipment_id = '1337344'
)

, hawb_shipments as (

select
distinct
documentable_id
, bi_shipments.arrival_date::date as arrival_date
, in_house_hawb.shipment_id as in_house_hawb

from
legacy.prep_documents
left join legacy.bi_shipments
on bi_shipments.shipment_id = prep_documents.documentable_id
left join in_house_hawb
on in_house_hawb.shipment_id = prep_documents.documentable_id

where
documentable_type like 'Shipment'
and document_type_id in (6)
and bi_shipments.departure_date > '2020-08-21'
--and hbl_drop_off.messageable_id is null
--and bi_shipments.arrival_date > current_timestamp()
and transportation_mode_blended_name in ('Air')
and prep_documents.archived_ts is null
--and in_house_hbl.shipment_id is not null
--and bi_shipments.shipment_id = '1337344'

order by
arrival_date asc

  ), delivery_orders as (

select
distinct
shipment_id

from
legacy.prep_delivery_orders

where
sent_at is null
--and deleted_ts is null
)

select
bi_shipments.shipment_id
, 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as shipment_link
, case when hawb_drop_off.messageable_id is not null then 'Complete'
        when hawb_shipments.in_house_hawb is not null then 'Complete'
        else 'No' end as hawb_count_digitized
, bi_shipments.arrival_date::date as shipment_arrival_date

from
legacy.bi_shipments
inner join hawb_shipments
    on hawb_shipments.documentable_id = bi_shipments.shipment_id
left join hawb_drop_off
    on hawb_drop_off.messageable_id = bi_shipments.shipment_id
left join legacy.supply_shipments
    on supply_shipments.shipment_id = bi_shipments.shipment_id
left join delivery_orders
    on delivery_orders.shipment_id = bi_shipments.shipment_id

left join transcribed_hawb
on transcribed_hawb.shipment_id = bi_shipments.shipment_id

where
hawb_count_digitized like 'No'
and transcribed_hawb.shipment_id is null
--((mbl_drop_off.messageable_id is null) or (hbl_drop_off.messageable_id is null or hbl_shipments.partner_hbl is null) or (pl_drop_off.messageable_id is null))
--and supply_shipments.squad_office in ('new_york', 'los_angeles', 'chicago', 'seattle', 'san_francisco', 'philadelphia', 'atlanta', 'dallas', 'shenzhen', 'shanghai', 'hong_kong', 'copenhagen', 'london', 'hamburg')
and shipment_arrival_date is not null
and ((bi_shipments.actual_port_pickup_date > current_timestamp()) or bi_shipments.actual_port_pickup_date is null)
and bi_shipments.completed_at is null
and bi_shipments.client_id NOT IN (11522, 36919, 12441, 14163)
--and bi_shipments.shipment_id = 1337344


order by
shipment_arrival_date asc