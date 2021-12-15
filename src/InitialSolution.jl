module InitialSolution

using CVRP_Structures: Delivery, CvrpData, CvrpAuxiliars, Route
using CVRP_Controllers: getDistance, pushDelivery!

export greedySolution
"""
    greedySolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars)

Generates a greedy initial solution by first selecting those deliveries with greater `size * distance`.

**Parameters:**
* `instance` - Instance original data
* `cvrp_auxiliars` - Instance auxiliar data

**Returns:**
* Array of `Route`, each containing different deliveries to be attended by the route.
"""
function greedySolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars)
    
    local routes = Array{Route, 1}(undef, 1)
    routes[1] = Route(1, Array{Delivery, 1}(), 0.0, instance.origin, instance.capacity)

    local depot = Delivery("DEPOT", instance.origin, 0, 0, 1, 1)
    local deliveries = sort(instance.deliveries, alg=MergeSort, rev=true, by = x -> (instance.capacity / x.size * getDistance(cvrp_auxiliars, depot, x)))

    local cnt = 1
    for i in deliveries
        if (routes[cnt].free - i.size >= 0)
            pushDelivery!(cvrp_auxiliars, routes[cnt], i)
        else
            cnt += 1
            push!(routes, Route(cnt, Array{Delivery, 1}(), 0.0, instance.origin, instance.capacity))
            pushDelivery!(cvrp_auxiliars, routes[cnt], i)
        end

    end

    return routes

end

end # module