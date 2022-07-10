with hbl_drop_off as (
  select
  distinct
  messageable_id

  from
  entities.platform_messages

  where
  PLATFORM_MESSAGES.messageable_type like 'Shipment'
  and lower(platform_messages.body) like '%#hblcarton%'

), transcribed_docs as (

select
distinct
  REGEXP_SUBSTR(transcribed_documents.source_doc_fid, '[0-9]+') as document_id

from nis_transcription.transcribed_documents

    where lower(document_type) like 'pgbl'


  ), transcribed_pgbl as (

select
distinct
documentable_id as shipment_id

from
legacy.prep_documents
inner join transcribed_docs on transcribed_docs.document_id = prep_documents.document_id

where
lower(documentable_type) like 'shipment'
and document_type_id in (8,42,74)


), partner_hbl as (
  select
  bi_shipments.shipment_id


  from
  legacy.bi_shipments
  left join core.bill_of_ladings
  on bill_of_ladings.shipment_id = bi_shipments.shipment_id

  where
  lower(bill_of_ladings.bill_number) not like '%flxt%'
)

, hbl_shipments as (

select
distinct
documentable_id
, bi_shipments.arrival_date::date as arrival_date
, partner_hbl.shipment_id as partner_hbl

from
legacy.prep_documents
left join legacy.bi_shipments
on bi_shipments.shipment_id = prep_documents.documentable_id
left join partner_hbl
on partner_hbl.shipment_id = prep_documents.documentable_id

where
documentable_type like 'Shipment'
and document_type_id in (8,42,74)
and bi_shipments.departure_date > '2020-08-21'
--and hbl_drop_off.noteable_id is null
--and bi_shipments.arrival_date > current_timestamp()
and transportation_mode_blended_name in ('Ocean FCL','Ocean LCL')
and bi_shipments.is_live_shipment
and prep_documents.archived_ts is null
--and in_house_hbl.shipment_id is not null

order by
arrival_date asc

  )

select
bi_shipments.shipment_id
, 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as shipment_link
, case when hbl_drop_off.messageable_id is not null then 'Complete' when hbl_shipments.partner_hbl is null then 'Complete' else 'No' end as hbl_count_digitized
, bi_shipments.arrival_date::date as shipment_arrival_date

from
legacy.bi_shipments
inner join hbl_shipments
on hbl_shipments.documentable_id = bi_shipments.shipment_id
left join hbl_drop_off
on hbl_drop_off.messageable_id = bi_shipments.shipment_id
left join legacy.supply_shipments
on supply_shipments.shipment_id = bi_shipments.shipment_id

left join transcribed_pgbl
on transcribed_pgbl.shipment_id = bi_shipments.shipment_id


where
hbl_count_digitized like 'No'
and transcribed_pgbl.shipment_id is null
--((mbl_drop_off.noteable_id is null) or (hbl_drop_off.noteable_id is null or hbl_shipments.partner_hbl is null) or (pl_drop_off.noteable_id is null))
--and supply_shipments.squad_office in ('new_york', 'los_angeles', 'chicago', 'seattle', 'san_francisco', 'philadelphia', 'atlanta', 'dallas', 'shenzhen', 'shanghai', 'hong_kong', 'copenhagen', 'london', 'hamburg')
and shipment_arrival_date is not null
and bi_shipments.completed_at is null
and bi_shipments.client_id NOT IN (11522, 36919, 12441, 14163)


order by
shipment_arrival_date asc