module Heuristic_Solution

using CVRP_Structures: CvrpData, CvrpAuxiliars, Route
using CVRP_Controllers: getDistance, pushDelivery!
using Dates

export ils
function ils(instance::CvrpData, cvrp_aux::CvrpAuxiliars, solution::Array{Route, 1})

    local editable_solution = deepcopy(solution)
    
    local swap_1x1 = Swap(1, 1)
    local swap_1x2 = Swap(1, 2)
    local swap_2x1 = Swap(2, 1)
    local swap_2x2 = Swap(2, 2)
    
    local shift_1  = Shift(1)
    local shift_2  = Shift(2)
    local shift_3  = Shift(3)
    local shift_4  = Shift(4)

    local moves::Array{Neighborhood, 1} = [swap_1x1, swap_1x2, swap_2x1, swap_2x2,
                                           shift_1, shift_2, shift_3, shift_4]
    
    local controller = IlsController()
end

end # module