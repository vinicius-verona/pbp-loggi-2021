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
    pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64 = -1)

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


export getStringDistance
"""
    getStringDistance(cvrp_aux::CvrpAuxiliars, string::Array{Delivery, 1})

For a given sub-route (`string`), returns the string total distance.
"""
function getStringDistance(cvrp_aux::CvrpAuxiliars, string::Array{Delivery, 1})

    let value = 0, idx = 0
        
        for idx = 1 : length(string) - 1
            value += getDistance(cvrp_aux, string[idx], string[idx + 1])
        end

        return value
        
    end
    
end


export getInsertionDistance
"""
    getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, string::Array{Delivery, 1})

For a given string, return insertion distance for inserting the string of size into `route` starting in `idx`.
If returned value is positive, the insertion is not profitable.
"""
function getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, string::Array{Delivery, 1})

    if (length(string) === 0)
        throw("Empty string.")
    end
    if (length(route.deliveries) === 0)
        throw("Empty route. Route must have at leat two depot as deliveries")
    end

    let value = 0

        local predecessor = route.deliveries[idx]
        local neighbor = route.deliveries[idx + 1]

        value -= getDistance(cvrp_aux, predecessor, neighbor)
        value += getDistance(cvrp_aux, predecessor, string[begin])
        value += getStringDistance(cvrp_aux, string)
        value += getDistance(cvrp_aux, string[end], neighbor)

        return value

    end

end


export getInsertionDistance
"""
    getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, gap::Int64, string::Array{Delivery, 1})

For a given string, return insertion distance for inserting the string of size into `route` starting in `idx`
and disconsidering the next `gap` deliveries after `idx`.
If returned value is positive, the insertion is not profitable.
"""
function getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, gap::Int64, string::Array{Delivery, 1})

    if (length(string) === 0)
        throw("Empty string.")
    end
    if (length(route.deliveries) === 0)
        throw("Empty route. Route must have at leat two depot as deliveries")
    end
    if (length(route.deliveries) < gap)
        throw("The gap is too big. Route must have at leat gap deliveries + two depot deliveries.")
    end

    let value = 0

        local predecessor = route.deliveries[idx]
        local neighbor = route.deliveries[idx + gap]

        value -= getDistance(cvrp_aux, predecessor, neighbor)
        value += getDistance(cvrp_aux, predecessor, string[begin])
        value += getStringDistance(cvrp_aux, string)
        value += getDistance(cvrp_aux, string[end], neighbor)

        return value

    end

end


export getRemovalDistance
"""
    getRemovalDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, length::Int64)

For a given route, return removal distance for string of size `length` starting in `idx`.
If returned value is negative, the removal is not profitable.
"""
function getRemovalDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, length::Int64)

    if (idx === 1)
        throw("DEPOT selected in string.")
    end
    if (length(route.deliveries) === 0)
        throw("Empty route.")
    end
    if (length(route.deliveries) < length)
        throw("The string length is too big. Route must have at leat length deliveries + two depot deliveries.")
    end

    let value = 0

        local predecessor = route.deliveries[idx - 1]
        local neighbor = route.deliveries[idx + length]

        value += getStringDistance(cvrp_aux, route.deliveries[idx : idx + length - 1])
        value -= getDistance(cvrp_aux, predecessor, neighbor)
        value += getDistance(cvrp_aux, predecessor, route.deliveries[idx])
        value += getDistance(cvrp_aux, route.deliveries[idx + length - 1], neighbor)

        return value

    end

end

end # module