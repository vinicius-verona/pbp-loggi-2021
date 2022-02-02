using CVRP_Structures: CvrpData, CvrpAuxiliars, Route, Delivery
using CVRP_Controllers: getDistance, pushDelivery!, deleteDelivery!,
                        getBestInsertionPosition, getClosestRoute,
                        getStringSize, getStringDistance, getInsertionDistance

export Swap
mutable struct Swap <: Neighbor
    
    id::String
    hasMove::Bool
    swap_size::Int64
    
    first_route::RouteOrNothing
    second_route::RouteOrNothing

    positions_route1::Array{Int64,1} # Indexes from which we selected deliveries in first_route
    positions_route2::Array{Int64,1} # Indexes from which we selected deliveries in second_route

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

    Swap(size::Int64 = 1; id = "Swap-default") = begin
        local hasMove   = false
        local swap_size = size
        local first_route  = nothing
        local second_route = nothing
        local positions_route1 = Array{Int64, 1}(undef, 0)
        local positions_route2 = Array{Int64, 1}(undef, 0)
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

        id === "Swap-default" ? id = "Swap-$swap_size" : nothing

        return new(id, hasMove, swap_size, first_route, second_route, positions_route1, 
                   positions_route2, first_string, second_string, original_size1, 
                   original_size2, move_size1, move_size2, original_distance1,
                   original_distance2, move_distance1, move_distance2, 0, 0, 0, 0, 0, 0)
    end

end

export execute
function execute(cvrp_aux::CvrpAuxiliars, swap::Swap, routes::Array{Route, 1}, _) # Delta evaluation

    # Update some statistics regarding the move execution
    swap.hasMove = false
    swap.first_route = nothing
    swap.second_route = nothing

    # Selecting routes
    swap.first_route = rand(routes)
    swap.second_route = rand(routes)
    
    if (swap.first_route.index == swap.second_route.index)
        local timeout = 0
        while (swap.first_route.index == swap.second_route.index ||
              length(swap.first_route.deliveries) - 2 < swap.swap_size ||
              length(swap.second_route.deliveries) - 2 < swap.swap_size)

            timeout += 1
            swap.first_route = rand(routes)
            swap.second_route = rand(routes)

            if (timeout > 100)
                swap.hasMove = false
                return typemax(Int64)
            end
        
        end
    end

    # As both routes are different routes and both have swap_size deliveries, chose random string to swap
    local unfixedR1 = findall(x -> x.fixed == false && x.index !== 0, swap.first_route.deliveries) 
    local unfixedR2 = findall(x -> x.fixed == false && x.index !== 0, swap.second_route.deliveries) 

    if (length(unfixedR1) < swap.swap_size || length(unfixedR2) < swap.swap_size)
        swap.hasMove = false
        return typemax(Int64)
    end

    # Select first string
    if (length(unfixedR1) == swap.swap_size)
        swap.positions_route1 = unfixedR1
    else
        timeout = 0

        while (timeout <= 100)
            timeout += 1
            
            local selected = rand(unfixedR1, swap.swap_size)
            unique!(selected)

            if (length(selected) == swap.swap_size)
                swap.positions_route1 = sort(selected, alg=MergeSort)
                break
            end
        end
        
        if (timeout >= 100)
            swap.positions_route1 = unfixedR1[1:swap.swap_size]
        end
    end

    # Select second string
    if (length(unfixedR2) == swap.swap_size)
        swap.positions_route2 = unfixedR2
    else
        timeout = 0

        while (timeout <= 100)
            timeout += 1

            local selected = rand(unfixedR2, swap.swap_size)
            unique!(selected)

            if (length(selected) == swap.swap_size)
                swap.positions_route2 = sort(selected, alg=MergeSort)
                break
            end
        end
        
        if (timeout >= 100)
            swap.positions_route2 = unfixedR2[1:swap.swap_size]
        end
    end

    # Store original values
    swap.original_size1 = swap.first_route.free
    swap.original_size2 = swap.second_route.free
    swap.original_distance1 = swap.first_route.distance
    swap.original_distance2 = swap.second_route.distance
    
    # Store selected string
    swap.first_string  = swap.first_route.deliveries[swap.positions_route1]
    swap.second_string = swap.second_route.deliveries[swap.positions_route2]

    if (swap.first_route.free + getStringSize(swap.first_string) - getStringSize(swap.second_string) < 0 ||
        swap.second_route.free + getStringSize(swap.second_string) - getStringSize(swap.first_string) < 0)
        swap.hasMove = false
        return typemax(Int64)
    end

    # Execute move
    for i = 1:swap.swap_size
        
        deleteDelivery!(cvrp_aux, swap.first_route, swap.positions_route1[i])
        deleteDelivery!(cvrp_aux, swap.second_route, swap.positions_route2[i])

        pushDelivery!(cvrp_aux, swap.first_route, swap.second_string[i], swap.positions_route1[i])
        pushDelivery!(cvrp_aux, swap.second_route, swap.first_string[i], swap.positions_route2[i])

    end
    
    swap.move_size1 = swap.first_route.free
    swap.move_size2 = swap.second_route.free
    swap.move_distance1 = swap.first_route.distance
    swap.move_distance2 = swap.second_route.distance

    # Update some statistics regarding the move execution
    swap.hasMove = true
    swap.total += 1

    # Calculate delta value
    return (swap.move_distance1 + swap.move_distance2) - (swap.original_distance1 + swap.original_distance2)
    
end

export accept
accept(_::CvrpAuxiliars, swap::Swap, _::Array{Route, 1}) = swap.accept += 1

export reject
function reject(cvrp_aux::CvrpAuxiliars, swap::Swap) 
    
    # Update some statistics regarding the move execution
    swap.reject += 1

    for i = 1:swap.swap_size
        
        deleteDelivery!(cvrp_aux, swap.first_route, swap.positions_route1[i])
        deleteDelivery!(cvrp_aux, swap.second_route, swap.positions_route2[i])
        
        pushDelivery!(cvrp_aux, swap.first_route, swap.first_string[i], swap.positions_route1[i])
        pushDelivery!(cvrp_aux, swap.second_route, swap.second_string[i], swap.positions_route2[i])

    end

end