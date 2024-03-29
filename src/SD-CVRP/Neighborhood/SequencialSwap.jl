using CVRP_Structures: CvrpData, CvrpAuxiliars, Route, Delivery
using CVRP_Controllers: getDistance, pushDelivery!, deleteDelivery!,
                        getBestInsertionPosition, getClosestRoute,
                        getStringSize, getStringDistance, getInsertionDistance

DEBUG = 0

"""
    - This neighbor considers that, for a route of type {depot -> d1 -> d2 ... -> dk -> depot}
    - if dn, where n <= k, is the first one not fixed to the route, then dn+1...dk are also not fixed.
    - However, d1...dn-1 are all fixed to the route.
"""

export SequencialSwap
mutable struct SequencialSwap <: Neighbor
    
    id::String
    hasMove::Bool
    swap_size::Int64
    
    first_route::RouteOrNothing
    second_route::RouteOrNothing

    r1_starts_at::Int64 # Index in which we start selecting deliveries in first_route
    r2_starts_at::Int64 # Index in which we start selecting deliveries in second_route
    r1_ends_at::Int64 # Index in which we stop selecting deliveries in first_route
    r2_ends_at::Int64 # Index in which we stop selecting deliveries in second_route

    first_string::Array{Delivery, 1}
    second_string::Array{Delivery, 1}

    original_size1::Int64 # The quantity of free space in first_route
    original_size2::Int64 # The quantity of free space in second_route
    move_size1::Int64 # The quantity of free space in first_route after move is pre-executed
    move_size2::Int64 # The quantity of free space in second_route after move is pre-executed

    original_distance1::Float64 # The distance in first_route
    original_distance2::Float64 # The distance in second_route
    move_distance1::Float64 # The distance in first_route after move is pre-executed
    move_distance2::Float64 # The distance in second_route after move is pre-executed

    accept::Int64
    reject::Int64
    improvements::Int64
    worsens::Int64
    sideways::Int64
    total::Int64

    SequencialSwap(size::Int64 = 1; id = "SequencialSwap-default") = begin
        local hasMove   = false
        local swap_size = 1
        local first_route  = nothing
        local second_route = nothing
        local r1_starts_at = -1
        local r2_starts_at = -1
        local r1_ends_at = -1
        local r2_ends_at = -1
        local first_string   = Array{Delivery, 1}(undef, 0)
        local second_string  = Array{Delivery, 1}(undef, 0)
        local original_size1 = 0
        local original_size2 = 0
        local move_size1 = 0
        local move_size2 = 0
        local original_distance1 = 0
        local original_distance2 = 0
        local move_distance1 = 0
        local move_distance2 = 0

        swap_size = size
        id === "SequencialSwap-default" ? id = "SequencialSwap-$swap_size" : nothing

        return new(id, hasMove, swap_size, first_route, second_route, r1_starts_at,
                   r2_starts_at, r1_ends_at, r2_ends_at, first_string, second_string, 
                   original_size1, original_size2, move_size1, move_size2, original_distance1,
                   original_distance2, move_distance1, move_distance2, 0, 0, 0, 0, 0, 0)
    end

end

export execute
function execute(cvrp_aux::CvrpAuxiliars, swap::SequencialSwap, routes::Array{Route, 1}, _) # Delta evaluation

    # WARNING: When SequencialSwap is used with SequencialShift, the same insertion problem can occur.
    # The same strategies can be applied. However, SequencialSwap itself is not wrong.

    # Update some statistics regarding the move execution
    swap.hasMove = false
    swap.first_route = nothing
    swap.second_route = nothing

    # Selecting routes
    swap.first_route = rand(routes)
    swap.second_route = rand(routes)
    
    if (swap.first_route.index == swap.second_route.index)
        while (swap.first_route.index == swap.second_route.index ||
              length(swap.first_route.deliveries) - 2 < swap.swap_size ||
              length(swap.second_route.deliveries) - 2 < swap.swap_size)

            swap.first_route = rand(routes)
            swap.second_route = rand(routes)
        
        end
    end

    # As both routes are different routes and both have swap_size deliveries, chose random string to swap
    local r1_size   = length(swap.first_route.deliveries)
    local r2_size   = length(swap.second_route.deliveries)
    local unfixedR1 = findfirst(x -> x.fixed == false && x.index !== 0, swap.first_route.deliveries) 
    local unfixedR2 = findfirst(x -> x.fixed == false && x.index !== 0, swap.second_route.deliveries) 

    if (unfixedR1 === nothing || unfixedR2 === nothing || unfixedR1 + swap.swap_size > r1_size - 1 ||
        unfixedR2 + swap.swap_size > r2_size - 1)
        swap.hasMove = false
        return typemax(Int64)
    end

    
    swap.r1_starts_at = rand(unfixedR1:r1_size - swap.swap_size - 1)
    swap.r2_starts_at = rand(unfixedR2:r2_size - swap.swap_size - 1)
    swap.r1_ends_at   = swap.r1_starts_at + swap.swap_size - 1
    swap.r2_ends_at   = swap.r2_starts_at + swap.swap_size - 1
    
    # Store original values
    swap.original_size1 = swap.first_route.free
    swap.original_size2 = swap.second_route.free
    swap.original_distance1 = swap.first_route.distance
    swap.original_distance2 = swap.second_route.distance
    
    # Store selected string
    swap.first_string  = swap.first_route.deliveries[swap.r1_starts_at:swap.r1_ends_at]
    swap.second_string = swap.second_route.deliveries[swap.r2_starts_at:swap.r2_ends_at]
    
    if (findfirst(x -> x.fixed == true, swap.first_string) !== nothing ||
        findfirst(x -> x.fixed == true, swap.second_string) !== nothing)
        swap.hasMove = false
        return typemax(Int64)
    end

    if (swap.first_route.free + getStringSize(swap.first_string) - getStringSize(swap.second_string) < 0 ||
        swap.second_route.free + getStringSize(swap.second_string) - getStringSize(swap.first_string) < 0)
        swap.hasMove = false
        return typemax(Int64)
    end

    # Calculate move value
    swap.move_distance1 = swap.original_distance1 - getStringDistance(cvrp_aux, swap.first_string) + 
                          getDistance(cvrp_aux, swap.first_route.deliveries[swap.r1_starts_at - 1], swap.first_route.deliveries[swap.r1_ends_at + 1])
    swap.move_distance1 += getInsertionDistance(cvrp_aux, swap.first_route, swap.r1_starts_at, swap.swap_size, swap.second_string)
    
    swap.move_distance2 = swap.original_distance2 - getStringDistance(cvrp_aux, swap.second_string) +
                          getDistance(cvrp_aux, swap.second_route.deliveries[swap.r2_starts_at - 1], swap.second_route.deliveries[swap.r2_ends_at + 1])
    swap.move_distance2 += getInsertionDistance(cvrp_aux, swap.second_route, swap.r2_starts_at, swap.swap_size, swap.first_string)

    # Update some statistics regarding the move execution
    swap.hasMove = true
    swap.total += 1

    # Calculate delta value
    return (swap.move_distance1 + swap.move_distance2) - (swap.original_distance1 + swap.original_distance2)
    
end

export accept
function accept(cvrp_aux::CvrpAuxiliars, swap::SequencialSwap, _::Array{Route, 1})

    # SequencialSwap deliveries between the selected routes
    deleteDelivery!(cvrp_aux, swap.first_route, swap.r1_starts_at, swap.r1_ends_at)
    deleteDelivery!(cvrp_aux, swap.second_route, swap.r2_starts_at, swap.r2_ends_at)
    pushDelivery!(cvrp_aux, swap.first_route, swap.second_string, swap.r1_starts_at)
    pushDelivery!(cvrp_aux, swap.second_route, swap.first_string, swap.r2_starts_at)

    # Update move execution statistics
    swap.accept += 1

end

export reject
reject(_::CvrpAuxiliars, swap::SequencialSwap) = swap.reject += 1