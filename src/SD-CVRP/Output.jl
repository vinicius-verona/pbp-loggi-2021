module Output

using CVRP_Structures: CvrpData, Route, Point
using OrderedCollections
using JSON


mutable struct SolutionDelivery
    
    id::String
    point::Point # Longitude and Latitude
    size::Int64

end

mutable struct SolutionVehicle

    origin::Point
    deliveries::Array{SolutionDelivery, 1}

end

export generateOutput
function generateOutput(instance::CvrpData, solution::Array{Route, 1}; algorithm::String, additional::String = "", path::String = "")

    local distribution::Array{SolutionVehicle, 1} = []

    for i in solution
        local deliveries::Array{SolutionDelivery, 1} = []

        for j in i.deliveries
            if j.index != 0
                push!(deliveries, SolutionDelivery(j.id, j.point, j.size))
            end
        end

        push!(distribution, SolutionVehicle(i.depot.point, deliveries))
    end
    
    local solution_dict = OrderedDict("name" => instance.name, "vehicles" => distribution)

    local json_solution = JSON.json(solution_dict)
    local output_path = path !== "" ? path : "$(@__DIR__)/../../data/output/"
    
    if (additional !== "")
        write(open("$(output_path)$(instance.name)-$(algorithm)-$(additional).json", "w"), json_solution)
    else
        write(open("$(output_path)$(instance.name)-$(algorithm).json", "w"), json_solution)
    end

end

end # module