module Load_Instance

using JSON
using GZip
import CVRP_Structures: Point, Delivery, CvrpData, CvrpAuxiliars
using DataStructures

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

    # return CvrpAuxiliars(distances, size(distances)[1] * size(distances)[2], generateNearestAdjacent(100, distances))
    return CvrpAuxiliars(distances, size(distances)[1] * size(distances)[2])
end

"""
    generateNearestAdjacent(k_adjance::Int64, distances::Array{Float64, 2})

For all vertices in the instance, a heap with the first nearest *k* adjacent vertices is created.

**Parameters:**
* `k_adjacent` - The number of near adjacent vertices to a given vertex.
* `distances` - A matrix with the distances between all vertices, where each element is the distance from point A to B.
"""
function generateNearestAdjacent(k_adjancent::Int64, distances)
    
    # local n_vertices = size(distances)[1]
    # local adjacent_heap = Array{Array{Pair{Float64,Int64},1}, 1}(undef, n_vertices - 1)
    
    # for i = 2:n_vertices
    #     local heap = BinaryMaxHeap{Pair{Float64,Int64}}()
    #     for j = 2:n_vertices
    #         if i != j
                
    #             if length(heap) == k_adjancent && distances[i,j] < first(heap).first
    #                 pop!(heap)
    #                 push!(heap, Pair(distances[i,j], j - 1)) # Push (Distance, identifier) and to the heap
    #             elseif length(heap) + 1 <= k_adjancent
    #                 push!(heap, Pair(distances[i,j], j - 1)) # Push (Distance, identifier) and to the heap
    #             end
                
    #         end
    #     end
    #     adjacent_heap[i - 1] = reverse!(extract_all!(heap))
    # end
        

    # return adjacent_heap

end

end # module
