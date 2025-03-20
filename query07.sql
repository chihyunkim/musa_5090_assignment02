-- What are the bottom five neighborhoods?

select
    neighborhood_name,
    accessibility_metric,
    num_bus_stops_accessible,
    num_bus_stops_inaccessible
from phl.neighborhoods_accessibility
order by accessibility_metric, num_bus_stops_accessible
limit 5
