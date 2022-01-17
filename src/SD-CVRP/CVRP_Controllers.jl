module CVRP_Controllers

using CVRP_Structures: Point, Delivery, CvrpAuxiliars, Route
using Distances

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

# TODO: Alterar campo route para final da assinatura da função
export pushDelivery!
"""
    pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64 = -1)

Insert delivery `d` into `route` on position `pos`. If `pos` is not defined, it inserts in the last position.
"""
@inline function pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, d::Delivery, pos::Int64 = -1)

    if (d.fixed && route.deliveries[1].route_index != d.route_index)
        throw("Cannot push a fixed delivery into another route. Delivery ID: $(d.id)")
    end

    if (pos == -1)
        pos = length(route.deliveries) + 1
    end

    insert!(route.deliveries, pos, d)
    route.free -= d.size
    d.route_index    = route.index
    d.visiting_index = length(route.deliveries)

    local previous = isassigned(route.deliveries, pos - 1) ? route.deliveries[pos-1] : nothing; # Previous Delivery
    local next = isassigned(route.deliveries, pos + 1) ? route.deliveries[pos+1] : nothing; # Next Delivery
    
    previous !== nothing ? route.distance += getDistance(cvrp_aux, previous, d) : nothing
    next !== nothing ? route.distance += getDistance(cvrp_aux, d, next) : nothing
    
    if (previous !== nothing && next !== nothing) 
        route.distance -= getDistance(cvrp_aux, previous, next)
    end

end

export pushDelivery!
"""
    pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, string::Array{Delivery, 1})

Insert string of delivery into `route` after last position of `route`.
"""
@inline function pushDelivery!(cvrp_aux::CvrpAuxiliars, route::Route, string::Array{Delivery, 1})

    local end_position1   = (route.deliveries[end].id == "DEPOT") ? length(route.deliveries) - 1 : length(route.deliveries)
    local start_position2 = (string[begin].id == "DEPOT") ? 2 : 1
    local end_position2   = (string[end].id == "DEPOT") ? length(string) - 1 : length(string)
    
    foreach(delivery -> begin
        pushDelivery!(cvrp_aux, route, delivery, end_position1 + 1)
        end_position1 += 1
    end, string[start_position2:end_position2])

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
@inline function getInsertionDistance(cvrp_aux::CvrpAuxiliars, route::Route, idx::Int64, string::Array{Delivery, 1})

    # TODO: Criar DEPOT no fim das rotas (automaticamente) e nas funções de inserção, mudar 
    #       para inserir a partir da segunda e até penultima posição

    if (length(string) === 0)
        throw("Empty string.")
    end
    if (length(route.deliveries) === 0)
        throw("Empty route. Route must have at least two depot as deliveries")
    end

    let value = 0

        local predecessor = route.deliveries[idx]
        local neighbor = nothing
        
        if (idx + 1 <= length(route.deliveries))
            neighbor = route.deliveries[idx + 1]
        end

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
        throw("The gap is too big. Route must have at least gap deliveries + two depot deliveries.")
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

end # module