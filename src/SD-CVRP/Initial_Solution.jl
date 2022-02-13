module Initial_Solution

using CVRP_Structures: Delivery, CvrpData, CvrpAuxiliars, Route, Model, Point, Controller
using CVRP_Controllers: getDistance, pushDelivery!, findBestRoute, fixAssignment!
using Cluster_Instance: predict

# Global variables used to controll solver
SLOT_LENGTH  = 0
SLOT_COUNTER = 0
LAST_SLOT    = false
INSTANCE_LENGTH = 0

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
function greedySolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars, model::Model; slot::Int64=1)

    global SLOT_LENGTH = slot
    global LAST_SLOT = false
    global SLOT_COUNTER = 0
    global INSTANCE_LENGTH = length(instance.deliveries)
    return _greedy_solution(instance, cvrp_auxiliars, model)

end

function _greedy_solution(instance::CvrpData, auxiliar::CvrpAuxiliars, model::Model; solution::Controller{Array{Route,1}} = nothing)

    global SLOT_COUNTER += 1
    local current_slot = SLOT_COUNTER * SLOT_LENGTH

    if (current_slot >= INSTANCE_LENGTH)
        current_slot = INSTANCE_LENGTH
        global LAST_SLOT = true
    end

    local depot = Delivery("DEPOT", instance.origin)
    local deliveries = instance.deliveries[1:current_slot]
    sort!(deliveries, rev = true, alg = MergeSort, by = x -> begin
        instance.capacity / (x.size * getDistance(auxiliar, depot, x))
    end)

    local routes::Array{Route, 1} = solution === nothing ? [] : solution
    foreach(delivery -> begin

        if (!delivery.fixed)
            local centroid::Point = predict(model.centroids, delivery)
            local possible_routes = filter(x -> begin
                return (x.centroid === centroid && x.free - delivery.size >= 0)
            end, routes)

            if (length(possible_routes) == 0)
                local depot    = instance.origin
                local capacity = instance.capacity

                local route = Route(length(routes) + 1, Array{Delivery, 1}(), 0.0, instance.origin, capacity, capacity, centroid)
                pushDelivery!(auxiliar, route, delivery)
                push!(routes, route)

            else
                local route, position = findBestRoute(:Extremes, auxiliar, possible_routes, delivery)
                pushDelivery!(auxiliar, route, delivery, position)
            end
        end

    end, deliveries)

    fixAssignment!(routes, deliveries)

    if (LAST_SLOT)
        return routes
    end

    return _greedy_solution(instance, auxiliar, model; solution = routes)

end


end # module
