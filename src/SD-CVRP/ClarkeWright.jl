module ClarkeWright

using CVRP_Structures: Delivery, CvrpData, CvrpAuxiliars, Route, Point
using CVRP_Controllers: getDistance, pushDelivery!

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
adapted to the synamic stochastic version of CVRP (SD-CVRP).

**Parameters:**
* `instance` - Instance original data
* `cvrp_auxiliars` - Instance auxiliar data

**Returns:**
* Array of `Route`, each containing different deliveries to be attended by the route.
"""
function clarkeWrightSolution(instance::CvrpData, cvrp_auxiliars::CvrpAuxiliars)

    local idx = 0
    local routes::Array{Route, 1} = []

    foreach(d->begin
        idx += 1
        local pairs = getPairs(instance, cvrp_auxiliars, idx) # Get combination pairs of delivery until delivery of index idx
                                                              # As switching routes are not permited in the studied SD-CVRP
                                                              # all combination of deliveries must include the delivery idx as
                                                              # part of the pair

        for p in pairs

            local in_route = p[1].route_index !== 0 || p[2].route_index !== 0

            if (in_route)
                insertPair!(:Merge, instance, cvrp_auxiliars, p, routes)
            else
                insertPair!(:New, instance, cvrp_auxiliars, p, routes)
            end

        end
    end, instance.deliveries)

    return routes

end

"""
    insertPair(type::Symbol, cvrp_auxiliar::CvrpAuxiliars, pair::Tuple{Delivery, Delivery}, routes::Array{Route, 1})

For a given pair of delivery, insert it into a pair by either `:Merge` (mergin existing routes) or `:New` (creating new routes).
"""
insertPair!(type::Symbol, instance::CvrpData, cvrp_auxiliar::CvrpAuxiliars, pair::Tuple{Delivery, Delivery}, routes::Array{Route, 1}) = type == :Merge ? 
    insertPair(Val(:Merge), instance, cvrp_auxiliar, pair, routes) :
    insertPair(Val(:New), instance, cvrp_auxiliar, pair, routes)

@inline function insertPair!(::Val{:Merge}, instance::CvrpData, cvrp_auxiliar::CvrpAuxiliars, pair::Tuple{Delivery, Delivery}, routes::Array{Route, 1})

    local first_assignment  = pair[1].route_index
    local second_assignment = pair[2].route_index

    if (first_assignment !== 0 && second_assignment !== 0 && first_assignment !== second_assignment)
        concatRoutes!(routes[first_assignment], routes[second_assignment], pair, routes)
    else if (first_assignment !== 0)
        concatRoutes!(routes[first_assignment], pair[2].route_index, routes)
    else if (second_assignment !== 0)
        concatRoutes!(routes[second_assignment], pair[1].route_index, routes)
    else
        throw("Error while merging pairs -> insertPair!() in ClarkeWright.jl")
    end

end

"""
For the `:New` type, create a new route, insert both deliveries belonging to `pair` and push it to routes array.
"""
function insertPair!(::Val{:New}, instance::CvrpData, cvrp_auxiliar::CvrpAuxiliars, pair::Tuple{Delivery, Delivery}, routes::Array{Route, 1})

    local depot    = instance.origin
    local capacity = instance.capacity
    local route = Route(length(routes) + 1, Array{Delivery, 1}(), 0.0, depot, capacity, capacity, depot)

    pushDelivery!(cvrp_auxiliars, route, pair[1])
    pushDelivery!(cvrp_auxiliars, route, pair[2])
    push!(routes, route)

end


# Both concatRoutes! insert or concat routes based according to Clarke-Wright and SD_CVRP merging/insertion rules.
concatRoutes!(route::Route, routes[second_assignment]::Route, pair::Tuple{Delivery, Delivery}, routes::Array{Routes, 1}) = nothing
concatRoutes!(route::Route, delivery::Delivery, routes::Array{Routes, 1}) = nothing

end # module
