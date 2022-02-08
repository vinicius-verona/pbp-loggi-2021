module Cluster_Instance

using ParallelKMeans
using Random
using JSON
using Load_Instance: loadInstance
using CVRP_Structures: Point, Model, CvrpData, Delivery
using CVRP_Controllers: getDistance

export train
"""
    train(region::String="df-0", initial_day::Int64=0; limit_day::Int64=89)

For a given region, read instances starting at day `initial_day` and stopping at `limit_day`.
With each instance, store enough information to create a cluster and facilitate finding vehicles
to service a client.
In case there is an instance between `initial_day` and `limit_day` that should not be considered,
use the `except::Int64` parameter.
"""
function train(region::String="df-0"; initial_day::Int64=0, limit_day::Int64=89, except::Int64=0)
    
    # Load directory
    local train_dir   = "$(@__DIR__)/../../data/input/train/$region"
    local train_files = readdir(train_dir, sort=true)
    local inverse_region = "$(split(region, "-")[2])-$(split(region, "-")[1])"

    function deleteInstance(day::String)
        local removed_json = split(day, ".json")[1]
        day = split(removed_json, "cvrp-$inverse_region-")[2]
        
        local lt = parse(Int64, day) < initial_day
        local gt = parse(Int64, day) > limit_day
        local eq = parse(Int64, day) == except

        return (lt || gt || eq)
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

    # Read instance and store points
    local points::Array{Array{Float64,1},1} = []
    local number_of_routes = 0

    for i in train_files[1:end]
        local instance_data = getInstanceData(loadInstance("$train_dir/$i"))
        points = cat(points, instance_data[1], dims=1)
        number_of_routes += instance_data[2]
    end

    number_of_routes = Int(round(number_of_routes / length(train_files), RoundUp))

    # Create model by clustering delivery points of training instances
    local matrix = hcat(points...)
    local rng    = Random.seed!(1)
    local model  = kmeans(Yinyang(), matrix, number_of_routes; rng=rng)
    local centroids = extractCentroids(model.centers)


    return Model(centroids, model)

end

export predict
"""
    predict(centroids::Array{Point, 1}, delivery::Delivery)

For a given delivery, predict in which clustered region does the delivery belong to.

**Parameters:**
* `centroids` - Array with the coordinates for each cluster centroid.
* `delivery` - Delivery that must be fit to a region.

**Returns:**
* `::Point` - A reference to the selected centroid.
"""
@inline function predict(centroids::Array{Point, 1}, delivery::Delivery)

    local center::Point = Point(0.0, 0.0)
    local min_dist = typemax(Float64)
    
    foreach(centroid -> begin
        local dist = getDistance(centroid, delivery.point)
        (dist < min_dist) ? (center = centroid; min_dist = dist) : nothing
    end, centroids)
    
    return center

end

"""
    getInstanceData(instance::CvrpData)

For a given instance, return delivery points (`Array{Array{Float64,1},1}`) and the instance's minimum number of routes.
"""
function getInstanceData(instance::CvrpData)

    local points::Array{Array{Float64,1},1} = []
    local size = 0
    for d in instance.deliveries
        size += d.size
        push!(points, [d.point.lat;d.point.lng])
    end

    return points, Int(round(size/instance.capacity, RoundUp))

end

"""
    extractCentroids(matrix::Array{Float64, 2})

For a given matrix of centroids, create and return an array of type `Point` with each centroid coordinates.
"""
function extractCentroids(matrix::Array{Float64, 2})

    local centroids = Array{Point, 1}()
    local length = size(matrix)[2]
    
    for i = 1:length
        push!(centroids, Point(matrix[2,i], matrix[1,i]))
    end

    return centroids
    
end

end # module
