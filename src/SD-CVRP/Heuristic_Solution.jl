module Heuristic_Solution

using CVRP_Structures: CvrpData, CvrpAuxiliars, Route
using CVRP_Controllers: getDistance, pushDelivery!
using Neighborhood
using Dates

Controller{Type} = Union{Type, Nothing}

export IlsController
mutable struct IlsController

    initial_timestamp::DateTime
    duration::Int64    
    original_solution::Float64
    edited_solution::Float64
    best_solution::Float64

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

export ils
function ils(instance::CvrpData, cvrp_aux::CvrpAuxiliars, solution::Array{Route, 1}, slot::Int64; ils_controller::Controller{IlsController} = nothing, rna_controller::Controller{RnaController} = nothing)

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

    local moves::Array{Neighbor, 1} = [swap_1x1, swap_2x2, swap_3x3, swap_4x4,
                                       shift_1, shift_2, shift_3, shift_4]


    if (ils_controller === nothing)
        ils_controller = IlsController(Dates.now(), 9e5, solution_cost, solution_cost, solution_cost)
    end 

    if (rna_controller === nothing)
        rna_controller = RnaController(1, 1, length(slot), 0, length(slot), length(slot))
    end 

    while true
        
        while (rna_controller.perturbance <= rna_controller.perturb_max)
            Dates.now() - ils_controller.initial_timestamp > Millisecond(9e5) ? break : nothing
            
            local move = rand(moves)
            execute(cvrp_aux, move, editable_solution)
            accept(cvrp_aux, move)
        end

        Dates.now() - ils_controller.initial_timestamp > Millisecond(9e5) ? break : nothing

        # TODO: RNA

        if (ils_controller.edited_solution <= ils_controller.best_solution)
            # TODO: Update controller.best_solution and solution             
            rna_controller.iter = 0
            rna_controller.perturbance = 0
            
        else
            # TODO: Reject edited_solution by updating it to be like best solution
            rna_controller.iter += 1

        end

        if (rna_controller.iter >= rna_controller.iter_max)
            rna_controller.perturbance += rna_controller.initial_perturb
            
            if (rna_controller.perturbance > rna_controller.perturb_max)
                rna_controller.perturbance = rna_controller.initial_perturb
            end
        end
    end

end

end # module