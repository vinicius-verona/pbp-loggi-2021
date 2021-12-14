module InitialSolution

using CVRP_Structures: Delivery, CvrpData, CvrpAuxiliars, Route

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

    local deliveries = sort(instance.deliveries, alg=MergeSort, rev=true, by = x -> (instance.capacity / x.size * getDistance(cvrp_auxiliars, depot, x)))

    local routes = Array{Route, 1}(undef, 1)
    routes[1] = Route(1, _, _, instance.origin, instance.capacity)

    local cnt = 1
    for i in deliveries
        if (routes[cnt].free - i.size >= 0)
            pushDelivery!(cvrp_auxiliars, routes[cnt], i)
        else
            push!(routes, Route(cnt+1 , _, _, instance.origin, instance.capacity))
            pushDelivery!(cvrp_auxiliars, routes[cnt], _, i)
        end

        cnt += 1
    end

    return routes

end

end # module