module ClarkeWright

using CVRP_Structures: Delivery, CvrpData, CvrpAuxiliars, Route, Point
using CVRP_Controllers: getInsertionDistance, getDistance, pushDelivery!, deleteRoute!

struct Savings

    from::Delivery # -> Delivery used to calculate the savings s(i,j) -> i
    to::Delivery   # -> Delivery used to calculate the savings s(i,j) -> j
    savings::Float64 # s(i,j) = d(D,i) + d(D,j) - d(i,j)
                     # * Where d(i,j) is equal to the distance between nodes 'i' and 'j';
                     # * D -> origin depot (hub)

end

export clarkeWrightSolution
"""
    clarkeWrightSolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars)

For a given instance data, apply Clarke-Wright constructive heuristic
adapted to the dynamic version of CVRP (DCVRP).

**Parameters:**
* `instance` - Instance original data
* `cvrp_auxiliars` - Instance auxiliar data
* `slot` - Number of deliveries considered to generate a initial solution

**Returns:**
* Array of `Route`, each containing different deliveries to be attended by the route.
"""
function clarkeWrightSolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars, slot::Int64=10)

    local routes::Array{Route, 1} = []
    local pairs = getPairs(instance, cvrp_auxiliars, slot) # Get combination pairs of deliveries on slot
    sort!(pairs, alg = MergeSort, by = x -> x.savings, rev = true)

    for p in pairs

        local in_route = p.from.route_index !== 0 || p.to.route_index !== 0

        if (in_route)
            insertPair!(:Merge, instance, cvrp_auxiliars, p, routes)
        else
            insertPair!(:New, instance, cvrp_auxiliars, p, routes)
        end

    end

    return routes

end

"""
    insertPair(type::Symbol, cvrp_auxiliar::CvrpAuxiliars, pair::Savings, routes::Array{Route, 1})

For a given pair of delivery, insert it into a pair by either `:Merge` (mergin existing routes) or `:New` (creating new routes).
"""
insertPair!(type::Symbol, instance::CvrpData, cvrp_auxiliar::CvrpAuxiliars, pair::Savings, routes::Array{Route, 1}) = type == :Merge ? 
    insertPair!(Val(:Merge), instance, cvrp_auxiliar, pair, routes) :
    insertPair!(Val(:New), instance, cvrp_auxiliar, pair, routes)

function insertPair!(::Val{:Merge}, instance::CvrpData, cvrp_auxiliar::CvrpAuxiliars, pair::Savings, routes::Array{Route, 1})

    local first_assignment  = pair.from.route_index
    local second_assignment = pair.to.route_index

    if (first_assignment !== 0 && second_assignment !== 0 && first_assignment !== second_assignment)
        if (routes[first_assignment].free - (instance.capacity - routes[second_assignment].free) >= 0)
            concatRoutes!(cvrp_auxiliar, routes[first_assignment], routes[second_assignment], pair, routes)
        end

    elseif (second_assignment === 0 && first_assignment !== 0 && routes[first_assignment].free - pair.to.size >= 0)
        concatRoutes!(cvrp_auxiliar, routes[first_assignment], pair.to, pair)

    elseif (first_assignment === 0 && second_assignment !== 0 && routes[second_assignment].free - pair.from.size >= 0)
        concatRoutes!(cvrp_auxiliar, routes[second_assignment], pair.from, pair)    
    end

end

"""
For the `:New` type, create a new route, insert both deliveries belonging to `pair` and push it to routes array.
"""
function insertPair!(::Val{:New}, instance::CvrpData, cvrp_auxiliar::CvrpAuxiliars, pair::Savings, routes::Array{Route, 1})

    local depot    = instance.origin
    local capacity = instance.capacity
    local route    = Route(length(routes) + 1, Array{Delivery, 1}(), 0.0,
                           depot, capacity, capacity, depot)

    pushDelivery!(cvrp_auxiliar, route, pair.from)
    pushDelivery!(cvrp_auxiliar, route, pair.to)
    push!(routes, route)

end

"""
    concatRoutes!(first_route::Route, second_route::Route, pair::Savings, routes::Array{Route, 1})

Insert or concat routes/deliveries accordingly to Clarke-Wright merging/insertion rules.
See: [Clarke-Wright Algorithm](https://web.mit.edu/urban_or_book/www/book/chapter6/6.4.12.html#:~:text=By%20far%20the%20best%2Dknown,of%20the%20n%20demand%20points.)
"""
function concatRoutes!(cvrp_aux::CvrpAuxiliars, first_route::Route, second_route::Route, pair::Savings, routes::Array{Route, 1})

    #= 
       This concatanation route+route can only happen if both deliveries 
       in the pair belongs to different routes and are adjacent to the depot.
    =#
    local start_position1 = (first_route.deliveries[begin].id == "DEPOT") ? 2 : 1
    local end_position1   = (first_route.deliveries[end].id == "DEPOT") ? length(first_route.deliveries) - 1 : length(first_route.deliveries)
    local start_position2 = (second_route.deliveries[begin].id == "DEPOT") ? 2 : 1
    local end_position2   = (second_route.deliveries[end].id == "DEPOT") ? length(second_route.deliveries) - 1 : length(second_route.deliveries)
    
    local adjacent1 = false
    local adjacent2 = false
    if (pair.from.visiting_index === start_position1 || pair.from.visiting_index === end_position1)
        adjacent1 = true
    end
    if (pair.to.visiting_index === start_position2 || pair.to.visiting_index === end_position2)
        adjacent2 = true
    end

    if (!adjacent1 || !adjacent2)
        return
    end

    local r1r2 = getInsertionDistance(cvrp_aux, first_route, end_position1, second_route.deliveries[start_position2:end_position2])
    local r2r1 = getInsertionDistance(cvrp_aux, second_route, end_position2, first_route.deliveries[start_position1:end_position1])
    
    if (r1r2 <= r2r1)
        # Insert r2 string to r1
        pushDelivery!(cvrp_aux, first_route, second_route.deliveries[start_position2:end_position2])
        deleteRoute!(second_route.index, routes)
    else
        # Insert r1 string to r2
        pushDelivery!(cvrp_aux, second_route, first_route.deliveries[start_position1:end_position1])
        deleteRoute!(first_route.index, routes)
    end

end

"""
    concatRoutes!(route::Route, delivery::Delivery, pair::Savings)

Insert or concat routes/deliveries accordingly to Clarke-Wright merging/insertion rules.
See: [Clarke-Wright Algorithm](https://web.mit.edu/urban_or_book/www/book/chapter6/6.4.12.html#:~:text=By%20far%20the%20best%2Dknown,of%20the%20n%20demand%20points.)
"""
function concatRoutes!(cvrp_aux::CvrpAuxiliars, route::Route, delivery::Delivery, pair::Savings)

    #= 
       This concatanation route+pair can only happen if one of the deliveries 
       in the pair belongs to the route and are adjacent to the depot.
    =#
    local start_position = (route.deliveries[begin].id == "DEPOT") ? 2 : 1
    local end_position   = (route.deliveries[end].id == "DEPOT") ? length(route.deliveries) - 1 : length(route.deliveries)
    local delivery_in_route = (delivery === pair.from) ? pair.to : pair.from
    local adjacent = false

    if (delivery_in_route.visiting_index === start_position || delivery_in_route.visiting_index === end_position)
        adjacent = true
    end

    if (!adjacent)
        return
    end

    local dij = getInsertionDistance(cvrp_aux, route, delivery_in_route.visiting_index, [delivery])
    local dji = getInsertionDistance(cvrp_aux, route, delivery_in_route.visiting_index, [delivery])

    if (dij <= dji)
        pushDelivery!(cvrp_aux, route, delivery, delivery_in_route.visiting_index)
    elseif (dji < dij)
        pushDelivery!(cvrp_aux, route, delivery, delivery_in_route.visiting_index + 1)
    end

end

"""
    getPairs(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars, slot::Int64)

For a given slot, generate all possible combination of deliveries.
"""
function getPairs(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars, slot::Int64)

    local savings = Array{Savings,1}(undef, slot^2)
    local depot = Delivery("DEPOT",instance.origin, 0, 0, 1, -1)
    local savings_counter = 1

    for i = 1:slot
        for j = 1:slot
            if (i !== j)
                local di = getDistance(cvrp_auxiliars, depot, instance.deliveries[i])
                local dj = getDistance(cvrp_auxiliars, depot, instance.deliveries[j])
                local ij = getDistance(cvrp_auxiliars, instance.deliveries[i], instance.deliveries[j])
                
                if (di + dj > ij && instance.capacity > instance.deliveries[i].size + instance.deliveries[j].size)
                    savings[savings_counter] = Savings(instance.deliveries[i], instance.deliveries[j], di + dj - ij)
                    savings_counter += 1
                end
            end
        end
    end

    local idx = 0
    for i = 1:length(savings)
        if (!isassigned(savings, i))
            idx = i
            break
        end
    end

    deleteat!(savings, idx:length(savings))

    return savings

end

end # module
