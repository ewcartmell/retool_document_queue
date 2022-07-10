with cte_shipment_firms as (
select
  distinct
  legs.shipment_id,
  prep_addresses.firms_code as firms_code

from entities.legs
join legacy.prep_addresses on legs.destination_address_id = prep_addresses.address_id
  where
    array_contains('to port of entry'::variant, legs.to_node_types)

)

, completed_drop_off as (

SELECT
  messageable_id as shipment_id
  ,created_ts

FROM entities.platform_messages

  where
  lower(body) like '%#airfirms:%'

)

select
distinct

ifnull(BI_SHIPMENTS.ACTUAL_ARRIVAL_DATE, BI_SHIPMENTS.SCHEDULED_ARRIVAL_DATE)::DATE as Port_Arrival_Date
  ,bi_shipments.shipment_id as Flex_ID
  , 'https://core.flexport.com/shipments/' || bi_shipments.shipment_id || '/documents' as link
  , bi_shipments.transportation_mode_blended_name
  , PREP_SHIPMENT_LOCATION_HIERARCHY.final_port as IMPORT_PORT
  , ADDRESSES.REGION

FROM LEGACY.PREP_SHIPMENT_LEGS

LEFT JOIN LEGACY.BI_SHIPMENTS
  on bi_shipments.shipment_id = PREP_SHIPMENT_LEGS.shipment_id

LEFT JOIN ENTITIES.ADDRESSES
	on ADDRESSES.ADDRESS_ID = bi_shipments.DESTINATION_ADDRESS_ID

LEFT JOIN LEGACY.PREP_SHIPMENT_LOCATION_HIERARCHY
  on BI_SHIPMENTS.SHIPMENT_ID = PREP_SHIPMENT_LOCATION_HIERARCHY.SHIPMENT_ID

LEFT JOIN cte_shipment_firms
  on cte_shipment_firms.shipment_id = bi_shipments.shipment_id

LEFT JOIN completed_drop_off
    on completed_drop_off.shipment_id = BI_SHIPMENTS.shipment_id


where
lower(bi_shipments.transportation_mode_blended_name) like '%air%'
AND completed_drop_off.shipment_id is null
AND lower(ADDRESSES.REGION) like 'north america'
AND lower(PREP_SHIPMENT_LOCATION_HIERARCHY.final_port) not like '%canada'
AND cte_shipment_firms.firms_code is null
and ((bi_shipments.wants_flexport_freight = 'TRUE')
    OR (bi_shipments.wants_bco = 'TRUE')) --filters out customs only
and Port_Arrival_Date > CURRENT_DATE - 5
and Port_Arrival_Date < CURRENT_DATE + 4

order by 1 asc