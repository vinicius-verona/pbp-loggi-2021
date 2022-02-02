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

#-----------------------------#
#          Algorithm          #
#-----------------------------#

export ils
function ils(cvrp_aux::CvrpAuxiliars, solution::Array{Route, 1}, slot_deliveries::Array{Delivery, 1}; ils_controller::Controller{IlsController} = nothing, rna_controller::Controller{RnaController} = nothing, execution_time::Int64 = Int(6e4))

    if (length(solution) == 1)
        @warn "There is only one route, therefore, as there is no intra-route neighbors (yet), the heuristic will not execute."
        return solution
    elseif (length(solution) <= 5)
        @warn "There are too few routes, there is a chance the neighbors will take too long selecting routes. Consider increasing the number of routes."
    end

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

    # local moves::Array{Neighbor, 1} = [shift_2]
    local moves::Array{Neighbor, 1} = [swap_1x1, swap_2x2, swap_3x3, swap_4x4]
    # local moves::Array{Neighbor, 1} = [shift_1, shift_2, shift_3, shift_4]
    # local moves::Array{Neighbor, 1} = [swap_1x1, swap_2x2, swap_3x3, swap_4x4,
                                    #    shift_1, shift_2, shift_3, shift_4]

    if (ils_controller === nothing)
        if (slot_deliveries === nothing)
            throw("Error! When an ILS controller is not defined, an array of avaliable (editable) deliveries is required.")
        end
        
        ils_controller = IlsController(Dates.now(), execution_time, solution_cost, solution_cost, solution_cost, moves, editable_deliveries, slot_deliveries)
    
    elseif (ils_controller.moves === nothing)
        ils_controller.moves = moves
    end
    
    if (rna_controller === nothing)
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
    
    while true
        
        Dates.now() - ils_controller.initial_timestamp > Millisecond(ils_controller.duration) ? break : nothing
        
        for i = 1:rna_controller.perturbance
            Dates.now() - ils_controller.initial_timestamp > Millisecond(ils_controller.duration) ? break : nothing
            
            local move = rand(ils_controller.moves)
            local cost = execute(cvrp_aux, move, editable_solution, ils_controller.editable_deliveries)
            
            if (move.hasMove)
                accept(cvrp_aux, move, editable_solution)
                ils_controller.edited_solution += cost
            else
                i -= 1
            end

        end
        
        Dates.now() - ils_controller.initial_timestamp > Millisecond(ils_controller.duration) ? break : nothing

        rna(cvrp_aux, editable_solution, ils_controller, rna_controller)

        if (ils_controller.edited_solution <= ils_controller.best_solution)
            # println(ils_controller.edited_solution) 
            # println(ils_controller.best_solution)
            # println()
            # Update controller.best_solution and solution
            copyRoute!(editable_solution, ils_controller.slot_deliveries, solution)
            ils_controller.best_solution = ils_controller.edited_solution
            rna_controller.iter = 0
            rna_controller.perturbance = 0

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

    return solution

end

export rna
function rna(cvrp_aux::CvrpAuxiliars, solution::Array{Route, 1}, ils_controller::IlsController, rna_controller::RnaController)
    
    local i = 1
    while i < rna_controller.rna_max

        i += 1

        Dates.now() - ils_controller.initial_timestamp > Millisecond(ils_controller.duration) ? break : nothing

        local move = rand(ils_controller.moves)
        local cost = execute(cvrp_aux, move, solution, ils_controller.editable_deliveries)

        if (cost <= 0 && move.hasMove)
            accept(cvrp_aux, move, solution)
            
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