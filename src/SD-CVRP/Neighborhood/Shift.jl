using CVRP_Structures: CvrpData, CvrpAuxiliars, Route, Delivery
using CVRP_Controllers: getDistance, pushDelivery!, deleteDelivery!,
                        getBestInsertionPosition, getClosestRoute,
                        getStringSize, getStringDistance, getInsertionDistance,
                        deleteRoute!

export Shift
mutable struct Shift <: Neighbor
    
    id::String
    hasMove::Bool
    shift_size::Int64
    
    route::RouteOrNothing # Removal route
    routes::RoutesOrNothing # Insertion routes

    removal_positions::Array{Int64, 1} # Indexes from which we select deliveries in route
    insertion_positions::Array{Int64, 1} # Index in which we will insert each delivery
    insert_routes_index::Array{Int64, 1} # Index in which we start selecting deliveries in second_route

    string::Array{Delivery, 1}
    predecessors::Array{Delivery, 1} # Closest predecessors in new route

    original_size::Int64 # The quantity of free space in removal route
    original_sizes::Array{Int64, 1} # The quantity of free space in insertion routes
    move_size::Int64 # The quantity of free space in removal route after move is executed
    move_sizes::Array{Int64, 1} # The quantity of free space in insertion routes after move is executed

    original_distance::Float64 # The distance in removal route
    original_distances::Array{Float64, 1} # The distance in insertion routes
    move_distance::Float64 # The distance in removal route after move is executed
    move_distances::Array{Float64, 1} # The distance in insertion routes after move is executed

    accept::Int64
    reject::Int64
    improvements::Int64
    worsens::Int64
    sideways::Int64
    total::Int64

    Shift(size::Int64 = 1; id="Shift-default") = begin
        local hasMove    = false
        local shift_size = 1

        shift_size = size
        id === "Shift-default" ? id = "Shift-$shift_size" : nothing

        local route      = nothing
        local routes     = Array{Delivery, 1}(undef, shift_size)
        local removal_positions   = zeros(Int64, shift_size)
        local insertion_positions = zeros(Int64, shift_size)
        local insert_routes_index = zeros(Int64, shift_size)
        local string         = Array{Delivery, 1}(undef, 0)
        local predecessors   = Array{Delivery, 1}(undef, shift_size)
        local original_size  = 0
        local original_sizes = zeros(Int64, shift_size)
        local move_size  = 0
        local move_sizes = zeros(Int64, shift_size)
        local original_distance  = 0
        local original_distances = zeros(Float64, shift_size)
        local move_distance  = 0
        local move_distances = zeros(Float64, shift_size)

        return new(id, hasMove, shift_size, route, routes, removal_positions,
                   insertion_positions, insert_routes_index, string, 
                   predecessors, original_size, original_sizes, move_size,
                   move_sizes, original_distance, original_distances, move_distance,
                   move_distances, 0, 0, 0, 0, 0, 0)
    end

end

export execute
function execute(cvrp_aux::CvrpAuxiliars, shift::Shift, routes::Array{Route, 1}, deliveries::Array{Delivery, 1}) # Delta evaluation

    # Update some statistics regarding the move execution
    shift.hasMove = false

    # Selecting route
    shift.route = rand(routes)
    local timeout = 0
    
    while (length(shift.route.deliveries) - 2 < shift.shift_size)
        shift.route = rand(routes)
        
        timeout += 1
        if (timeout > 100)
            shift.hasMove = false
            return typemax(Int64)
        end
    end

    # Chose random string to shift
    local unfixed_route = findall(x -> x.fixed == false && x.index !== 0, shift.route.deliveries) 

    if (length(unfixed_route) < shift.shift_size)
        shift.hasMove = false
        return typemax(Int64)
    end

    # Select first string
    if (length(unfixed_route) == shift.shift_size)
        shift.removal_positions = unfixed_route
    else
        timeout = 0

        while (timeout <= 100)
            timeout += 1
            
            local selected = rand(unfixed_route, shift.shift_size)
            unique!(selected)

            if (length(selected) == shift.shift_size)
                shift.removal_positions = sort(selected, alg=MergeSort)
                break
            end
        end
        
        if (timeout >= 100)
            shift.removal_positions = unfixed_route[1:shift.shift_size]
        end
    end

    shift.string  = shift.route.deliveries[shift.removal_positions]

    # Select closest routes and insertion positions
    # For each insertion position detected, shift delivery
    local original_routes_distance = 0
    local move_routes_distance     = 0
    
    local route_indexes = []
    for i = 1:shift.shift_size

        local delivery = shift.string[i]

        local route_index = getClosestRoute(cvrp_aux, deliveries, routes, delivery)
        if (route_index === typemax(Int64))
            shift.hasMove = false
            return typemax(Int64)
        end
        
        shift.routes[i] = routes[route_index]

        if (!(route_index in route_indexes))
            original_routes_distance += shift.routes[i].distance
        end

        shift.insert_routes_index[i] = route_index
        
        local insertion_position = getBestInsertionPosition(cvrp_aux, shift.routes[i], delivery)
        if (insertion_position === typemax(Int64))
            if (i > 1)
                shift.hasMove = false
                return typemax(Int64)
            else
                shift.hasMove = true
                return typemax(Int64)
            end
        end
        
        shift.predecessors[i] = shift.routes[i].deliveries[insertion_position - 1]
        shift.insertion_positions[i] = insertion_position

        if (route_index in route_indexes)
            move_routes_distance -= shift.routes[i].distance # If the route has already been summed, remove value before sum
        else
            push!(route_indexes, route_index)
        end

        deleteDelivery!(cvrp_aux, shift.route, delivery.visiting_index, delivery.visiting_index)
        pushDelivery!(cvrp_aux, shift.routes[i], delivery, insertion_position)
        move_routes_distance += shift.routes[i].distance # If the route has already been summed, remove value before sum
        
    end
    
    # Update removal route distance
    shift.move_distance = shift.route.distance

    # Update some statistics regarding the move execution
    shift.hasMove = true
    shift.total += 1

    # # TEST: Verify Cost after move
    #     local solution = [shift.route]
    #     solution = cat(routes, shift.routes, dims=1)
    #     for route in solution
    #         if (abs(route.distance / 1000 - getStringDistance(cvrp_aux, route.deliveries) / 1000) > 1e-5)
    #             error = "Different Distance: Route($(route.distance / 1000) KM) | String($(getStringDistance(cvrp_aux, route.deliveries) / 1000) KM)"
                
    #             local sum = 0
    #             for i = 1:length(route.deliveries)-1
    #                 sum += getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1])
    #                 println("From $(route.deliveries[i].index) to $(route.deliveries[i+1].index) sums $(getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1]))")
    #             end
    
    #             println("SUM: $sum - ORIGINAL SUM: $(route.distance)")
    #             println()
    #             throw(error)
    #         end
    #     end
    # # End of test

    # Calculate delta value
    return (shift.move_distance + move_routes_distance) - (shift.original_distance + original_routes_distance)
    
end

export accept
function accept(_::CvrpAuxiliars, shift::Shift, solution::Array{Route, 1})

    shift.accept += 1

    if (length(shift.route.deliveries) <= 2)
        deleteRoute!(shift.route.index, solution)
    end

    # # TEST: Verify Cost after move
    #     local routes = [shift.route]
    #     routes = cat(routes, shift.routes, dims=1)

    #     for route in routes
    #         if (abs(route.distance / 1000 - getStringDistance(cvrp_aux, route.deliveries) / 1000) > 1e-5)
    #             error = "Different Distance: Route($(route.distance / 1000) KM) | String($(getStringDistance(cvrp_aux, route.deliveries) / 1000) KM)"
                
    #             local sum = 0
    #             for i = 1:length(route.deliveries)-1
    #                 sum += getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1])
    #                 println("From $(route.deliveries[i].index) to $(route.deliveries[i+1].index) sums $(getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1]))")
    #             end
    
    #             println("SUM: $sum - ORIGINAL SUM: $(route.distance)")
    #             println()
    #             throw(error)
    #         end
    #     end
    # # End of test

end

export reject
function reject(cvrp_aux::CvrpAuxiliars, shift::Shift)

    for i = 1:shift.shift_size
        if (shift.string[i].route_index !== shift.route.index)
            deleteDelivery!(cvrp_aux, shift.routes[i], shift.string[i].visiting_index)
            pushDelivery!(cvrp_aux, shift.route, shift.string[i], shift.removal_positions[i])
        end
    end

    # # TEST: Verify Cost after move
    #     local routes = [shift.route]
    #     routes = cat(routes, shift.routes, dims=1)
        
    #     for route in routes
    #         if (abs(route.distance / 1000 - getStringDistance(cvrp_aux, route.deliveries) / 1000) > 1e-5)
    #             error = "Different Distance: Route($(route.distance / 1000) KM) | String($(getStringDistance(cvrp_aux, route.deliveries) / 1000) KM)"
                
    #             local sum = 0
    #             for i = 1:length(route.deliveries)-1
    #                 sum += getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1])
    #                 println("From $(route.deliveries[i].index) to $(route.deliveries[i+1].index) sums $(getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1]))")
    #             end
    
    #             println("SUM: $sum - ORIGINAL SUM: $(route.distance)")
    #             println()
    #             throw(error)
    #         end
    #     end
    # # End of test

    # Update move execution statistics
    shift.reject += 1

end