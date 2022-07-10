with HAS_HBL as (

    select
    distinct
    documentable_id as shipment_id
    ,created_ts

    from
    legacy.prep_documents

    where
    lower(documentable_type) like 'shipment'
    and document_type_id in (75, 76, 180, 42, 74, 8) --HBL

)
, has_ci as (
--shipments with CIPL uploaded prior to 7 days before departure date

    select
    distinct
    documentable_id as shipment_id
    --, prep_documents.created_ts
    , prep_documents.document_type_id
    --, rank() OVER(PARTITION BY documentable_id ORDER by prep_documents.created_ts DESC) Rank

    from legacy.prep_documents
    inner join legacy.bi_shipments
        on bi_shipments.shipment_id = prep_documents.documentable_id

    where prep_documents.document_type_id in (5, 66) --commercial invoice, packling list, commercial invoice/packing list
    and prep_documents.created_ts is not null
    --and datediff(day, prep_documents.created_ts,  bi_shipments.arrival_date) > 9
   -- and lower(bi_shipments.transportation_mode_blended_name) like '%ocean%'
    group by 1, 2
)

, completed as (

    select distinct
    messageable_id

    from entities.platform_messages

    where
        (lower(body) like '%#cinetweight%' or lower(body) like '%#cigrossweight%')
        and lower(messageable_type) like 'shipment'

)

select distinct
ifnull(ifnull(BI_SHIPMENTS.ACTUAL_INLAND_PORT_ARRIVAL_DATE, BI_SHIPMENTS.SCHEDULED_INLAND_PORT_ARRIVAL_DATE) , ifnull(BI_SHIPMENTS.ACTUAL_ARRIVAL_DATE, BI_SHIPMENTS.SCHEDULED_ARRIVAL_DATE)
	    )::Date as IMPORT_DATE
, 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as link
,bi_shipments.shipment_id
,dest_address.region as Dest_Region
, origin_address.region as Origin_Region

from legacy.bi_shipments

LEFT JOIN ENTITIES.ADDRESSES as dest_address
		on dest_address.ADDRESS_ID = bi_shipments.DESTINATION_ADDRESS_ID

LEFT JOIN ENTITIES.ADDRESSES as origin_address
		on origin_address.ADDRESS_ID = bi_shipments.ORIGIN_ADDRESS_ID

LEFT JOIN has_ci
    on has_ci.shipment_id = bi_shipments.shipment_id

LEFT JOIN HAS_HBL
    on HAS_HBL.shipment_id = bi_shipments.shipment_id

LEFT JOIN completed
    on completed.messageable_id = bi_shipments.shipment_id

where client_id = 8101
and import_date is not null
and Dest_Region like 'Europe'
and Origin_Region like 'North America'
and HAS_HBL.shipment_id is not null
and has_ci.shipment_id is not null
and completed.messageable_id is null
and IMPORT_DATE > '2022-06-01'
and IMPORT_DATE < CURRENT_DATE + 21

order by 1 asc