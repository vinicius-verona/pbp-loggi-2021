module Load_instance
using JSON
import CVRP_Structures: Point, Delivery, CvrpData

export loadInstance
"""
    loadInstance(input::String)

Read JSON instance.

**Parameters:**
* `input` - CVRP instance.

**Returns:**
* `data` - returns the dictionary parsed into `CvrpData` type
"""
function loadInstance(input::String)
    
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

end # module
