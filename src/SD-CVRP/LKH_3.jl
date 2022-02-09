module LKH_3

using LKH
using CVRP_Structures: Route, CvrpAuxiliars, Delivery
using CVRP_Controllers: getStringDistance, getDistance

"""

For a given route, the visiting order and its possible variants are transformed into a TSP problem to execute the LKH algorithm

**Parameters:**
* `route` - Route used to generate the TSP matrix
* `cvrp`  - Problem data
"""
function generateTSP(route::Route, cvrp::CvrpAuxiliars)

    # Generate config for LKH
    local distances = zeros(Int64, length(route.deliveries) - 1, length(route.deliveries) - 1)
    for i in 1:length(route.deliveries) - 1 # As both first and last position are DEPOT, the last is not necessary
        for j in i+1:length(route.deliveries) - 1
            distances[i, j] = Int(round(getDistance(cvrp, route.deliveries[i], route.deliveries[j]), RoundUp))
            distances[j, i] = Int(round(getDistance(cvrp, route.deliveries[j], route.deliveries[i]), RoundUp))
        end
    end

    return distances

end

"""

For a given executed move, all routes altered are improved by applying the LKH algorithm.

**Parameters:**
* `move` - Move previously executed, e.g `InterRouteNDInsertion`
"""
function executeLKH(route::Route, cvrp::CvrpAuxiliars)

    local route_matrix = generateTSP(route, cvrp)
    local optimal_tour, _ = solve_tsp(route_matrix)

    return optimal_tour

end


export lkh
"""

For all routes in the given solution, apply LKH to the the route. Then, the total distance is calculated and if it is better, it updates the route.

**Parameters:**
* `routes` - The chosen route for LKH
* `cvrp` - Problem data gathered from the input JSON
"""
function lkh(routes::Array{Route, 1}, cvrp::CvrpAuxiliars)

    for r in routes
        if length(r.deliveries) <= 2
            continue
        end

        local lkh_result = executeLKH(r, cvrp)
        local deliveries = Array{Delivery, 1}(undef, length(r.deliveries))

        # Find hub in tour
        local hub_position = findfirst(x->x == 1, lkh_result)

        local counter = 1
        for i = hub_position:length(lkh_result)
            if lkh_result[i] != -1
                local original_position = lkh_result[i]

                if (r.deliveries[original_position].index != 0)
                    local idx = counter
                    deliveries[idx] = r.deliveries[original_position]
                    deliveries[idx].visiting_index = idx

                elseif (i == hub_position)
                    deliveries[1] = r.deliveries[original_position]
                    deliveries[1].visiting_index = 1
                end
            end

            counter += 1
        end

        if (hub_position != 1)
            for i = 1:hub_position
                if lkh_result[i] != -1
                    local original_position = lkh_result[i]

                    if (r.deliveries[original_position].index != 0)
                        local idx = counter
                        deliveries[idx] = r.deliveries[original_position]
                        deliveries[idx].visiting_index = idx

                    elseif (i == hub_position)
                        deliveries[end] = r.deliveries[original_position]
                        deliveries[end].visiting_index = length(deliveries)
                    end
                end
                counter += 1
            end
        end

        deliveries[end] = r.deliveries[end]
        local dist = getStringDistance(cvrp, deliveries)

        # Compare distances in order to apply or reject
        if dist < r.distance
            r.distance = dist
            r.deliveries = deliveries
        end
    end

    return routes

end

end # module
