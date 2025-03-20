/*
  The accessibility metric is defined as the percentage of PWD parcels
  in the neighborhood which has an accessible bus stop within 200 meters.
*/

with

-- Parcels by their distance to nearest accessible bus stop 
-- (assumes no accessibility information is not accessible)
parcels_nearest_accessible_stop as (
    select
        pwd.geog,
        pwd.address as parcel_address,
        nearest_stop.stop_name,
        round(st_distance(pwd.geog, nearest_stop.geog)::numeric, 2) as distance
    from phl.pwd_parcels as pwd
    cross join
        lateral (
            select
                septa.bus_stops.stop_name,
                septa.bus_stops.geog
            from septa.bus_stops
            where septa.bus_stops.wheelchair_boarding = 1
            order by pwd.geog <-> septa.bus_stops.geog
            limit 1
        ) as nearest_stop
    order by distance desc
),

-- Parcels joined to neighborhood
parcels_neighborhoods as (
    select
        parcels.parcel_address,
        parcels.distance,
        nbs.name as neighborhood_name
    from parcels_nearest_accessible_stop as parcels
    left join phl.neighborhoods as nbs
        on st_intersects(
            parcels.geog::geometry, nbs.geog::geometry
        )
),

-- Count of parcels with bus stop accessibility by neighborhood
parcels_accessibility_n as (
    select
        neighborhood_name,
        case
            when distance <= 200 then 'accessible stop'
            else 'no accessible stop'
        end as accessibility_category,
        count(*) as n
    from parcels_neighborhoods
    group by neighborhood_name, accessibility_category
),

-- Percentage of parcels with bus stop accessibility by neighborhood
parcels_accessibility_percent as (
    select
        neighborhood_name,
        accessibility_category,
        n * 100.0 / sum(n) over (partition by neighborhood_name)
        as accessibility_metric
    from parcels_accessibility_n
),

stops_joined as (
    select
        nbs.name as neighborhood_name,
        stops.stop_name,
        stops.wheelchair_boarding
    from
        phl.neighborhoods as nbs
    left join septa.bus_stops as stops
        on st_intersects(
            stops.geog, nbs.geog
        )
),

-- accessible stops in neighborhoods
accessible as (
    select
        neighborhood_name,
        count(*) as num_bus_stops_accessible
    from stops_joined
    where wheelchair_boarding = 1
    group by neighborhood_name
),

-- inaccessible stops in neighborhoods
inaccessible as (
    select
        neighborhood_name,
        count(*) as num_bus_stops_inaccessible
    from stops_joined
    where wheelchair_boarding != 1
    group by neighborhood_name
),

neighborhood_summary as (
    select
        neighborhood_name,
        coalesce(accessible.num_bus_stops_accessible, 0) as num_bus_stops_accessible,
        coalesce(inaccessible.num_bus_stops_inaccessible, 0) as num_bus_stops_inaccessible
    from inaccessible
    full join accessible using (neighborhood_name)
),

-- Final table
output_ready as (
    select
        parcels.neighborhood_name,
        parcels.accessibility_metric,
        summarytable.num_bus_stops_accessible,
        summarytable.num_bus_stops_inaccessible,
        parcels.accessibility_category
    from parcels_accessibility_percent as parcels
    left join neighborhood_summary as summarytable using (neighborhood_name)
    where parcels.accessibility_category = 'accessible stop'

)

-- Save table
select
    neighborhood_name,
    accessibility_metric,
    num_bus_stops_accessible,
    num_bus_stops_inaccessible
into phl.neighborhoods_accessibility
from output_ready
