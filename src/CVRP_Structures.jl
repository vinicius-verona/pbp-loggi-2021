module CVRP_Structures

# Instance Structures
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
end

end # module