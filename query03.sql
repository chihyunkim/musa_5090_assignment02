/*
	Pair each PWD parcel with its closest bus stop
*/

select
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
        order by pwd.geog <-> septa.bus_stops.geog
        limit 1
    ) as nearest_stop
order by distance desc
