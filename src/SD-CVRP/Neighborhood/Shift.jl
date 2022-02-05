using CVRP_Structures: CvrpData, CvrpAuxiliars, Route, Delivery
using CVRP_Controllers: getDistance, pushDelivery!, deleteDelivery!,
                        getBestInsertionPosition, getClosestRoute,
                        getStringSize, getStringDistance, getInsertionDistance,
                        deleteRoute!


using JSON # DEBUG
using OrderedCollections # DEBUG

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

# _debug = nothing

export execute
function execute(cvrp_aux::CvrpAuxiliars, shift::Shift, routes::Array{Route, 1}, deliveries::Array{Delivery, 1}) # Delta evaluation

    # global _debug = deepcopy(routes)

    # Update some statistics regarding the move execution
    shift.hasMove = false

    # Reset values
    # shift = Shift(shift.shift_size)
    shift.route      = nothing
    shift.routes     = Array{Delivery, 1}(undef, shift.shift_size)
    shift.removal_positions   = zeros(Int64, shift.shift_size)
    shift.insertion_positions = zeros(Int64, shift.shift_size)
    shift.insert_routes_index = zeros(Int64, shift.shift_size)
    shift.string         = Array{Delivery, 1}(undef, 0)
    shift.predecessors   = Array{Delivery, 1}(undef, shift.shift_size)
    shift.original_size  = 0
    shift.original_sizes = zeros(Int64, shift.shift_size)
    shift.move_size  = 0
    shift.move_sizes = zeros(Int64, shift.shift_size)
    shift.original_distance  = 0
    shift.original_distances = zeros(Float64, shift.shift_size)
    shift.move_distance  = 0
    shift.move_distances = zeros(Float64, shift.shift_size)

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
    shift.original_distance = getStringDistance(cvrp_aux, shift.route.deliveries)

    # Select closest routes and insertion positions
    # For each insertion position detected, shift delivery
    local original_routes_distance = 0
    local move_routes_distance     = 0

    local route_indexes = []
    for i = 1:shift.shift_size

        local delivery = shift.string[i]

        local route_index = getClosestRoute(cvrp_aux, deliveries, routes, delivery)
        if (route_index === typemax(Int64) || route_index === shift.route.index)
            if (i == 1)
                shift.hasMove = false
                return typemax(Int64)
            else
                shift.hasMove = true
                return typemax(Int64)
            end
        end
        
        shift.routes[i] = routes[route_index]

        if (!(route_index in route_indexes))
            original_routes_distance += shift.routes[i].distance
        end

        shift.insert_routes_index[i] = route_index
        
        local insertion_position = getBestInsertionPosition(cvrp_aux, shift.routes[i], delivery)
        if (insertion_position === typemax(Int64))
            if (i == 1)
                shift.hasMove = false
            else
                shift.hasMove = true
            end

            return typemax(Int64)
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

    # # Debug
    # local _original_routes_distance = 0
    # for i in route_indexes
    #     _original_routes_distance += _debug[i].distance
    # end
    # if (abs(_original_routes_distance - original_routes_distance) > 1e-5)
    #     throw("Diff")
    # end
    # #######

    # println("Rotas: ", route_indexes, " - Length of routes: ", length(shift.routes), " - Routes: ", map(x->x.index, shift.routes))
    # println("insert_routes_index: ", shift.insert_routes_index)

    # Update removal route distance
    shift.move_distance = shift.route.distance

    # Update some statistics regarding the move execution
    shift.hasMove = true
    shift.total += 1

    # println("Move Dist: $(shift.move_distance)")
    # println("Move Dists: $(move_routes_distance)")

    # println("Orig Dist: $(shift.original_distance)")
    # println("Orig Dists: $(original_routes_distance)")
    # println((shift.move_distance + move_routes_distance) - (shift.original_distance + original_routes_distance))

    # Calculate delta value
    return (shift.move_distance + move_routes_distance) - (shift.original_distance + original_routes_distance)
    
end

export accept
function accept(_::CvrpAuxiliars, shift::Shift, solution::Array{Route, 1}, cost::Float64)

    shift.accept += 1
    
    if (length(shift.route.deliveries) <= 2)
        cost -= shift.route.distance
        deleteRoute!(shift.route.index, solution)
    end

    return cost

end

export reject
function reject(cvrp_aux::CvrpAuxiliars, shift::Shift)

    for i = 1:shift.shift_size
        if (isassigned(shift.string, i) && shift.string[i].route_index !== shift.route.index)
            deleteDelivery!(cvrp_aux, shift.routes[i], shift.string[i].visiting_index)
            pushDelivery!(cvrp_aux, shift.route, shift.string[i], shift.removal_positions[i])
        end
    end

    # Update move execution statistics
    shift.reject += 1

end