# This file generates a latex format table comparison in 4 different files
#
# - File 1: Execution time for each algorithm
#           |- Train + greedy - Algorithm 1
#           |- ClarkeWright + ILS [Solver] - Algorithm 2
#           |- Solver + LKH - Algorithm 3
#
# - File 2: Final Solution value compared to the classic CVRP solution
#           |- Train + greedy - Algorithm 1
#           |- ClarkeWright + ILS [Solver] - Algorithm 2
#           |- Solver + LKH - Algorithm 3
#           |- classic CVRP Solution
#
# - File 3: Solution compared to the classic CVRP solution regarding number of vehicles/routes used
#           |- Train + greedy - Algorithm 1
#           |- ClarkeWright + ILS [Solver] - Algorithm 2
#           |- Minimum possible
#
# - File 4: Best Solution GAP to the classic CVRP
#           |- Algorithm
#           |- Best Solution
#           |- GAP to CVRP Solution

# One instance has
#   - 4 comparison types

# Each comparison type has
#   - type name
#   - multiple values -> (Algorithm, value)

module ResultComparison

using Dates

TypeNull{_Type} = Union{_Type,Nothing}

mutable struct Algorithm

    name::String
    start::DateTime
    stop::DateTime
    length::Int64 # Regarding number of vehicles/routes used
    value::Float64

    Algorithm(;
        name::String = "",
        start::DateTime = Dates.now(),
        stop::DateTime = Dates.now(),
        length::Int64 = 0,
        value::Float64 = 0.0,
    ) = new(name, start, stop, length, value)

end

ComparisonData = TypeNull{Pair{String,Real}}
mutable struct Data

    comparison_type::String
    values::Array{ComparisonData,1}

    Data(type::String; cols::Int64 = 0) = new(type, Array{ComparisonData,1}(nothing, cols))

end

InstanceData = TypeNull{Data}
mutable struct Instance

    name::String
    size::Int64 # Number of deliveries
    minimum::Int64 # Numebr of vehicles/routes
    comparisons::Array{InstanceData,1}

    Instance(name::String = ""; size::Int64 = 0, minimum::Int64 = 0) =
        new(name, size, minimum, Array{InstanceData,1}(nothing, size))

end

_table_template(; cols_config::String = "", header::String = "", body)::String =
"""
 \\begin{table}[]
     \\centering

     \\begin{tabular}{$cols_config}
         \\toprule
         $header

         \\hline
         $body

         \\bottomrule
     \\end{tabular}
 \\end{table}
"""

_calculate_gap(; best::Real, solution::Real) = (solution - best) / best

# The classic CVRP solution parsed as `::Algorithm` must be the last element of `algorithms`
function _compare_values(algorithms::Array{Algorithm,1})::Array{Data,1}

    local time_type = Data("time", cols = length(algorithms))
    local distance_type = Data("distance", cols = length(algorithms))
    local length_type = Data("length", cols = length(algorithms))
    local gap_type = Data("gap", cols = 2)

    for (index, alg) in enumerate(algorithms)
        time_type.values[index] = Pair(alg.name, Dates.value(alg.stop - alg.start) / 1000)
        distance_type.values[index] = Pair(alg.name, alg.value)
        length_type.values[index] = Pair(alg.name, alg.length)
    end

    local minimum = typemax(Float64)
    local best = nothing

    foreach(_value -> begin
        if (_value.second < minimum)
            minimum = _value.second
            best = _value
        end
    end, distance_type.values[begin:end-1])

    # Calculate GAP variation
    gap_type.values[1] = best
    local gap = _calculate_gap(best = algorithms[end].value, solution = best.second)
    gap_type.values[2] = Pair("GAP", gap)

    return [time_type, distance_type, length_type, gap_type]

end

export parse_data
function parse_data(filename::String)::Instance

    local instance = Instance()
    local algorithms::Array{Algorithm,1} = []
    local LAST_ALGORITHM = 20

    let file = readlines(open(filename, "r"))
        local pattern = r" *\.*" # Remove space and . from the name
        instance.name = replace(split(file[3], ": ")[2], pattern => "")
        instance.size = parse(Int64, split(file[6], ": ")[2])

        pattern = r"([0-9]++\.?)++"
        instance.minimum = parse(Int64, match(pattern, file[7]).match)

        local line = 10
        local value = LAST_ALGORITHM + 5

        while (line <= LAST_ALGORITHM)

            local alg = Algorithm()
            pattern = r"( *)++" # Remove space and . from the name
            alg.start = parse(Dates.DateTime, replace(split(file[line], ": ")[2], pattern => ""))
            alg.stop = parse(Dates.DateTime, replace(split(file[line+2], ": ")[2], pattern => ""))

            pattern = r"([0-9]++\.?)++"
            alg.length = parse(Int64, match(pattern, split(file[line+1], ": ")[2]).match)
            alg.value = parse(Float64, match(pattern, split(file[value], ": ")[2]).match)

            pattern = r" *"
            alg.name = replace(split(file[value], ": ")[1], pattern => "")
            push!(algorithms, alg)

            line += 5
            value += 1

        end
    end

    instance.comparisons = _compare_values(algorithms[begin:end])

    return instance

end

export to_latex
function to_latex(instance::Instance)

    local latex_content = [] # Each position is a comparison type

    for comparison in instance.comparisons
        local header = "Instance "
        local cols_config = "c"
        local body = "$(instance.name) "

        local _header, _body, _cols = reduce(
            (acc, value) -> begin
                acc[1] *= ("& " * value.first * " ")
                acc[2] *= "&  $(value.second) "
                acc[3] *= "|c"
                return acc
            end, comparison.values, init=["","",""]
        )

        header *= _header
        body *= _body
        cols_config *= _cols
        push!(latex_content, (header, cols_config, body))
    end

    return latex_content

end

end  # module Comparison


function main()

    local project_path = "$(@__DIR__)"
    local results_path = "$project_path/data/output/"
    local dirs = readdir(results_path)


end


# function test()
#     content = ResultComparison.to_latex(ResultComparison.parse_data(
#         "$(@__DIR__)/../data/output/ILS/cvrp-0-df-0.txt"
#     ))
#
#     println()
#     println("DONE PARSING")
#     for (idx, content) in enumerate(content)
#         println("Type $idx has content: $(content)")
#     end
# end
#
# test()



# Instance has 4 type comparisons
# each type has n algs (Name, value)
