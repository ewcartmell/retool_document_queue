with transcribed_docs as (

select
distinct
  REGEXP_SUBSTR(transcribed_documents.source_doc_fid, '[0-9]+') as document_id

from nis_transcription.transcribed_documents

    where lower(document_type) like 'mbl'


  ), transcribed_mbls as (

select
distinct
documentable_id as shipment_id

from
legacy.prep_documents
inner join transcribed_docs on transcribed_docs.document_id = prep_documents.document_id

where
lower(documentable_type) like 'shipment'
and document_type_id in (115, 114, 38)

  ), mbl_drop_off as (
  select
  distinct
  noteable_id

  from
  core.notes

  where
  noteable_type like 'Shipment'
  and lower(notes.message) like '%#mblnumber%'
  and deleted_at is null

)

, mbl_shipments as (

select
distinct
documentable_id
, bi_shipments.arrival_date::date as arrival_date
  , transportation_mode_blended_name

from
core.documents
left join legacy.bi_shipments
on bi_shipments.shipment_id = documents.documentable_id

where
documentable_type like 'Shipment'
and document_type_id in (115, 114, 38)
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
, case when mbl_drop_off.noteable_id is not null then 'Complete' else 'No' end as mbl_digitized
, bi_shipments.arrival_date::date as shipment_arrival_date
--, supply_shipments.squad_office

from
legacy.bi_shipments
inner join mbl_shipments
on mbl_shipments.documentable_id = bi_shipments.shipment_id
left join mbl_drop_off
on mbl_drop_off.noteable_id = bi_shipments.shipment_id
left join legacy.supply_shipments
on supply_shipments.shipment_id = bi_shipments.shipment_id
left join transcribed_mbls
on transcribed_mbls.shipment_id = bi_shipments.shipment_id

where
mbl_digitized like 'No'
and transcribed_mbls.shipment_id is null
--((mbl_drop_off.noteable_id is null) or (hbl_drop_off.noteable_id is null or hbl_shipments.partner_hbl is null) or (pl_drop_off.noteable_id is null))
--and supply_shipments.squad_office in ('new_york', 'los_angeles', 'chicago', 'seattle', 'san_francisco', 'philadelphia', 'atlanta', 'dallas', 'shenzhen', 'shanghai', 'hong_kong', 'copenhagen', 'london', 'hamburg', 'amsterdam')
and shipment_arrival_date is not null
and bi_shipments.completed_at is null
and bi_shipments.client_id NOT IN (11522, 36919, 12441, 14163)
and bi_shipments.shipment_id > 1000000


order by
shipment_arrival_date asc

