module Heuristic_Solution

using CVRP_Structures: CvrpData, CvrpAuxiliars, Route, Delivery, Controller
using CVRP_Controllers: copyRoute!, getStringDistance, getDistance
using Neighborhood
using Dates
using Random

export IlsController
mutable struct IlsController

    initial_timestamp::DateTime
    duration::Int64    
    original_solution::Float64
    edited_solution::Float64
    best_solution::Float64

    moves::Controller{Array{Neighbor, 1}}
    editable_deliveries::Array{Delivery, 1} # Synced to every move
    slot_deliveries::Array{Delivery, 1} # Synced to best solution

end

export RnaController
mutable struct RnaController
    
    perturbance::Int64
    initial_perturb::Int64
    perturb_max::Int64
    iter::Int64
    iter_max::Int64
    rna_max::Int64

end

INITIAL_TIMESTAMP = 0
DEBUG = 0

#-----------------------------#
#          Algorithm          #
#-----------------------------#

export ils
function ils(cvrp_aux::CvrpAuxiliars, solution::Array{Route, 1}, slot_deliveries::Array{Delivery, 1}; ils_controller::Controller{IlsController} = nothing, rna_controller::Controller{RnaController} = nothing)

    Random.seed!(1)

    local editable_deliveries = deepcopy(slot_deliveries)
    local editable_solution = deepcopy(solution)
    local solution_cost = sum(map(x->x.distance, editable_solution))

    local swap_1x1 = Swap(1)
    local swap_2x2 = Swap(2)
    local swap_3x3 = Swap(3)
    local swap_4x4 = Swap(4)
    
    local shift_1  = Shift(1)
    local shift_2  = Shift(2)
    local shift_3  = Shift(3)
    local shift_4  = Shift(4)

    # local moves::Array{Neighbor, 1} = [swap_2x2]
    # local moves::Array{Neighbor, 1} = [swap_1x1, swap_2x2, swap_3x3, swap_4x4]
    local moves::Array{Neighbor, 1} = [shift_1, shift_2, shift_3, shift_4]
    # local moves::Array{Neighbor, 1} = [swap_1x1, swap_2x2, swap_3x3, swap_4x4,
                                    #    shift_1, shift_2, shift_3, shift_4]

    if (ils_controller === nothing)
        if (slot_deliveries === nothing)
            throw("Error! When an ILS controller is not defined, an array of avaliable (editable) deliveries is required.")
        end
        
        ils_controller = IlsController(Dates.now(), 9e4, solution_cost, solution_cost, solution_cost, moves, editable_deliveries, slot_deliveries)
    
    elseif (ils_controller.moves === nothing)
        ils_controller.moves = moves
    end
    
    if (rna_controller === nothing)
        # rna_controller = RnaController(1, 1, length(slot), 0, length(slot), length(slot))
        rna_controller = RnaController(1, 1, Int(round(length(slot_deliveries) / 3, RoundDown)), 0, Int(round(length(slot_deliveries) / 3, RoundDown)), Int(round(length(slot_deliveries) / 3, RoundDown)))
    end

    if (ils_controller.slot_deliveries === nothing)
        throw("Error! An array of avaliable (editable) deliveries is required.")
    end

    # Link deliveries-solution to ensure that when a solution is modified,
    # the modificiation is reflected to the used deliveries. 
    linkCopy!(slot_deliveries, solution)
    linkCopy!(editable_deliveries, editable_solution)
    
    ils_controller.initial_timestamp = Dates.now()

    global INITIAL_TIMESTAMP = Dates.now()
    while true
        
        Dates.now() - ils_controller.initial_timestamp > Millisecond(9e4) ? break : nothing
        
        # for i = 1:rna_controller.perturbance
            # Dates.now() - ils_controller.initial_timestamp > Millisecond(9e4) ? break : nothing
            
            # local move = rand(ils_controller.moves)
            # local cost = execute(cvrp_aux, move, editable_solution, ils_controller.editable_deliveries)
            # if (move.hasMove)
            #     # println("Before accept: ", ils_controller.edited_solution)
            #     accept(cvrp_aux, move)
            #     ils_controller.edited_solution += cost
            #     # println("After  accept: ", ils_controller.edited_solution)
            # else
            #     i -= 1
            # end

        # end
        
        Dates.now() - ils_controller.initial_timestamp > Millisecond(9e4) ? break : nothing

        rna(cvrp_aux, editable_solution, ils_controller, rna_controller)

        if (ils_controller.edited_solution <= ils_controller.best_solution)
            # local less = false
            # println("Improved from $(ils_controller.best_solution) to $(ils_controller.edited_solution) -> Solution: $(sum(map(x -> x.distance, solution))) - Edited: $(sum(map(x -> x.distance, editable_solution)))")
            # if (ils_controller.edited_solution < ils_controller.best_solution)
            #     less = true
            # end
            
            # Update controller.best_solution and solution
            copyRoute!(editable_solution, ils_controller.slot_deliveries, solution)
            ils_controller.best_solution = ils_controller.edited_solution
            rna_controller.iter = 0
            rna_controller.perturbance = 0

            # if (less && ils_controller.edited_solution == ils_controller.best_solution)
            #     println("After Improved from $(ils_controller.best_solution) to $(ils_controller.edited_solution) -> Solution: $(sum(map(x -> x.distance, solution))) - Edited: $(sum(map(x -> x.distance, editable_solution)))")
            #     exit()
            # end

            #DEBUG
            for route in solution
                if (abs(route.distance/1000 - getStringDistance(cvrp_aux, route.deliveries)/1000) > 1e-5)
                    error = "Different Distance: Route($(route.distance / 1000) KM) | String($(getStringDistance(cvrp_aux, route.deliveries) / 1000) KM)"
                    
                    local sum = 0
                    for i = 1:length(route.deliveries)-1
                        sum += getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1])
                        println("From $(route.deliveries[i].index) to $(route.deliveries[i+1].index) sums $(getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1]))")
                    end
                    println()
                    
                    println("SUM: $sum - ORIGINAL SUM: $(route.distance)")
                    println()
                    throw(error)
                end
            end
            #END DEBUG
            
        else
            # Reject edited_solution by updating it to be like best solution
            copyRoute!(solution, ils_controller.editable_deliveries, editable_solution)
            ils_controller.edited_solution = ils_controller.best_solution
            rna_controller.iter += 1
        end

        if (rna_controller.iter >= rna_controller.iter_max)
            rna_controller.perturbance += rna_controller.initial_perturb
            
            if (rna_controller.perturbance > rna_controller.perturb_max)
                rna_controller.perturbance = rna_controller.initial_perturb
            end
        end
    end

    for i in moves
        println("ID: $(i.id)")
        println("accept: $(i.accept)")
        println("reject: $(i.reject)")
        println("improvements: $(i.improvements)")
        println("worsens : $(i.worsens)")
        println("sideways: $(i.sideways)")
        println("total: $(i.total)")
        println()
    end

    return solution

end

export rna
function rna(cvrp_aux::CvrpAuxiliars, solution::Array{Route, 1}, ils_controller::IlsController, rna_controller::RnaController)
    
    local i = 1
    while i < rna_controller.rna_max

        i += 1

        Dates.now() - INITIAL_TIMESTAMP > Millisecond(9e4) ? break : nothing

        local move = rand(ils_controller.moves)
        local cost = execute(cvrp_aux, move, solution, ils_controller.editable_deliveries)

        if (cost <= 0 && move.hasMove)
            # println("Iter $i has cost < 0. Cost: ", cost)
            accept(cvrp_aux, move, solution)
            
            #DEBUG
            for route in solution
                if (abs(route.distance/1000 - getStringDistance(cvrp_aux, route.deliveries)/1000) > 1e-5)
                    error = "Different Distance: Route($(route.distance / 1000) KM) | String($(getStringDistance(cvrp_aux, route.deliveries) / 1000) KM)"
                    
                    println(move.id)
                    local sum = 0
                    for i = 1:length(route.deliveries)-1
                        sum += getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1])
                        println("From $(route.deliveries[i].index) to $(route.deliveries[i+1].index) sums $(getDistance(cvrp_aux, route.deliveries[i], route.deliveries[i+1]))")
                    end
                    
                    println("SUM: $sum - ORIGINAL SUM: $(route.distance)")
                    println()
                    throw(error)
                end
            end
            #END DEBUG
            
            ils_controller.edited_solution += cost
            
            if (cost < 0)
                i = 1
            end
            
            if (ils_controller.edited_solution < ils_controller.best_solution)
                move.improvements += 1
            else
                move.sideways += 1
            end
        
        else
            if (move.hasMove)
                reject(cvrp_aux, move)
            end
        end

    end

    # if (ils_controller.edited_solution < ils_controller.best_solution)
        # println("##### EXIT RNA #### - COST = $(ils_controller.edited_solution) - BEST COST = $(ils_controller.best_solution)")
    # end

end

function linkCopy!(deliveries::Array{Delivery, 1}, solution::Array{Route, 1})

    foreach(route -> begin
        for i = 2:length(route.deliveries) - 1
            delivery = route.deliveries[i]
            route.deliveries[i] = deliveries[delivery.index]
        end
    end, solution)

end

end # module