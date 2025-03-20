-- What are the top five neighborhoods according to your accessibility metric?

select
    neighborhood_name,
    accessibility_metric,
    num_bus_stops_accessible,
    num_bus_stops_inaccessible
from phl.neighborhoods_accessibility
order by accessibility_metric desc, num_bus_stops_accessible desc
limit 5
