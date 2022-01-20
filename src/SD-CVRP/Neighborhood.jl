module Neighborhood

using CVRP_Structures: CvrpAuxiliars
using CVRP_Controllers: getInsertionDistance, getDistance, pushDelivery!, 
                        deleteDelivery!, getStringSize, getBestInsertionPosition, getClosestRoute

export Neighbor
abstract type Neighbor end

RouteOrNothing  = Union{Route, Nothing}
RoutesOrNothing = Union{Array{Route,1}, Nothing}

include("SwapDeliveries.jl")
include("ShiftDeliveries.jl")

end # module