module Neighborhood

using CVRP_Structures: CvrpAuxiliars
using CVRP_Controllers

export Neighbor
abstract type Neighbor end

include("Neighborhood/SwapDeliveries.jl")
include("Neighborhood/ShiftDeliveries.jl")

end # module