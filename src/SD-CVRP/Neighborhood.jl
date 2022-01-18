module Neighborhood

using CVRP_Structures: CvrpAuxiliars
using CVRP_Controllers

export Neighbor
abstract type Neighbor end

include("SwapDeliveries.jl")
include("ShiftDeliveries.jl")

end # module