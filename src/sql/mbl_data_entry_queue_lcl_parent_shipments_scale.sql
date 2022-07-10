with mbl_drop_off as (
  select
  distinct
  messageable_id

  from
  entities.platform_messages

  where
  PLATFORM_MESSAGES.messageable_type like 'shipment'
  and lower(platform_messages.body) like '%#mblnumber%'

)
,  transcribed_docs as (

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
  and bi_shipments.client_id NOT IN (11522, 36919, 12441)

--and mbl_drop_off.noteable_id is null
--and bi_shipments.arrival_date > current_timestamp()
--and lower(transportation_mode_blended_name) like '%ocean lcl%'

order by
arrival_date asc

)

select distinct
consol_shipment_id
, 'https://core.flexport.com/shipments/' || consol_shipment_id|| '/documents' as shipment_link
, case when mbl_drop_off.messageable_id is not null then 'Complete' else 'No' end as mbl_digitized
, bi_shipments.arrival_date as shipment_arrival_date
--, CHILD_SQUAD_OFFICES

from
entities.shipment_attributes
inner join mbl_shipments
on mbl_shipments.documentable_id = shipment_attributes.consol_shipment_id
left join mbl_drop_off
on mbl_drop_off.messageable_id = shipment_attributes.consol_shipment_id
inner join legacy.bi_shipments
on bi_shipments.shipment_id = shipment_attributes.consol_shipment_id
--left join legacy.bi_clients on bi_shipments.client_id = bi_clients.client_id


left join transcribed_mbls
on transcribed_mbls.shipment_id = bi_shipments.shipment_id

where
mbl_digitized like 'No'
and transcribed_mbls.shipment_id is null
--and bi_clients.squad_office like 'NYC'
and shipment_arrival_date is not null
--and shipment_attributes.consol_shipment_id = shipment_attributes.shipment_id
--and bi_shipments.completed_at is null
--and lower(CHILD_SQUAD_OFFICES) in ('%new_york%', '%los_angeles%', '%chicago%', '%seattle%', '%san_francisco%', '%philadelphia%', '%atlanta%', '%dallas%', '%shenzhen%', '%shanghai%', '%hong_kong%', '%copenhagen%', '%london%', '%hamburg%')