module Cluster_Instance

using ParallelKMeans
using Random
using JSON
using Load_Instance: loadInstance
import CVRP_Structures: Point

export train
"""
    train(region::String="df-0", initial_day::Int64=0; limit_day::Int64=89)
"""
function train(region::String="df-0", initial_day::Int64=0, limit_day::Int64=89)
    
    # Load directory
    local train_dir   = "$(@__DIR__)/../data/input/train/$region"
    local train_files = readdir(train_dir, sort=true)
    local inverse_region = "$(split(region, "-")[2])-$(split(region, "-")[1])"

    function deleteInstance(day::String)
        local removed_json = split(day, ".json")[1]
        day = split(removed_json, "cvrp-$inverse_region-")[2]
        
        local lt = parse(Int64, day) < initial_day
        local gt = parse(Int64, day) > limit_day

        return (lt || gt)
    end

    # Remove instance before initial day and after limit day
    local counter = 1
    for _ = 1:length(train_files)
        
        if (deleteInstance(train_files[counter]))
            local position = findfirst(x->x==train_files[counter], train_files)
            deleteat!(train_files, position)

        else
            counter += 1
        end
        
    end

    # Read instance and store
    local points::Array{Array{Point,1}, 1} = []
    for i in train_files
        push!(points, map(x-> x.point, loadInstance("$train_dir/$i").deliveries))
    end

end

end # module
