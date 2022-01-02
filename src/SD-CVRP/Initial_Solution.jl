module Initial_Solution

using CVRP_Structures: Delivery, CvrpData, CvrpAuxiliars, Route, Model, Point
using CVRP_Controllers: getDistance, pushDelivery!, findBestRoute
using Cluster_Instance: predict

export greedySolution
"""
    greedySolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars, model::Model)

Generates a greedy initial solution by first selecting those deliveries with greater `size * distance`.

**Parameters:**
* `instance` - Instance original data
* `cvrp_auxiliars` - Instance auxiliar data
* `model` - Model trained using previous instances (clustered)

**Returns:**
* Array of `Route`, each containing different deliveries to be attended by the route.
"""
function greedySolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars, model::Model)
    
    local routes::Array{Route, 1} = []
    foreach(delivery -> begin

        local centroid::Point = predict(model.centroids, delivery)
        local possible_routes = filter(x -> begin
            return (x.centroid === centroid && x.free - delivery.size >= 0)
        end, routes)

        if (possible_routes === nothing || length(possible_routes) == 0)
            local depot    = instance.origin
            local capacity = instance.capacity
            local free     = capacity - delivery.size

            local route = Route(length(routes) + 1, Array{Delivery, 1}(), 0.0, instance.origin, capacity, capacity, centroid)
            pushDelivery!(cvrp_auxiliars, route, delivery)
            push!(routes, route)

        else
            local route, position = findBestRoute(:Extremes, cvrp_auxiliars, possible_routes, delivery)
            pushDelivery!(cvrp_auxiliars, route, delivery, position)
            
        end
        
    end, instance.deliveries)
    
    return routes

end

end # module