"""
    - This neighbor considers that, for a route of type {depot -> d1 -> d2 ... -> dk -> depot}
    - if dn, where n <= k, is the first one not fixed to the route, then dn+1...dk are also not fixed.
    - However, d1...dn-1 are all fixed to the route.
"""

export Shift
mutable struct Shift <: Neighbor
    
    id::String
    hasMove::Bool
    shift_size::Int64
    
    route::RouteOrNothing # Removal route
    routes::RoutesOrNothing # Insertion routes

    removal_starts_at::Int64 # Index in which we start selecting deliveries in route
    removal_ends_at::Int64 # Index in which we stop selecting deliveries in route
    insertion_positions::Array{Int64, 1} # Index in which we will insert each delivery
    insert_routes_index::Array{Int64, 1} # Index in which we start selecting deliveries in second_route

    string::Array{Delivery, 1}
    predecessors::Array{Delivery, 1} # Closest predecessors in new route

    original_size::Int64 # The quantity of free space in removal route
    original_sizes::Array{Int64, 1} # The quantity of free space in insertion routes
    move_size::Int64 # The quantity of free space in removal route after move is executed
    move_sizes::Array{Int64, 1} # The quantity of free space in insertion routes after move is executed

    original_distance::Int64 # The distance in removal route
    original_distances::Array{Int64, 1} # The distance in insertion routes
    move_distance::Int64 # The distance in removal route after move is executed
    move_distances::Array{Int64, 1} # The distance in insertion routes after move is executed

    accept::Int64
    reject::Int64
    improvements::Int64
    worsens::Int64
    sideways::Int64
    total::Int64

    Shift(attributes...) = begin
        local id = "Shift-default"
        local hasMove    = false
        local shift_size = 1

        isdefined(attributes,  1) ? id = attributes[1] : nothing
        isdefined(attributes,  2) ? hasMove = attributes[2] : nothing
        isdefined(attributes,  3) ? begin
            shift_size = attributes[3]
            id === "Shift-default" ? id = "Shift-$shift_size" : nothing
        end : nothing
  
        local route      = nothing
        local routes     = Array{Delivery, 1}(undef, shift_size)
        local removal_starts_at   = -1
        local removal_ends_at     = -1
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

        return new(id, hasMove, shift_size, route, routes, removal_starts_at,
                   removal_ends_at, insertion_positions, insert_routes_index,
                   string, predecessors, original_size, original_sizes, move_size,
                   move_sizes, original_distance, original_distances, move_distance,
                   move_distances, 0, 0, 0, 0, 0, 0)
    end

end

export execute
function execute(cvrp_aux::CvrpAuxiliars, shift::Shift, routes::Array{Route, 1}) # Delta evaluation

    # Update some statistics regarding the move execution
    move.hasMove = false

    # Selecting route
    shift.route = rand(routes)
    
    while (length(shift.route.deliveries) < shift.shift_size)
        shift.route = rand(routes)
    end

    # Chose random string to shift
    local route_size    = length(shift.route.deliveries)
    local unfixed_route = findfirst(x -> x.fixed == false, shift.route.deliveries) 

    if (unfixed_route + shift.shift_size > route_size - 1)
        shift.hasMove = false
        return typemax(Int64)
    end

    # Select closest routes and insertion positions
    # For each insertion position detected, shift delivery
    local original_routes_distance = 0
    local move_routes_distance     = 0
    
    for i = 1:shift.shift_size

        local delivery = shift.string[i]

        local route_index = getClosestRoute(cvrp_aux, deliveries, routes, delivery)
        if (route_index === typemax(Int64))
            shift.hasMove = false;
            return typemax(Int64)
        end
        
        shift.routes[i] = routes[route_index]
        original_routes_distance += shift.routes[i].distance
        shift.insertion_routes_index[i] = route_index
        
        local insertion_position = getBestInsertionPosition(cvrp_aux, shift.routes[i], delivery)
        if (insertion_position === typemax(Int64))
            shift.hasMove = false;
            return typemax(Int64)
        end
        
        shift.predecessors[i] = shift.routes[i].deliveries[insertion_position - 1]
        shift.insertion_positions[i] = insertion_position

        deleteDelivery!(cvrp_aux, shift.route, delivery.visiting_index, delivery.visiting_index)
        pushDelivery!(cvrp_aux, shift.routes[i], delivery, insertion_position)
        move_routes_distance += shift.routes[i].distance

    end

    # Update removal route distance
    shift.move_distance = shift.route.distance

    # Update some statistics regarding the move execution
    move.hasMove = true
    move.total += 1

    # Calculate delta value
    return (shift.move_distance + move_routes_distance) - (shift.original_distance + original_routes_distance)
    
end

export accept
accept(_::CvrpAuxiliars, shift::Shift) = shift.accept += 1

export reject
function reject(cvrp_aux::CvrpAuxiliars, shift::Shift)

    for i = 1:shift.shift_size
        deleteDelivery!(cvrp_aux, shift.routes[i], shift.string[i].visiting_index, shift.string[i].visiting_index)
        pushDelivery!(cvrp_aux, shift.route, shift.string[i], shift.removal_starts_at + i - 1)
    end

    # Update move execution statistics
    move.reject += 1

end