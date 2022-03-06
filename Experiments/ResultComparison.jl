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
mutable struct Data{T}

    comparison_type::String
    values::Array{TypeNull{T},1}

    Data{T}(type::String; cols::Int64 = 0) where {T} =
        new(type, Array{T,1}(nothing, cols))

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

export table_template
table_template(; cols_config::String = "", header::String = "", body::String = "")::String =
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

    local time_type = Data{ComparisonData}("time", cols = length(algorithms))
    local distance_type = Data{ComparisonData}("distance", cols = length(algorithms))
    local length_type = Data{ComparisonData}("length", cols = length(algorithms))
    local gap_type = Data{ComparisonData}("gap", cols = 2)

    for (index, alg) in enumerate(algorithms)
        time_type.values[index] = Pair(alg.name, Dates.value(alg.stop - alg.start) / 1000)
        distance_type.values[index] = Pair(alg.name, alg.value)
        length_type.values[index] = Pair(alg.name, alg.length)
    end

    local minimum = typemax(Float64)
    local best = nothing
    local alg = ""

    for _value in distance_type.values[begin:end-1]
        if (_value.second < minimum)
            minimum = _value.second
            best = _value
            alg = _value.first
        end
    end

    # Calculate GAP variation
    gap_type.values[1] = best
    local gap = _calculate_gap(best = algorithms[end].value, solution = best.second)
    gap_type.values[2] = Pair("GAP", gap)

    return [time_type, distance_type, length_type, gap_type]

end

export parse_data
"""
For a given TXT file, extract comparison data and create an `Instance` object
```julia
julia>
```
"""
function parse_data(filename::String)::Instance

    local instance = Instance()
    local algorithms::Array{Algorithm,1} = []
    local LAST_ALGORITHM = 30

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
            # println("Line: ", value, " - ", file[value])
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
"""
For a given instance, extract comparison data and convert into LaTex format string
```julia
julia>
```
"""
function to_latex(instance::Instance)

    local latex_content = [] # Each position is a comparison type
    local counter = 1

    for comparison in instance.comparisons
        local header = "Instance "
        local cols_config = "c"
        local body = "$(instance.name) "
        counter += 1

        local _header, _body, _cols = reduce(
            (acc, value) -> begin
                if (comparison.comparison_type == "gap")
                    acc[1] *= ("& Algorithm & " * value.first * " ")
                    acc[2] *= "& $(value.first) & $(value.second) "
                else
                    acc[1] *= ("& " * value.first * " ")
                    acc[2] *= "&  $(value.second) "
                end

                acc[3] *= "|c"
                return acc
            end, comparison.values, init=["","",""]
        )

        _header *= "\\\\ \n"
        _body *= "\\\\ \n\t\t"

        header *= _header
        body *= _body
        cols_config *= _cols
        push!(latex_content, (cols_config, header, body))
    end

    return latex_content

end

end  # module Comparison

import Dates
function main()

    local project_path = "$(@__DIR__)/.."
    local experiment_path = "$project_path/data/output/Experiments/"

    local id = string(Dates.now())
    id = replace(id, r":" => "-")
    id = replace(id, r"\.([0-9]*)" => "")
    local experiments = filter(
        x -> match(r"-EXPER", x) !== nothing,
        readdir(experiment_path, join=true)
    )

    local filenames = [
        "$project_path/Experiments/Time-Comparison-$id.txt",
        "$project_path/Experiments/Distance-Comparison-$id.txt",
        "$project_path/Experiments/Length-Comparison-$id.txt",
        "$project_path/Experiments/GAP-Comparison-$id.txt"
    ]
    local files_ptr = [open(file, "a") for file in filenames]

    local cols_cfg = ["" for _ in filenames]
    local headers = ["" for _ in filenames]
    local bodies = ["" for _ in filenames]

    for i in experiments
        local content = ResultComparison.to_latex(ResultComparison.parse_data(i))

        for index = 1:length(filenames)
            # print(content[index][1])
            # exit()
            cols_cfg[index] = content[index][1]
            headers[index] = content[index][2]
            bodies[index] *= content[index][3]
        end
    end

    for (index, file) in enumerate(files_ptr)
        write(file, ResultComparison.table_template(
            cols_config = cols_cfg[index],
            header = headers[index],
            body = bodies[index],
        ))
    end

    [close(file) for file in files_ptr]

end

main()
