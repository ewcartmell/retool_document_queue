with transcribed_docs as (

select
distinct
  REGEXP_SUBSTR(transcribed_documents.source_doc_fid, '[0-9]+') as document_id

from nis_transcription.transcribed_documents

    where document_type like 'mawb'


  ), transcribed_mbls as (

select
distinct
documentable_id as shipment_id

from
legacy.prep_documents
inner join transcribed_docs on transcribed_docs.document_id = prep_documents.document_id

where
documentable_type like 'Shipment'
and document_type_id in (37)

      ), mawb_drop_off as (
  select
  distinct
  messageable_id

  from
  entities.platform_messages

  where
  messageable_type like 'shipment'
  and lower(platform_messages.body) like '%#mawbnumber%'

)

, mawb_shipments as (

select
distinct
documentable_id
, bi_shipments.arrival_date::date as arrival_date
  , transportation_mode_blended_name

from
LEGACY.PREP_DOCUMENTS
left join legacy.bi_shipments
on bi_shipments.shipment_id = PREP_DOCUMENTS.documentable_id

where
documentable_type like 'Shipment'
and document_type_id in (37)
and bi_shipments.departure_date > '2020-08-21'
and transportation_mode_blended_name in ('Air')


order by
arrival_date asc

)

select
bi_shipments.shipment_id
, 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as shipment_link
, case when mawb_drop_off.messageable_id is not null then 'Complete' else 'No' end as mawb_digitized
, bi_shipments.arrival_date::date as shipment_arrival_date

from
legacy.bi_shipments
inner join mawb_shipments
on mawb_shipments.documentable_id = bi_shipments.shipment_id
left join mawb_drop_off
on mawb_drop_off.messageable_id = bi_shipments.shipment_id
left join legacy.supply_shipments
on supply_shipments.shipment_id = bi_shipments.shipment_id
left join transcribed_mbls
on transcribed_mbls.shipment_id = bi_shipments.shipment_id

where mawb_digitized like 'No'
and transcribed_mbls.shipment_id is null

and shipment_arrival_date is not null
and ((bi_shipments.actual_port_pickup_date > current_timestamp()) or bi_shipments.actual_port_pickup_date is null)
and status < 7
and bi_shipments.client_id NOT IN (11522, 36919, 12441, 14163)


order by
shipment_arrival_date asc