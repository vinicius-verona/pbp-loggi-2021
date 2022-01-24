"""
    - This neighbor considers that, for a route of type {depot -> d1 -> d2 ... -> dk -> depot}
    - if dn, where n <= k, is the first one not fixed to the route, then dn+1...dk are also not fixed.
    - However, d1...dn-1 are all fixed to the route.
"""

export Swap
mutable struct Swap <: Neighbor
    
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

    original_distance1::Int64 # The distance in first_route
    original_distance2::Int64 # The distance in second_route
    move_distance1::Int64 # The distance in first_route after move is pre-executed
    move_distance2::Int64 # The distance in second_route after move is pre-executed

    accept::Int64
    reject::Int64
    improvements::Int64
    worsens::Int64
    sideways::Int64
    total::Int64

    Swap(size::Int64 = 1; id = "Swap-default") = begin
        # local id = "Swap-default"
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
        id === "Swap-default" ? id = "Swap-$swap_size" : nothing

        # isdefined(attributes,  1) ? id = attributes[1] : nothing
        # isdefined(attributes,  2) ? begin
        #     swap_size = attributes[2]
        #     id === "Swap-default" ? id = "Swap-$swap_size" : nothing
        # end : nothing
        # isdefined(attributes,  4) ? first_route  = attributes[4] : nothing
        # isdefined(attributes,  5) ? second_route = attributes[5] : nothing
        # isdefined(attributes,  6) ? r1_starts_at = attributes[6] : nothing
        # isdefined(attributes,  7) ? r2_starts_at = attributes[7] : nothing
        # isdefined(attributes,  8) ? r1_ends_at   = attributes[8] : nothing
        # isdefined(attributes,  9) ? r2_ends_at   = attributes[9] : nothing
        # isdefined(attributes, 10) ? original_size1 = attributes[10] : nothing
        # isdefined(attributes, 11) ? original_size2 = attributes[11] : nothing
        # isdefined(attributes, 12) ? move_size1 = attributes[12] : nothing
        # isdefined(attributes, 13) ? move_size2 = attributes[13] : nothing
        # isdefined(attributes, 14) ? original_distance1 = attributes[14] : nothing
        # isdefined(attributes, 15) ? original_distance2 = attributes[15] : nothing
        # isdefined(attributes, 16) ? move_distance1 = attributes[16] : nothing
        # isdefined(attributes, 17) ? move_distance2 = attributes[17] : nothing

        return new(id, hasMove, swap_size, first_route, second_route, r1_starts_at,
                   r2_starts_at, r1_ends_at, r2_ends_at, first_string, second_string, 
                   original_size1, original_size2, move_size1, move_size2, original_distance1,
                   original_distance2, move_distance1, move_distance2, 0, 0, 0, 0, 0, 0)
    end

end

export execute
function execute(cvrp_aux::CvrpAuxiliars, swap::Swap, routes::Array{Route, 1}, _) # Delta evaluation

    # Update some statistics regarding the move execution
    move.hasMove = false

    # Selecting routes
    swap.first_route = rand(routes)
    swap.second_route = rand(routes)
    
    if (swap.first_route.index == swap.second_route.index)
        while (swap.first_route.index == swap.second_route.index &&
              (length(swap.first_route.deliveries) - 2 < swap.swap_size
              || length(swap.second_route.deliveries) - 2 < swap.swap_size))

            swap.first_route = rand(routes)
            swap.second_route = rand(routes)
        
        end
    end
    
    # As both routes are different routes and both have swap_size deliveries, chose random string to swap
    local r1_size   = length(swap.first_route.deliveries)
    local r2_size   = length(swap.second_route.deliveries)
    local unfixedR1 = findfirst(x -> x.fixed == false, swap.first_route.deliveries) 
    local unfixedR2 = findfirst(x -> x.fixed == false, swap.second_route.deliveries) 

    if (unfixedR1 + swap.swap_size > r1_size - 1 || unfixedR2 + swap.swap_size > r2_size - 1)
        swap.hasMove = false
        return typemax(Int64)
    end

    swap.r1_starts_at = rand(unfixedR1:r1_size - swap.swap_size)
    swap.r2_starts_at = rand(unfixedR2:r2_size - swap.swap_size)
    swap.r1_ends_at   = swap.r1_starts_at + swap.swap_size - 1
    swap.r2_ends_at   = swap.r2_starts_at + swap.swap_size - 1

    # Store original values
    swap.original_size1 = swap.first_route.free
    swap.original_size2 = swap.second_route.free
    swap.original_distance1 = swap.first_route.distance
    swap.original_distance2 = swap.second_route.distance
    
    # Store selected string
    swap.first_string  = swap.first_route[swap.r1_starts_at:swap.r1_ends_at]
    swap.second_string = swap.second_route[swap.r2_starts_at:swap.r2_ends_at]

    if (swap.first_route.free + getStringSize(swap.first_string) - getStringSize(swap.second_string) < 0
        || swap.second_route.free + getStringSize(swap.second_string) - getStringSize(swap.first_string) < 0)
        
        swap.hasMove = false
        return typemax(Int64)

    end

    # Calculate move value
    swap.move_distance1 = swap.original_distance1 - getStringDistance(cvrp_aux, swap.first_string)
    swap.move_distance1 += getInsertionDistance(cvrp_aux, swap.first_route, swap.r1_starts_at, swap.swap_size, swap.second_string)
    swap.move_distance2 = swap.original_distance2 - getStringDistance(cvrp_aux, swap.second_string)
    swap.move_distance2 += getInsertionDistance(cvrp_aux, swap.second_route, swap.r2_starts_at, swap.swap_size, swap.first_string)

    # Update some statistics regarding the move execution
    move.hasMove = true
    move.total += 1

    # Calculate delta value
    return (swap.move_distance1 + swap.move_distance2) - (swap.original_distance1 + swap.original_distance2)
    
end

export accept
function accept(cvrp_aux::CvrpAuxiliars, swap::Swap)
        
    # Swap deliveries between the selected routes
    deleteDelivery!(cvrp_aux, swap.first_route, swap.r1_starts_at, swap.r1_ends_at)
    deleteDelivery!(cvrp_aux, swap.second_route, swap.r2_starts_at, swap.r2_ends_at)
    pushDelivery!(cvrp_aux, swap.first_route, swap.second_route, swap.r1_starts_at)
    pushDelivery!(cvrp_aux, swap.second_route, swap.first_route, swap.r2_starts_at)

    # Update move execution statistics
    move.accept += 1

end

export reject
reject(_::CvrpAuxiliars, swap::Swap) = swap.reject += 1