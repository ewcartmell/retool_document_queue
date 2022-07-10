with transcribed_docs as (

select
distinct
  REGEXP_SUBSTR(transcribed_documents.source_doc_fid, '[0-9]+') as shipment_id


from nis_transcription.transcribed_documents

    where document_type ilike '%mbl%'
    or document_type ilike '%hbl%'
    or document_type ilike '%mawb%'
    or document_type ilike '%hawb%'
    or document_type ilike '%arrival%'


  ), transcribed_docs as (

    select
    distinct documentable_id as shipment_id,
    case
      when prep_documents.document_type_id in (115,114, 38) then 'mbl'
      when prep_documents.document_type_id in (75, 76, 180, 42, 74, 8) then 'hbl'
      when prep_documents.document_type_id in (37) then 'mawb'
      when prep_documents.document_type_id in (6) then 'hawb'
      when prep_documents.document_type_id in (7, 146, 93, 86) then 'an'
      when prep_documents.document_type_id in (66, 46) then 'pl'
    end as document_type_shorthand



    from legacy.prep_documents
    inner join transcribed_docs on transcribed_docs.shipment_id = prep_documents.documentable_id

    where
    lower(documentable_type) like 'shipment'
    and document_type_id in (
                           --MASTER BILLS OF LADING
                           115, --Master Bill of Lading [Telex Release]
                           114, --Master Bill of Lading [Endorsed Original]
                           38, --Master Bill of Lading

                           --HOUSE BILLS OF LADING
                           75, --Trucking Bill of Lading
                           76, --Flexport Bill of Lading
                           180, --Flexport Original Bill Of Lading
                           42, --Bill of Lading [Telex Release]
                           74, --Bill of Lading [Endorsed Original]
                           8, --Bill of Lading

                           --MAWB
                           37, --Master Air Waybill

                           --HAWB
                           6, --Air Waybill

                           --PACKING LIST
                           66, --Commercial Invoice / Packing List
                           46, --Packing List

                           --ARRIVAL NOTICES
                           7, --Arrival Notice / Invoice
                           146, --Arrival Notice
                           93, --Inland Arrival Notice
                           86 --Flexport Arrival Notice
                          )

  ),

  hashtag_drop_off as (
  select
  distinct
  messageable_id,
  case
    when platform_messages.body ilike '%#mblnumber%' then 'mbl'
    when platform_messages.body ilike '%#hblnumber%' then 'hbl'
    when platform_messages.body ilike '%#mawbnumber%' then 'mawb'
    when platform_messages.body ilike '%#hawbnumber%' then 'hawb'
    when platform_messages.body ilike '%#annumber%' then 'an'
    when platform_messages.body ilike '%#plcarton%' then 'pl'
  end as document_type_shorthand

  from entities.platform_messages

  where messageable_type like 'shipment'
  and (
    platform_messages.body ilike '%#mblnumber%'
    or platform_messages.body ilike '%#hblnumber%'
    or platform_messages.body ilike '%#mawbnumber%'
    or platform_messages.body ilike '%#hawbnumber%'
    or platform_messages.body ilike '%#annumber%'
    or platform_messages.body ilike '%#plcarton%'
    )



)

, document_shipments as (

  select
  distinct
  documentable_id
  , document_id
  , prep_documents.document_type
  , case
      when prep_documents.document_type_id in (115,114, 38) then 'mbl'
      when prep_documents.document_type_id in (75, 76, 180, 42, 74, 8) then 'hbl'
      when prep_documents.document_type_id in (37) then 'mawb'
      when prep_documents.document_type_id in (6) then 'hawb'
      when prep_documents.document_type_id in (7, 146, 93, 86) then 'an'
      when prep_documents.document_type_id in (66, 46) then 'pl'
    end as document_type_shorthand
  , coalesce(
    shipment_timeline.actual_arrival_port_arrived_at,
    shipment_timeline.scheduled_arrival_port_arrived_at
  )::date as shipment_arrival_date
  , mode

  from legacy.prep_documents
  join entities.shipment_timeline on prep_documents.documentable_id = shipment_timeline.shipment_id
  join entities.shipment_attributes on prep_documents.documentable_id = shipment_attributes.shipment_id

  where documentable_type like 'Shipment'
  and document_type_id in (
                           --MASTER BILLS OF LADING
                           115, --Master Bill of Lading [Telex Release]
                           114, --Master Bill of Lading [Endorsed Original]
                           38, --Master Bill of Lading

                           --HOUSE BILLS OF LADING
                           75, --Trucking Bill of Lading
                           76, --Flexport Bill of Lading
                           180, --Flexport Original Bill Of Lading
                           42, --Bill of Lading [Telex Release]
                           74, --Bill of Lading [Endorsed Original]
                           8, --Bill of Lading

                           --MAWB
                           37, --Master Air Waybill

                           --HAWB
                           6, --Air Waybill

                           --PACKING LIST
                           66, --Commercial Invoice / Packing List
                           46, --Packing List

                           --ARRIVAL NOTICES
                           7, --Arrival Notice / Invoice
                           146, --Arrival Notice
                           93, --Inland Arrival Notice
                           86 --Flexport Arrival Notice
                          )
  and coalesce(
    shipment_timeline.actual_departure_port_departed_at,
    shipment_timeline.scheduled_departure_port_departed_at
  )::date > '2020-08-21'

)

select
shipment_timeline.shipment_id
, document_shipments.document_id
, document_shipments.document_type
, 'https://core.flexport.com/shipments/' || shipment_timeline.shipment_id || '/documents' as shipment_link
, case when hashtag_drop_off.document_type_shorthand is not null then 'Complete' else 'No' end as digitized
, coalesce(
    shipment_timeline.actual_arrival_port_arrived_at,
    shipment_timeline.scheduled_arrival_port_arrived_at
  )::date as shipment_arrival_date

from entities.shipment_attributes
join entities.shipment_timeline on shipment_attributes.shipment_id = shipment_timeline.shipment_id
join document_shipments on document_shipments.documentable_id = shipment_attributes.shipment_id
left join hashtag_drop_off on hashtag_drop_off.messageable_id = shipment_attributes.shipment_id
  and hashtag_drop_off.document_type_shorthand = document_shipments.document_type_shorthand
left join transcribed_docs on transcribed_docs.shipment_id = shipment_attributes.shipment_id

where digitized = 'No'
and transcribed_docs.shipment_id is null
and shipment_arrival_date is not null
and shipment_attributes.completed_at is null
and shipment_attributes.client_id NOT IN (11522, 36919, 12441, 14163)
and shipment_timeline.shipment_id > 1000000


order by
shipment_arrival_date asc

