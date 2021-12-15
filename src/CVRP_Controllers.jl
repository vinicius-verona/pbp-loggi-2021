module CVRP_Controllers

using CVRP_Structures: Delivery, CvrpAuxiliars, Route

export getDistance
"""
    getDistance(cvrp_aux::CvrpAuxiliars, a::Delivery, b::Delivery)

Get distance between delivery `d1` and `d2`.
"""
getDistance(cvrp_aux::CvrpAuxiliars, d1::Delivery, d2::Delivery) = cvrp_aux.distance_matrix[d1.index + 1, d2.index + 1]


export pushDelivery!
"""
    pushDelivery!!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64)

Insert delivery `d` into `route` on position `pos`. If `pos` is not defined, it inserts in the last position.
"""
function pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64 = -1)

    if (pos == -1)
        pos = length(route.deliveries) + 1
    end

    insert!(route.deliveries, pos, d)
    route.free -= d.size

    local previous = isassigned(route.deliveries, pos - 1) ? route.deliveries[pos-1] : nothing; # Previous Delivery
    local next = isassigned(route.deliveries, pos + 1) ? route.deliveries[pos+1] : nothing; # Next Delivery
    
    previous !== nothing ? route.distance += getDistance(cvrp_aux, previous, d) : nothing
    next !== nothing ? route.distance += getDistance(cvrp_aux, d, next) : nothing
    
    if (previous !== nothing && next !== nothing) 
        route.distance -= getDistance(cvrp_aux, previous, next)
    end

end

end # module