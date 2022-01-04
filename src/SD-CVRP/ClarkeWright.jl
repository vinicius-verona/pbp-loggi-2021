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
        local pairs = getPairs(instance, cvrp_auxiliars, idx)

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
        concatRoutes!(routes[first_assignment], pair[2].route_index, pair, routes)
    else if (second_assignment !== 0)
        concatRoutes!(routes[second_assignment], pair[1].route_index, pair, routes)
    else
        throw("Error while merging pairs -> insertPair!() in ClarkeWright.jl")
    end

end

@inline function insertPair!(::Val{:New}, instance::CvrpData, cvrp_auxiliar::CvrpAuxiliars, pair::Tuple{Delivery, Delivery}, routes::Array{Route, 1})

    local depot    = instance.origin
    local capacity = instance.capacity
    local route = Route(length(routes) + 1, Array{Delivery, 1}(), 0.0, depot, capacity, capacity, depot)

    pushDelivery!(cvrp_auxiliars, route, pair[1])
    pushDelivery!(cvrp_auxiliars, route, pair[2])
    push!(routes, route)

end

end # module














#=
using Base: Int64, first_index
export ClarkeWright, clarkewright


mutable struct Route 
    
    id::Int64
    size::Int64
    deliveries::Array{Delivery, 1}
    in_use::Bool

end

mutable struct ClarkeWright <: Solution

    from::Delivery # -> Delivery used to calculate the savings s(i,j) -> i
    to::Delivery   # -> Delivery used to calculate the savings s(i,j) -> j
    pair_savings::Float64 # s(i,j) = d(D,i) + d(D,j) - d(i,j)
                          # * Where d(i,j) is equal to the distance between nodes 'i' and 'j';
                          # * D   -> origin depot (hub)

    ClarkeWright() = new(Delivery, 0.0)
    ClarkeWright(from::Delivery, to::Delivery, savings::Float64) = begin
        return new(from, to, savings) # savings = dist_Di + dist_Dj - dist_ij)
    end

end

"""
    Base.print(io::Core.IO, cw::ClarkeWright)

Ovewrite `print` method for `ClarkeWright` type.
"""
function Base.print(io::Core.IO, cw::ClarkeWright)

    lock(io)
    try
        println(io, "Delivery Pair: (ID: $(cw.from), ID: $(cw.to))")
        println(io, "Pair Savings : $(cw.pair_savings)\n")
    finally
        unlock(io)
    end

    return nothing

end

#########################################################################################################################
#########################################################################################################################
####################################################### Algorithm #######################################################
#########################################################################################################################
#########################################################################################################################

"""
    createRoute(delivery_pair::Array{Delivery, 1}, routes_deliv::Array{Route, 1}, insertion_limiter::Int64)

A new route will be generated between a pair of `Delivery`. This new route updates the `routes_index` and insert the route into ` routes_deliv`.

**Params:**
* `from` - `Delivery` origin to generate route
* `to` - `Delivery` origin to generate route
* `routes_deliv` - Array of existing routes
* `insertion_limiter` - Vehicle capacity limiter
* `dist` - Distance from `from` to `to`

**Returns:**
* `created` - Boolean is used as a return flag to possibly exit route cration loop.
"""
function createRoute(from::Delivery, to::Delivery, routes_deliv::Array{Route, 1}, insertion_limiter::Int64, _)
# function createRoute(from::Delivery, to::Delivery, routes_deliv::Array{Route, 1}, insertion_limiter::Int64, dist::Float64)

    # Check limiter
    if from.size + to.size > insertion_limiter
        return false
    end

    # Create a route
    local route = Route(length(routes_deliv) + 1, from.size + to.size, [from, to], true)
    push!(routes_deliv, route)

    # Update IDs
    from.in_route = true
    to.in_route = true
    from.route_id = route.id
    to.route_id = route.id

    return true

end

"""
    mergeRoute(delivery_pair::Array{Delivery, 1}, routes_deliv::Array{Route, 1}, insertion_limiter::Int64)

Merge two routes if possible.

**Params:**
* `routes_deliv` - Array of existing routes
* `cvrp` - Problem data

**Returns:**
* `merged` - Boolean used as a return flag to possibly exit route cration loop.
"""
function mergeRoute(from::Delivery, to::Delivery, routes_deliv::Array{Route, 1}, cvrp::CVRP)

    if from.in_route && to.in_route
        # Check if deliveries belong to different routes
        local route_groupA = from.route_id
        local route_groupB = to.route_id

        # Same route
        if route_groupA == route_groupB
            return
        end

        local routeA = routes_deliv[route_groupA]
        local routeB = routes_deliv[route_groupB]

        # Exceedes capacity 
        if routeA.size + routeB.size > cvrp.vehicle_capacity
            return
        end

        # Check extremes
        local extreme  = length(routeA.deliveries)
        local extremeA = (routeA.deliveries[1].identifier == from.identifier || routeA.deliveries[extreme].identifier == from.identifier)

        extreme  = length(routeB.deliveries)
        local extremeB = (routeB.deliveries[1].identifier == to.identifier || routeB.deliveries[extreme].identifier == to.identifier)
         
        # Merge if possible
        if extremeA && extremeB
 
            # Get savings from hub to first delivery in both routes
            local hub_to_delivA = cvrp.distances[1, routeA.deliveries[1].identifier + 1]
            local hub_to_delivB = cvrp.distances[1, routeB.deliveries[1].identifier + 1]

            # Merge
            if hub_to_delivA >= hub_to_delivB
                local new_route = cat(routeB.deliveries, routeA.deliveries, dims = (1,1))
                routeB.deliveries = new_route
                routeB.size += routeA.size
                routeA.in_use = false

                # Updates deliveries route group index
                for i in routeA.deliveries
                    i.route_id = routeB.id
                end 

            else
                local new_route = cat(routeA.deliveries, routeB.deliveries, dims = (1,1))
                routeA.deliveries = new_route
                routeA.size += routeB.size
                routeB.in_use = false

                # Updates deliveries route group index
                for i in routeB.deliveries
                    i.route_id = routeA.id
                end 
            end

        end

    elseif !from.in_route
        local route_group = to.route_id
        local route = routes_deliv[route_group]
        
        # Check the size of future route
        if route.size + from.size > cvrp.vehicle_capacity
            return
        end

        # Check if delivery is interior to its route
        local extreme = length(route.deliveries) 
        if route.deliveries[1].identifier == to.identifier || route.deliveries[extreme].identifier == to.identifier
           
            # Get savings from hub to first delivery in both routes
            local hub_to_delivA = cvrp.distances[1, from.identifier + 1]
            local hub_to_delivB = cvrp.distances[1, route.deliveries[1].identifier + 1]

            # Merge
            if hub_to_delivB >= hub_to_delivA
                local new_route = cat([from], route.deliveries, dims = (1,1))
                route.deliveries = new_route
                route.size += from.size

                from.in_route = true
                from.route_id = route.id

            else
                push!(route.deliveries, from)
                route.size += from.size

                from.in_route = true
                from.route_id = route.id
            end

        end

    else
        local route_group = from.route_id
        local route = routes_deliv[route_group]
        
        # Check the size of future route
        if route.size + to.size > cvrp.vehicle_capacity
            return
        end

        # Check if delivery is interior to its route
        local extreme = length(route.deliveries) 
        if route.deliveries[1].identifier == from.identifier || route.deliveries[extreme].identifier == from.identifier
            
            # Get savings from hub to first delivery in both routes
            local hub_to_delivA = cvrp.distances[1, route.deliveries[1].identifier + 1]
            local hub_to_delivB = cvrp.distances[1, to.identifier + 1]

            # Merge
            if hub_to_delivA >= hub_to_delivB
                local new_route = cat([to], route.deliveries, dims = (1,1))
                route.deliveries = new_route
                route.size += to.size

                to.in_route = true
                to.route_id = route.id

            else
                push!(route.deliveries, to)
                route.size += to.size

                to.in_route = true
                to.route_id = route.id
            end

        end
    end 

end

"""
    distributeDeliveriesToVehicles(routes::Array{Route, 1}, hub::Point)

For a given array of type `Route`, each position is a vehicles.

**Parameters:**
* `routes` - Array of type `Route`
* `hub` - Hub, initial point for each vehicle

**Returns:**
* `vehicles` - Array of type `Vehicle`
"""
function distributeDeliveriesToVehicles(routes::Array{Route, 1}, hub::Point, cvrp)
    
    local vehicles::Array{Vehicle, 1} = []
    for i in routes
        
        if i.in_use
            local vehicles_length = length(vehicles)
            local hub_delivery = Delivery("HUB_DELIVERY", hub, 0, 0, true, vehicles_length + 1)
            push!(vehicles, Vehicle(hub, [hub_delivery], 0.0, 0))
            vehicles_length += 1
            
            for j in i.deliveries
                # Insert one more delivery
                push!(vehicles[vehicles_length].deliveries, j)
                j.route_id = vehicles_length
                vehicles[vehicles_length].capacity_used += j.size
            end
            
            push!(vehicles[vehicles_length].deliveries, hub_delivery)
            
            # Adapt the following loop to the line 270 loop
            for j = 1:length(vehicles[vehicles_length].deliveries) - 1
                vehicles[vehicles_length].vehicle_distance += cvrp.distances[vehicles[vehicles_length].deliveries[j].identifier + 1, vehicles[vehicles_length].deliveries[j + 1].identifier + 1]
            end

        end
        
    end
    
    return vehicles

end

"""
    clarkewright(cvrp::CVRP)

Apply Clarke & Wright savings algorithm to the input in order to generate an initial solution.

**Parameters:**
* `cvrp` - `CVRP` type variable

**Returns:**
* `vehicles` - Array of `Vehicle` which repesents all vehicles necessary for delivery.
"""
function clarkewright(cvrp::CVRP)

    local delivery_pairs = Array{Union{ClarkeWright, Nothing}, 1}(nothing, cvrp.number_pairs)
    local counter = 1

    # Calculate first delivery pair savings
    for i = 1:length(cvrp.deliveries)
        for j = 1:length(cvrp.deliveries)
            
            if cvrp.deliveries[i].size + cvrp.deliveries[j].size <= cvrp.vehicle_capacity && i != j
                
                local dist_Di = cvrp.distances[1, cvrp.deliveries[i].identifier + 1]
                local dist_Dj = cvrp.distances[1, cvrp.deliveries[j].identifier + 1]
                local dist_ij = cvrp.distances[cvrp.deliveries[i].identifier + 1, cvrp.deliveries[j].identifier + 1]
                local savings = dist_Di + dist_Dj - dist_ij

                if dist_Di + dist_Dj < dist_ij
                    continue
                end

                local cw = ClarkeWright(cvrp.deliveries[i], cvrp.deliveries[j], savings)
                delivery_pairs[counter] = cw
                counter += 1
                
            end
            
        end
    end


    # Sort pairs in order to choose those subroutes with maximum savings
    filter!(x -> x !== nothing, delivery_pairs)
    sort!(delivery_pairs, alg=QuickSort, rev=true, by = x->x.pair_savings)

    #########################################################################################################################
    #########################################################################################################################

    # Create routes
    local routes_deliv = Array{Route, 1}()

    # First route
    local dist = cvrp.distances[delivery_pairs[1].from.identifier + 1, delivery_pairs[1].to.identifier + 1]
    local route = Route(1, delivery_pairs[1].from.size + delivery_pairs[1].to.size, [delivery_pairs[1].from, delivery_pairs[1].to], true)
    push!(routes_deliv, route)

    # Update first route position
    delivery_pairs[1].from.in_route = true
    delivery_pairs[1].to.in_route   = true
    delivery_pairs[1].from.route_id = route.id
    delivery_pairs[1].to.route_id   = route.id

    # Continue creating and updating routes
    for i = 2:length(delivery_pairs)
        if delivery_pairs[i] === nothing
            break
        end
        
        # Get deliveries route group index
        dist = cvrp.distances[delivery_pairs[i].from.identifier + 1, delivery_pairs[i].to.identifier + 1]
        local in_route = delivery_pairs[i].from.in_route || delivery_pairs[i].to.in_route
        
        # Handle route creation if necessary
        if !in_route
            createRoute(delivery_pairs[i].from, delivery_pairs[i].to, routes_deliv, cvrp.vehicle_capacity, dist)

        else
            mergeRoute(delivery_pairs[i].from, delivery_pairs[i].to, routes_deliv, cvrp)
        end
    end

    # Create routes for remaining deliveries
    for i in cvrp.deliveries
        if !i.in_route
            dist  = cvrp.distances[1, i.identifier + 1] + cvrp.distances[i.identifier + 1, 1]
            route = Route(length(routes_deliv) + 1, i.size, [i], true)
            push!(routes_deliv, route)
        end
    end

    return distributeDeliveriesToVehicles(routes_deliv, cvrp.origin, cvrp)

end
=#