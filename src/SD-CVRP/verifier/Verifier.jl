module Verifier

push!(LOAD_PATH, "$(@__DIR__)/../")
using Dates
using CVRP_Structures
using Load_Instance
using CVRP_Controllers: getStringDistance

export verify
function verify(;auxiliar::CvrpAuxiliars, solution::Array{Route, 1})

    println("======> Start verifying if every route starts and end in depot")
    if (verifyRouteStructure(solution))
        println("\t-> Status: [PASSED]")
    else
        println("\t-> Status: [FAILED]")
    end
    
    println("======> Start verifying lack of delivery assignment")
    if (verifyLackAssignment(auxiliar, solution))
        println("\t-> Status: [PASSED]")
    else
        println("\t-> Status: [FAILED]")
    end
    
    println("======> Start verifying double  delivery assignment")
    if (verifyDoubleAssignment(auxiliar, solution))
        println("\t-> Status: [PASSED]")
    else
        println("\t-> Status: [FAILED]")
    end
    
    println("======> Start verifying sum  of delivery sizes")
    if (verifySumSizes(auxiliar, solution))
        println("\t-> Status: [PASSED]")
    else
        println("\t-> Status: [FAILED]")
    end
    
    println("======> Start verifying sum  of delivery distances")
    if (verifySumDistance(auxiliar, solution))
        println("\t-> Status: [PASSED]")
    else
        println("\t-> Status: [FAILED]")
    end

    println()

end

"""
Verify if every route starts and ends at depot.

Cases of failure: 
   - if depot is in the middle of a route
   - if depot there is only one depot in the route
"""
function verifyRouteStructure(solution::Array{Route, 1})::Bool

    local response = true

    foreach(route -> begin
        if (!occursin(lowercase(route.deliveries[begin].id), "depot"))
            response = false
            return response
        end
        if (!occursin(lowercase(route.deliveries[end].id), "depot"))
            response = false
            return response
        end
    end, solution)

    return response

end

"""
Verify if every delivery appears only once in the solution.
"""
function verifyDoubleAssignment(auxiliar::CvrpAuxiliars, solution::Array{Route, 1})::Bool

    local response = true
    local matrix = deepcopy(auxiliar.distance_matrix)

    # In the distance matrix, set the primary diagonal to zero
    local matrix_size = size(matrix)[1]
    for i = 1 : matrix_size
        matrix[i,i] = 0
    end

    # For every delivery, takeaway 1 from distance matrix in the due primary diagonal
    # If at any time, a matrix element (in the main diagonal) is < -1, there is an error
    foreach(route -> begin
        for i in route.deliveries[begin + 1 : end - 1]
            local idx = i.index
            matrix[idx, idx] -= 1

            if (matrix[idx, idx] < -1)
                response = false
                return response
            end
        end
    end, solution)

    return response

end

"""
Verify if every delivery appears in the solution.
"""
function verifyLackAssignment(auxiliar::CvrpAuxiliars, solution::Array{Route, 1})::Bool

    local response = true
    local matrix = deepcopy(auxiliar.distance_matrix)

    # In the distance matrix, set the primary diagonal to zero
    local matrix_size = size(matrix)[1]
    for i = 1 : matrix_size
        matrix[i,i] = 0
    end

    # For every delivery, takeaway 1 from distance matrix in the due primary diagonal
    foreach(route -> begin
        for i in route.deliveries[begin + 1 : end - 1]
            local idx = i.index
            matrix[idx, idx] -= 1
        end
    end, solution)

    # If at any time, a matrix element (in the main diagonal) is = 0, there is an error
    for i = 2 : matrix_size
        if (matrix[i,i] === 0)
            response = false
            return response
        end
    end

    return response

end

"""
Verify if sum of delivery sizes per route does not exceed capacity.
"""
function verifySumSizes(auxiliar::CvrpAuxiliars, solution::Array{Route, 1})::Bool

    local response = true
    foreach(route -> begin
        local size = 0
        for i in route.deliveries
            size += i.size
        end

        if (size > route.capacity)
            response = false
            return response
        end
    end, solution)

    return response

end

"""
Verify if the sum of route distances matches the sum of route actual driven path.

Cases of failure: 
  - if current route distance field does not match the actual driven distance by the route
"""
function verifySumDistance(auxiliar::CvrpAuxiliars, solution::Array{Route, 1})::Bool
    
    local response = true

    foreach(route -> begin
        if (abs(route.distance - getStringDistance(auxiliar, route.deliveries)) > 0.00001)
            response = false
            return response
        end
    end, solution)

    return response

end

end # module

#=
function verify(;input::String="")

    println("\n======> Start loading instance data")
    local instance  = loadInstance(input)
    local auxiliars = loadDistanceMatrix(instance.name)
    println("=> Instance name     : ", instance.name)
    println("=> Instance region   : ", instance.region)
    println("=> Instance capacity : ", instance.capacity)
    println("=> Instance # of deliveries   : ", length(instance.deliveries))
    println("=> Instance min # of vehicles : ", instance.min_number_routes, " routes")
    
    
    println("\n======> Start loading solution data")
    println("\n======> Start verifying double  delivery assignment")
    println("\n======> Start verifying lack of delivery assignment")
    println("\n======> Start verifying sum  of delivery sizes")
    println("\n======> Start verifying sum  of delivery distances")

end


if abspath(PROGRAM_FILE) == @__FILE__

    if (length(ARGS) === 0 || ARGS[1] === "" || match(r".+\.json", ARGS[1]) === nothing)
        throw("An input JSON file has not been passed as argument! Syntax: julia verifier.jl path/to/instance.json")
    end

    verify(input=ARGS[1])

end
=#