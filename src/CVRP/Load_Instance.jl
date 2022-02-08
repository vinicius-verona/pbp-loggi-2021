module Load_Instance

using JSON
using GZip
import CVRP_Structures: Point, Delivery, CvrpData, CvrpAuxiliars

export loadInstance
"""
    loadInstance(input::String)::CvrpData

Read JSON instance.

**Parameters:**
* `input` - CVRP instance.

**Returns:**
* `data` - returns the dictionary parsed into `CvrpData` type
"""
function loadInstance(input::String)::CvrpData
    
    let file = JSON.parse(open(input, "r"))
        local name   = file["name"]
        local region = file["region"]
        local origin = Point(file["origin"]["lng"], file["origin"]["lat"])
        local capacity = file["vehicle_capacity"]
        local sum_sizes = 0
        
        # Deliveries
        local deliveries = Array{Delivery, 1}()
        local index = 0
        for i in file["deliveries"]
            index += 1
                    
            local id    = i["id"]
            local point = Point(i["point"]["lng"], i["point"]["lat"])
            local size  = i["size"]
            sum_sizes  += (size/capacity)
            
            push!(deliveries, Delivery(id, point, size, index, 0, 0))
        end

        return CvrpData(name, region, origin, capacity, deliveries, Int64(round(sum_sizes, RoundUp)))
    end

end

export loadDistanceMatrix
"""
    loadDistanceMatrix(instance::String)::CvrpAuxiliars

Load zipped precompiled distance matrix for a given instance.

**Parameters:**
* `instance` - CVRP instance name.

**Returns:**
* `cvrp_auxiliar` - returns the generated auxiliar data (number of pairs and distance matrix)
"""
function loadDistanceMatrix(instance::String)::CvrpAuxiliars
    local file = GZip.open("$(@__DIR__)/../../data/DistanceMatrix/$instance.json.gz")
    local parsed_file = JSON.parse(file)
    distances = reduce(hcat, parsed_file["Distance_Table"])

    return CvrpAuxiliars(distances, size(distances)[1] * size(distances)[2])
end

end # module
