/*

With a query involving PWD parcels and census block groups,
find the geo_id of the block group that contains Meyerson Hall.

*/

with

-- The address of Meyerson Hall does not appear in the PWD
-- data, but a similar address covers the same ground
meyerson_ersatz as (
    select geog
    from phl.pwd_parcels
    where address = '220-30 S 34TH ST'
)

select bgs.geoid
from census.blockgroups_2020 as bgs, meyerson_ersatz
where st_intersects(bgs.geog, meyerson_ersatz.geog)
