module CVRP_Structures

# TODO: Add typed kwargs to constructors

using Dates
using ParallelKMeans: KmeansResult

###############################
##### Instance Structures #####
###############################
export Point
struct Point
    lng::Float64 # Longitude
    lat::Float64 # Latitude
end

export Delivery
mutable struct Delivery
    id::String # Unique ID
    point::Point # Longitude and Latitude
    size::Int64

    index::Int64
    visiting_index::Int64
    route_index::Int64

    Delivery(attributes...) = begin
        local id    = ""
        local point = Point(0,0)
        local size  = 0
        local index = 0
        local visiting_index = 0
        local route_index    = 0

        isdefined(attributes, 1) ? id    = attributes[1] : nothing
        isdefined(attributes, 2) ? point = attributes[2] : nothing
        isdefined(attributes, 3) ? size  = attributes[3] : nothing
        isdefined(attributes, 4) ? index = attributes[4] : nothing
        isdefined(attributes, 5) ? visiting_index = attributes[5] : nothing
        isdefined(attributes, 6) ? route_index    = attributes[6] : nothing

        return new(id, point, size, index, visiting_index, route_index)
    end
end

export CvrpData
mutable struct CvrpData
    name::String
    region::String
    origin::Point # Longitude and Latitude
    capacity::Int64
    deliveries::Array{Delivery,1}

    min_number_routes::Int64 # The miminum numebr of vehicles to attend all customers

    CvrpData(attributes...) = begin
        local name   = ""
        local region = ""
        local origin = Point(0,0)
        local capacity = 0
        local deliveries = Array{Delivery, 1}()
        local minimum = 0

        isdefined(attributes, 1) ? name   = attributes[1] : nothing
        isdefined(attributes, 2) ? region = attributes[2] : nothing
        isdefined(attributes, 3) ? origin = attributes[3] : nothing
        isdefined(attributes, 4) ? capacity = attributes[4] : nothing
        isdefined(attributes, 5) ? deliveries = attributes[5] : nothing
        isdefined(attributes, 6) ? minimum = attributes[6] : nothing

        return new(name, region, origin, capacity, deliveries, minimum)
    end
end

export CvrpAuxiliars
mutable struct CvrpAuxiliars
    distance_matrix::Array{Float64, 2}
    number_pairs::Int64
    k_adjacent::Array{Array{Pair{Float64,Int64}, 1}, 1} # k adjacent vertices

    CvrpAuxiliars(attributes...) = begin
        local distance_matrix = zeros(Float64, 0, 0)
        local k_adjacent   = Array{Array{Pair{Float64,Int64},1}, 1}()
        local number_pairs = 0

        isdefined(attributes, 1) ? distance_matrix = attributes[1] : nothing
        isdefined(attributes, 2) ? number_pairs    = attributes[2] : nothing
        isdefined(attributes, 3) ? k_adjacent      = attributes[3] : nothing

        return new(distance_matrix, number_pairs, k_adjacent)
    end
end


###############################
##### Solution Structures #####
###############################
export Route
mutable struct Route
    index::Int64
    deliveries::Array{Delivery, 1}
    distance::Float64
    depot::Delivery

    capacity::Int64
    free::Int64
    centroid::Point

    Route(attributes...) = begin
        local index = 0
        local deliveries = Array{Delivery,1}()
        local distance   = 0.0
        local depot::Delivery
        local capacity = 0
        local free = 0
        local centroid = Point(0.0, 0.0)

        isdefined(attributes, 1) ? index      = attributes[1] : nothing
        isdefined(attributes, 2) ? deliveries = attributes[2] : nothing
        isdefined(attributes, 3) ? distance   = attributes[3] : nothing
        isdefined(attributes, 4) ? begin
            if (attributes[4] isa Point)
                depot = Delivery("DEPOT",attributes[4], 0, 0, 1, index)
                
            elseif (attributes[4] isa Delivery)
                depot = attributes[4]
            
            else
                throw("A Depot must be passed as either a Delivery or a Point")
            end

            insert!(deliveries, 1, depot)
        end : throw("A Depot must be passed as either a Delivery or a Point")
        
        isdefined(attributes, 5) ? capacity = attributes[5] : nothing
        isdefined(attributes, 6) ? free     = attributes[6] : free = capacity
        isdefined(attributes, 7) ? centroid = attributes[7] : nothing

        return new(index, deliveries, distance, depot, capacity, free, centroid)
    end
end

export Model # Used in KMeans
mutable struct Model
    centroids::Array{Point, 1}
    model::KmeansResult{Array{Float64,2},Float64,Float64}

    Model(attributes...) = begin
        local centroids = Array{Point, 1}()
        local model::KmeansResult{Array{Float64,2},Float64,Float64}

        isdefined(attributes, 1) ? centroids = attributes[1] : nothing
        isdefined(attributes, 2) ? model     = attributes[2] : throw("Model not defined. Type for model: KmeansResult{Array{Float64,2},Float64,Float64}")

        return new(centroids, model)
    end
end

end # module