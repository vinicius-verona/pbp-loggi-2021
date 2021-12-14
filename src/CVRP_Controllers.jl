module CVRP_Controllers

using CVRP_Structures: Delivery, CvrpAuxiliars, Route

export getDistance
"""
    getDistance(cvrp_aux::CvrpAuxiliars, a::Delivery, b::Delivery)

Get distance between delivery `d1` and `d2`.
"""
getDistance(cvrp_aux::CvrpAuxiliars, d1::Delivery, d2::Delivery) = cvrp_aux.distance_matrix[d1.index + 1, d2.index + 1]


export pushDelivery!
function pushDelivery!!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64 = -1)

    if (pos != -1)
        pos = length(route.deliveries)
    end

    insert!(route.deliveries, pos, d)

    # local previous = 0; # Previous Delivery
    # local next = 0; # Next Delivery
    # route.free -= getDistance(cvrp_aux, route.deliveries[pos])

end

end # module