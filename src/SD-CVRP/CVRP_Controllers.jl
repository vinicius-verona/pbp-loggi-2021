module CVRP_Controllers

using CVRP_Structures: Point, Delivery, CvrpAuxiliars, Route
using Distances

export fixAssignment!
"""
    fixAssignment!(routes::Array{Route, 1}, deliveries::Array{Delivery, 1})

Set each `delivery` in `deliveries` and `routes` as fixed to its assigned route.
"""
function fixAssignment!(routes::Array{Route, 1}, deliveries::Array{Delivery, 1})

    foreach(route -> begin
        map(delivery -> begin
            delivery.fixed = true
            
            if (!occursin(lowercase(delivery.id), "depot"))
                deliveries[delivery.index].fixed = true
            end
        end, route.deliveries)
    end, routes)

end

export getDistance
"""
    getDistance(cvrp_aux::CvrpAuxiliars, a::Delivery, b::Delivery)::Float64

Get distance between delivery `d1` and `d2`.
"""
getDistance(cvrp_aux::CvrpAuxiliars, d1::Delivery, d2::Delivery)::Float64 = cvrp_aux.distance_matrix[d1.index + 1, d2.index + 1]

export getDistance
"""
    getDistance(p1::Point, p2::Point)::Float64

Using [haversine](https://en.wikipedia.org/wiki/Haversine_formula) formula, calculates distance between `p1` and `p2`.
"""
getDistance(p1::Point, p2::Point)::Float64 = haversine((p1.lng, p1.lat), (p2.lng, p2.lat))

export pushDelivery!
"""
    pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64 = -1)

Insert delivery `d` into `route` on position `pos`. If `pos` is not defined, it inserts in the last position.
"""
@inline function pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64 = -1)

    # if (d.fixed && route.index != d.route_index)
    #     throw("Cannot push a fixed delivery into another route. Delivery ID: $(d.id)")
    # end

    if (pos == -1)
        pos = length(route.deliveries)
    end

    insert!(route.deliveries, pos, d)
    route.free -= d.size
    d.route_index    = route.index
    d.visiting_index = pos

    local previous = isassigned(route.deliveries, pos - 1) ? route.deliveries[pos-1] : nothing; # Previous Delivery
    local next = isassigned(route.deliveries, pos + 1) ? route.deliveries[pos+1] : nothing; # Next Delivery
    
    previous !== nothing ? route.distance += getDistance(cvrp_aux, previous, d) : nothing
    next !== nothing ? route.distance += getDistance(cvrp_aux, d, next) : nothing
    
    if (previous !== nothing && next !== nothing) 
        route.distance -= getDistance(cvrp_aux, previous, next)
    end

    local counter = pos+1
    for i = pos+1:length(route.deliveries)
        route.deliveries[i].visiting_index = counter
        counter += 1
    end

end

export pushDelivery!
"""
    pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, string::Array{Delivery, 1})

Insert string of delivery into `route` after last position of `route`.
"""
@inline function pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, string::Array{Delivery, 1}, start::Int64 = -1)

    local start_position = (string[begin].id == "DEPOT") ? 2 : 1
    local end_position   = (string[end].id == "DEPOT") ? length(string) - 1 : length(string)

    if (start !== -1)
        foreach(delivery -> begin
            pushDelivery!(cvrp_aux, route, delivery, start)
            start += 1
        end, string[start_position:end_position])
    
    else
        foreach(delivery -> begin
            pushDelivery!(cvrp_aux, route, delivery)
        end, string[start_position:end_position])
    end


end

export deleteDelivery!
"""
    deleteDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, limit::Int64)

Remove the selected string of deliveries from `route`. The string starts at `idx` and ends at `limit`
"""
@inline function deleteDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, limit::Int64)

    if (idx < 1)
        throw("Passed argument is out of bound. IDX: $idx is not a valid value.")
    end

    if (limit > length(route.deliveries))
        throw("Passed argument is out of bound. Limit: $limit is not a valid value. | Length of route: $(length(route.deliveries)) | Limit: $limit")
    end

    if (length(findall(x -> x.fixed === true, route.deliveries[idx:limit])) > 0)
        @warn "Removing fixed deliveries from route."
    end

    route.free += getStringSize(route.deliveries[idx:limit])

    if (isassigned(route.deliveries, idx - 1) && isassigned(route.deliveries, limit + 1))
        route.distance += getDistance(cvrp_aux, route.deliveries[idx - 1], route.deliveries[limit + 1])
    end
    
    route.distance -= getStringDistance(cvrp_aux, route.deliveries[idx:limit])
    deleteat!(route.deliveries, idx:limit)

    # Update indexers
    local counter = 1
    for i in route.deliveries
        i.visiting_index = counter
        counter += 1
    end

end

export insertRoute!
"""
    insertRoute!(route::Route, idx::Int64, routes::Array{Route,1})

Insert a route on index `idx` from `routes`.
"""
@inline function insertRoute!(route::Route, idx::Int64, routes::Array{Route,1})

    insert!(routes, idx, route)

    for i = idx:length(routes)
        routes[i].index = i

        for j in routes[i].deliveries
            j.route_index = i
        end
    end

end

export deleteRoute!
"""
    deleteRoute!(idx::Int64, routes::Array{Route,1})

Delete a route on index `idx` from `routes`.
"""
@inline function deleteRoute!(idx::Int64, routes::Array{Route,1})

    if (!isassigned(routes, idx))
        throw("Routes does not have route with idx equals to $idx.")
    end

    deleteat!(routes, idx)

    for i = idx:length(routes)
        routes[i].index = i

        for j in routes[i].deliveries
            j.route_index = i
        end
    end

end


export getStringDistance
"""
    getStringDistance(cvrp_aux::CvrpAuxiliars, string::Array{Delivery, 1})

For a given sub-route (`string`), returns the string total distance.
"""
function getStringDistance(cvrp_aux::CvrpAuxiliars, string::Array{Delivery, 1})

    local value = 0
    local idx   = 0
    
    for idx = 1 : length(string) - 1
        value += getDistance(cvrp_aux, string[idx], string[idx + 1])
    end

    return value
    
end

export getStringSize
"""
    getStringSize(string::Array{Delivery, 1})

For a given sub-route (`string`), returns the string total size.
"""
function getStringSize(string::Array{Delivery, 1})

    local value = 0
    local idx   = 0
        
    for idx = 1 : length(string) - 1
        value += string[idx].size
    end

    return value

end


export getInsertionDistance
"""
    getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, string::Array{Delivery, 1})

For a given string, return insertion distance for inserting the string of size into `route` starting in `idx`.
If returned value is positive, the insertion is not profitable.
"""
@inline function getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, string::Array{Delivery, 1})

    if (length(string) === 0)
        throw("Empty string.")
    end
    if (length(route.deliveries) === 0)
        throw("Empty route. Route must have at least two depot as deliveries")
    end

    let value = 0

        local predecessor = route.deliveries[idx-1]
        local neighbor    = route.deliveries[idx]

        value += getDistance(cvrp_aux, predecessor, string[begin])
        
        if (length(string) > 1)
            value += getStringDistance(cvrp_aux, string)
        end
        
        if (neighbor !== nothing)
            value -= getDistance(cvrp_aux, predecessor, neighbor)
            value += getDistance(cvrp_aux, string[end], neighbor)
        end

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
@inline function getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, gap::Int64, string::Array{Delivery, 1})

    if (length(string) === 0)
        throw("Empty string.")
    end
    if (length(route.deliveries) === 0)
        throw("Empty route. Route must have at least two depot as deliveries")
    end
    if (length(route.deliveries) < gap)
        throw("The gap is too big. Route must have at least $gap deliveries + two depot deliveries.")
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
@inline function getRemovalDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, length::Int64)

    if (idx === 1)
        throw("DEPOT selected in string.")
    end
    if (length(route.deliveries) === 0)
        throw("Empty route.")
    end
    if (length(route.deliveries) < length)
        throw("The string length is too big. Route must have at least length deliveries + two depot deliveries.")
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

export findBestRoute
"""
    findBestRoute(type::Symbol, cvrp_auxiliar::CvrpAuxiliars, routes::Array{Route, 1}, delivery::Delivery)
For a given search type (`:Extremes`, for example), find best route among `routes`
to insert `delivery`.

**Types:**
* `:Extremes` - Check both extremes insertion cost of a route.
"""
findBestRoute(type::Symbol, cvrp_auxiliar::CvrpAuxiliars, routes::Array{Route, 1}, delivery::Delivery) = type == :Extremes ? 
    findBestRoute(Val(:Extremes), cvrp_auxiliar, routes, delivery) :
    nothing # findBestRoute(Val(:FullRoute), cvrp_auxiliar, routes, delivery)

"""
For the `:Extremes` analysis, for each route, the desired delivery is compared to be inserted either as 
the first serviced customer or the last.
"""
@inline function findBestRoute(::Val{:Extremes}, cvrp_auxiliar::CvrpAuxiliars, routes::Array{Route, 1}, delivery::Delivery)

    local route = nothing
    local position = 0
    local distance = typemax(Float64)
    foreach(r -> begin

        if (r.free - delivery.size >= 0)
        
            # Depot -> new delivery
            local dist = getDistance(cvrp_auxiliar, r.deliveries[1], delivery)
            if (dist < distance)
                distance = dist
                position = 2
                route = r
            end

            # Last delivery in route -> new delivery
            dist = getDistance(cvrp_auxiliar, r.deliveries[end], delivery)
            if (dist < distance)
                distance = dist
                position = length(r.deliveries) + 1
                route = r
            end
        
        end

    end, routes)

    return route, position

end

export getClosestRoute
"""
    getClosestRoute(cvrp_auxiliar::CvrpAuxiliars, deliveries::Array{delivery, 1}, routes::Array{Route, 1}, delivery::Delivery)

For a given delivery, find the closest route which has enough space to have `delivery` inserted into.

**Returns:**
* The position of the closest route.
"""
@inline function getClosestRoute(cvrp_auxiliar::CvrpAuxiliars, deliveries::Array{Delivery, 1}, routes::Array{Route, 1}, delivery::Delivery)

    foreach(d -> begin
        for tuple in d

            if (!isassigned(deliveries, tuple.second))
                continue
            end
        
            local dlvr = deliveries[tuple.second]
            if (dlvr.route_index !== 0 && routes[dlvr.route_index].free - delivery.size >= 0)
                if (dlvr.route_index !== delivery.route_index)
                    return dlvr.route_index
                end
            end

        end
    end, cvrp_auxiliar.k_adjacent)

    return typemax(Int64)

end

export getBestInsertionPosition
"""
    getBestInsertionPosition(cvrp_auxiliar::CvrpAuxiliars, route::Route, delivery::Delivery)

For a given delivery and route, find the best position to insert the delivery into the route.

**Returns:**
* The position in which `delivery` shall be inserted.
"""
@inline function getBestInsertionPosition(cvrp_auxiliar::CvrpAuxiliars, route::Route, delivery::Delivery)

    local position = typemax(Int64)
    local distance = typemax(Float64)
    
    for i = 1 : length(route.deliveries) - 1
        local local_distance = getDistance(cvrp_auxiliar, route.deliveries[i], delivery)

        if (local_distance < distance)
            distance = local_distance
            position = i
        end
    end

    return position

end


export copyRoute
"""
    copyRoute(source::Array{Route, 1})

For a given set of routes, create a copy and return it.
"""
@inline function copyRoute(source::Array{Route, 1})

    local size = length(source)
    local routes = Array{Route, 1}(undef, size)

    for i = 1:size
        routes[i] = copyRoute(source[i])
    end

    return routes

end

export copyRoute
"""
    copyRoute(source::Route)

For a given route, create a copy and return it.
"""
@inline function copyRoute(source::Route)
    
    local length::Int64 = length(source.deliveries)
    local index::Int64  = source.index
    local deliveries::Array{Delivery, 1} = Array{Delivery, 1}(undef, length)
    local distance::Float64 = source.distance
    local depot::Delivery   = source.depot
    local capacity::Int64   = source.capacity
    local free::Int64       = source.free
    local centroid::Point   = source.centroid

    for i = 1:length
        deliveries[i] = copyDelivery(source.deliveries[i])
    end

    return Route(index, deliveries, distance, depot, capacity, free, centroid)
    
end

export copyDelivery
"""
    copyDelivery(source::Delivery)

For a given delivery, create a copy and return it.
"""
@inline function copyDelivery(source::Delivery)
    
    local id::String   = source.id
    local point::Point = source.point
    local size::Int64  = source.size
    local index::Int64 = source.index
    local visiting_index::Int64 = source.visiting_index
    local route_index::Int64    = source.route_index
    local fixed::Bool = source.fixed


    return Delivery(id, point, size, index, visiting_index, route_index, fixed)

end

export copyRoute!
"""
    copyRoute!(source::Array{Route, 1}, deliveries::Array{Delivery, 1}, destiny::Array{Route, 1})

For a given set of routes `source`, copy it to `destiny`.
In this context, deliveries must be the one to be synced to destiny.
"""
@inline function copyRoute!(source::Array{Route, 1}, deliveries::Array{Delivery, 1}, destiny::Array{Route, 1})

    local size = length(source)

    for i = 1:size
        if (isassigned(destiny, i))
            copyRoute!(source[i], deliveries, destiny[i])
        else
            local route = Route(i, Array{Delivery,1}(undef, length(source[i].deliveries)), 0.0, source[i].depot)
            copyRoute!(source[i], deliveries, route)
            push!(destiny, route)
        end
    end

end

export copyRoute!
"""
    copyRoute!(source::Route, deliveries::Array{Delivery, 1}, destiny::Route)

For a given route `source`, copy it to `destiny`.
In this context, deliveries must be the one to be synced to destiny.
"""
@inline function copyRoute!(source::Route, deliveries::Array{Delivery, 1}, destiny::Route)
    
    local size = length(source.deliveries)
    
    destiny.index    = source.index
    destiny.distance = source.distance
    destiny.depot    = source.depot
    destiny.capacity = source.capacity
    destiny.free     = source.free
    destiny.centroid = source.centroid

    for i = 2:size - 1
        local idx = source.deliveries[i].index
        if (isassigned(destiny.deliveries, i))
            destiny.deliveries[i] = deliveries[idx]
        else
            push!(destiny.deliveries, deliveries[idx])
        end

        deliveries[idx].visiting_index = i
        deliveries[idx].route_index = destiny.index
    end

    if (length(destiny.deliveries) - 1 > length)
        while (isassigned(destiny.deliveries, length + 1))
            deleteat!(destiny.deliveries, length + 1)
        end

    elseif (length(destiny.deliveries) < length)
        push!(destiny.deliveries, copyDelivery(source.deliveries[1]))
    end

    destiny.deliveries[length].visiting_index = length

    if (length(destiny.deliveries) !== length || destiny.deliveries[1].id != source.deliveries[1].id || destiny.deliveries[end].id != source.deliveries[end].id)
        throw("Error on copyRoute!(source::Route, deliveries::Array{Delivery, 1}, destiny::Route)")
    end

end

export copyDelivery!
"""
    copyDelivery!(source::Delivery)

For a given delivery `source`, copy info into `destiny`.
"""
@inline function copyDelivery!(source::Delivery, destiny::Delivery)
    
    destiny.id    = source.id
    destiny.point = source.point
    destiny.size  = source.size
    destiny.index = source.index
    destiny.fixed = source.fixed
    destiny.visiting_index = source.visiting_index
    destiny.route_index    = source.route_index

end

end # module