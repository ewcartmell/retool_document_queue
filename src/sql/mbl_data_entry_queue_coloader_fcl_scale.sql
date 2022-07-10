with mbl_drop_off as (
  select
  distinct
  messageable_id

  from
  entities.platform_messages

  where
  messageable_type like 'shipment'
  and lower(platform_messages.body) like '%#mblnumber%'

)
, transcribed_docs as (

select
distinct
  REGEXP_SUBSTR(transcribed_documents.source_doc_fid, '[0-9]+') as document_id

from nis_transcription.transcribed_documents

    where lower(document_type) like 'mbl'


)
, transcribed_mbls as (

select
distinct
documentable_id as shipment_id

from
legacy.prep_documents
inner join transcribed_docs on transcribed_docs.document_id = prep_documents.document_id

where
lower(documentable_type) like 'shipment'
and document_type_id in (115, 114, 38)

)
, mbl_shipments as (

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
and document_type_id in (115, 114, 38)
and bi_shipments.departure_date > '2020-08-21'
and transportation_mode_blended_name in ('Ocean LCL')

order by
arrival_date asc

)

, in_house_lcl as (
select
containers.shipment_id as child_flex_ids

from entities.containers

left join core.consols
on containers.consol_id = consols.id

where
consols.consol_shipment_id is not null

  )

select
bi_shipments.shipment_id
, 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as shipment_link
, case when mbl_drop_off.messageable_id is not null then 'Complete' else 'No' end as mbl_digitized
, bi_shipments.arrival_date::date as shipment_arrival_date
--, supply_shipments.squad_office

from
entities.shipment_attributes
join entities.shipment_timeline on shipment_attributes.shipment_id = shipment_timeline.shipment_id
join legacy.bi_shipments on shipment_attributes.shipment_id = bi_shipments.shipment_id
inner join mbl_shipments
on mbl_shipments.documentable_id = bi_shipments.shipment_id
left join mbl_drop_off
on mbl_drop_off.messageable_id = bi_shipments.shipment_id
left join legacy.supply_shipments
on supply_shipments.shipment_id = bi_shipments.shipment_id
left join in_house_lcl
on in_house_lcl.child_flex_ids = bi_shipments.shipment_id

left join transcribed_mbls
on transcribed_mbls.shipment_id = bi_shipments.shipment_id

where
mbl_digitized like 'No'
and transcribed_mbls.shipment_id is null

and shipment_arrival_date is not null
and shipment_attributes.completed_at is null
--and in_house_lcl.child_flex_ids is null
and shipment_attributes.consol_shipment_id is not null
and shipment_attributes.consol_shipment_id != shipment_attributes.shipment_id

order by
shipment_arrival_date asc