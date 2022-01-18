RouteOrNothing = Union{Route, Nothing}

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

    Swap(attributes...) = begin
        local swap_size = 1
        local id = "Swap-default"
        local hasMove = false
        local first_route  = nothing
        local second_route = nothing
        local r1_starts_at = -1
        local r2_starts_at = -1
        local r1_ends_at = -1
        local r2_ends_at = -1
        local original_size1 = 0
        local original_size2 = 0
        local move_size1 = 0
        local move_size2 = 0
        local original_distance1 = 0
        local original_distance2 = 0
        local move_distance1 = 0
        local move_distance2 = 0

        isdefined(attributes,  1) ? id = attributes[1] : nothing
        isdefined(attributes,  2) ? hasMove = attributes[2] : nothing
        isdefined(attributes,  3) ? begin
            swap_size = attributes[3]
            id === "Swap-default" ? id = "Swap-$swap_size" : nothing
        end : nothing
        isdefined(attributes,  4) ? first_route  = attributes[4] : nothing
        isdefined(attributes,  5) ? second_route = attributes[5] : nothing
        isdefined(attributes,  6) ? r1_starts_at = attributes[6] : nothing
        isdefined(attributes,  7) ? r2_starts_at = attributes[7] : nothing
        isdefined(attributes,  8) ? r1_ends_at   = attributes[8] : nothing
        isdefined(attributes,  9) ? r2_ends_at   = attributes[9] : nothing
        isdefined(attributes, 10) ? original_size1 = attributes[10] : nothing
        isdefined(attributes, 11) ? original_size2 = attributes[11] : nothing
        isdefined(attributes, 12) ? move_size1 = attributes[12] : nothing
        isdefined(attributes, 13) ? move_size2 = attributes[13] : nothing
        isdefined(attributes, 14) ? original_distance1 = attributes[14] : nothing
        isdefined(attributes, 15) ? original_distance2 = attributes[15] : nothing
        isdefined(attributes, 16) ? move_distance1 = attributes[16] : nothing
        isdefined(attributes, 17) ? move_distance2 = attributes[17] : nothing

        return new(id, hasMove, swap_size, first_route, second_route, r1_starts_at,
                   r2_starts_at, r1_ends_at, r2_ends_at, original_size1, original_size2,
                   move_size1, move_size2, original_distance1, original_distance2, move_distance1,
                   move_distance2, 0, 0, 0, 0, 0, 0)
    end

end

export execute
function execute(problem::CvrpData, cvrp_aux::CvrpAuxiliars, ) # Delta evaluation

    # 1 - Select a route
    # 2 - Select another route
    # 3 - If both routes have the same indexer or one does not have deliveries, repeat 1/2

    # 4 - Select `n` from first route where all `n` must have fixed=false
    # 5 - Select `m` from second route where all `m` must have fixed=false

    # 6  - Get the value of the selected string in the first route -> function
    # 7  - Get the value of the selected string in the second route -> function
    # 8  - Get value of removing the string in the first route -> function
    # 9  - Get value of removing the string in the second route -> function
    # 10 - Get value of inserting first string into second route -> function
    # 11 - Get value of inserting second string into first route -> function
    # 12 - Update index for each delivery inserted and neighbor to inserted string -> function
    
end

export accept
function accept()

    # 1 - Remove frist string in first route -> function
    # 2 - Insert frist string in second route -> function
    # 3 - Remove second string in second route -> function
    # 4 - Insert second string in first route -> function

end

export reject
function reject()
    # Update statistics
end