/*

Find how many bus routes have stops within 500m of the rail stop

*/


with

-- Get all bus stops within 500m of a rail stop
rail_buffer_bus as (
    select
        rail.stop_id,
        rail.stop_name,
        rail.stop_lon,
        rail.stop_lat,
        bus.stop_id as bus_stop_id
    from septa.rail_stops as rail
    left join septa.bus_stops as bus
        on st_dwithin(rail.geog, bus.geog, 500)
),

-- Get unique routes per stop
bus_stop_info as (
    select distinct times.stop_id, trips.route_id -- noqa: LT09
    from septa.bus_stop_times as times
    left join septa.bus_trips as trips
        on times.trip_id = trips.trip_id
    order by times.stop_id, trips.route_id
),

-- Join rail stops with bus routes and decorate description
rail_bus_routes as (
    select
        rail.stop_id,
        rail.stop_name,
        rail.stop_lon,
        rail.stop_lat,
        coalesce(
            'Nearby bus route transfers: '
            || string_agg(
                distinct bus.route_id, ', '
                order by bus.route_id
            ),
            'No nearby bus transfers'
        ) as stop_desc
    from rail_buffer_bus as rail
    left join bus_stop_info as bus
        on rail.bus_stop_id = bus.stop_id
    group by
        rail.stop_id,
        rail.stop_name,
        rail.stop_lon,
        rail.stop_lat
)

select * from rail_bus_routes
