/*

With a query, find out how many census block groups
Penn's main campus fully contains.

Discuss which dataset you chose for defining Penn's campus:

1. Take the Philadelphia Universities and Colleges
dataset from opendataphilly
(https://opendataphilly.org/datasets/philadelphia-universities-and-colleges/)
and filter to parcels from University of Pennsylvania
2. Take the Zoning Base Districts dataset from opendataphilly
(https://opendataphilly.org/datasets/zoning-base-districts/)
and filter to zoning group 'Special Purpose'
3. Take the intersection of 1. and 2.
4. Take the concave hull of the union of 3, deleting holes

*/

with

upenn_buildings as (
    select geog
    from phl.universities
    where name = 'University of Pennsylvania'
),

institutional as (
    select geog
    from phl.zoning
    where zoninggroup = 'Special Purpose'
),

upenn_zoning as (
    select
        st_makepolygon(
            st_exteriorring(
                st_concavehull(
                    st_union(upenn_buildings.geog::geometry),
                    0.25
                )
            )
        ) as geom
    from upenn_buildings, institutional
    where st_intersects(upenn_buildings.geog, institutional.geog)
)

select count(*) as count_block_groups
from census.blockgroups_2020 as bgs, upenn_zoning
where st_coveredby(bgs.geog, upenn_zoning.geom::geography)
