module PBP_Loggi

using Dates
using CVRP_Structures
using Load_Instance
using CVRP_Controllers: fixAssignment!
using Cluster_Instance: train
using Initial_Solution: greedySolution
using ClarkeWright: clarkeWrightSolution
using Heuristic_Solution: ils
using LKH_3: lkh
using Verifier
using Random
using Output
using Juno
using Profile
using ProfileSVG

# Global variables used to controll solver
SLOT_LENGTH  = 100
SLOT_COUNTER = 0
LAST_SLOT    = false
INSTANCE_LENGTH = 0

# Execution Structures
export Argument
mutable struct Argument

    seed::Int64
    input::String
    execution_time::Real
    k_nearest::Int64

    Argument(attributes...) = begin
        local seed = 0
        local input = ""
        local execution_time = 0
        local k_nearest = 100

        isdefined(attributes, 1) ? seed = attributes[1] : nothing
        isdefined(attributes, 2) ? input = attributes[2] : nothing
        isdefined(attributes, 3) ? execution_time = attributes[3] : nothing
        isdefined(attributes, 4) ? k_nearest = attributes[4] : nothing

        return new(seed, input, execution_time, k_nearest)
    end

end

mutable struct ExecStatistic

    solver_initial_timestamp::DateTime # Solver Solution timestamp
    solver_completion_timestamp::DateTime # Solver Solution timestamp

    lkh_initial_timestamp::DateTime # Solver + LKH Solution timestamp
    lkh_completion_timestamp::DateTime # Solver + LKH Solution timestamp

end

# CVRP Program
export cvrp
function cvrp(arguments::Argument; DEBUG::Bool=false)

    Random.seed!(arguments.seed)

    #-------------------------------------#
    #         Instance Processing         #
    #-------------------------------------#

    println("\n======> Start loading instance data")
    local instance = loadInstance(arguments.input)
    local auxiliars = loadDistanceMatrix(instance.name; k_nearest=arguments.k_nearest)
    println("=> Instance name     : ", instance.name)
    println("=> Instance region   : ", instance.region)
    println("=> Instance capacity : ", instance.capacity)
    println("=> Instance # of deliveries   : ", length(instance.deliveries))
    println("=> Instance min # of vehicles : ", instance.min_number_routes, " routes")

    #----------------------------------#
    #         Instance Solving         #
    #----------------------------------#

    # Update INSTANCE_LENGTH variable
    global SLOT_COUNTER = 0
    global LAST_SLOT = false
    global INSTANCE_LENGTH = length(instance.deliveries)
    local execution_stats = ExecStatistic(now(), now(), now(), now())

    # Slot version solver solution
    println("\n======> Start Slotted solver solution")
    execution_stats.solver_initial_timestamp = now()
    println("=> Start timestamp : ", execution_stats.solver_initial_timestamp)

    local solver_solution::Array{Route, 1} = []
    if (DEBUG)
        solver_solution = @profile solve(instance, auxiliars; exec_time = arguments.execution_time)
    else
        solver_solution = solve(instance, auxiliars; exec_time = arguments.execution_time)
    end

    execution_stats.solver_completion_timestamp = now()
    println("=> # of vehicles   : ", length(filter!(r -> length(r.deliveries) > 2, solver_solution)), " routes")
    println("=> Compl. timestamp: ", execution_stats.solver_completion_timestamp)

    # LKH + slot version solver solution
    println("\n======> Start Pos-Heuristic reordering solution")
    execution_stats.lkh_initial_timestamp = now()
    println("=> Start timestamp : ", execution_stats.lkh_initial_timestamp)

    local lkh_solution = lkh(deepcopy(solver_solution), auxiliars)
    execution_stats.lkh_completion_timestamp = now()
    println("=> # of vehicles   : ", length(filter!(r -> length(r.deliveries) > 2, lkh_solution)), " routes")
    println("=> Compl. timestamp: ", execution_stats.lkh_completion_timestamp)

    #----------------------------------#
    #         Instance Results         #
    #----------------------------------#

    println("\n======> Results (Distance in KM)")
    println("Solved: ", sum(map(x -> x.distance, solver_solution)) / 1000)
    println("LKH-3 : ", sum(map(x -> x.distance, lkh_solution)) / 1000)
    println()

    #-----------------------------------#
    #         Solving Verifying         #
    #-----------------------------------#

    # Verify solution
    println("\n\n======> Verifying Solver Solution <======")
    verify(auxiliar = auxiliars, solution = solver_solution)
    println("\n\n======> Verifying Solver + LKH Solution <======")
    verify(auxiliar = auxiliars, solution = lkh_solution)
    println()

    # Generate output
    generateOutput(instance, lkh_solution; algorithm = "Slot", path="$(@__DIR__)/../../data/output/ILS/")
    generateOutput(instance, lkh_solution; algorithm = "lkh", path="$(@__DIR__)/../../data/output/LKH/")

    #-------------------------------------#
    #             DEBUG STATS             #
    #-------------------------------------#

    if (DEBUG)
        local name = "$(@__DIR__)/../../data/output/DEBUG/$(instance.name)"
        Profile.print(open("$name.txt", "w"), format=:flat)
        ProfileSVG.save("$name.svg")
    end

end


"""
Apply initial algorithm and then a heuristic method in order to solve DCVRP.

**Algorithms:**
* `Clarke-Wright` - Initial Algorithm
* `Iterated Local-Search (ILS)` - Heuristic Algorithm (improvement step)
"""
function solve(instance::CvrpData, auxiliar::CvrpAuxiliars; solution::Controller{Array{Route,1}} = nothing, exec_time::Real=9e5)

    global SLOT_COUNTER += 1
    local current_slot = SLOT_COUNTER * SLOT_LENGTH

    if (current_slot >= INSTANCE_LENGTH)
        current_slot = INSTANCE_LENGTH
        global LAST_SLOT = true
    end

    local deliveries = instance.deliveries[1:current_slot]

    if (solution !== nothing)
        solution = clarkeWrightSolution(instance, auxiliar, deliveries; solution = solution)

        local time = Int(round((exec_time * SLOT_LENGTH) / length(instance.deliveries), RoundUp))
        solution = ils(auxiliar, solution, deliveries; execution_time=time)

    else
        solution = clarkeWrightSolution(instance, auxiliar, deliveries)

        local time = Int(round((exec_time * SLOT_LENGTH) / length(instance.deliveries), RoundUp))
        solution = ils(auxiliar, solution, deliveries; execution_time=time)
    end

    fixAssignment!(solution, deliveries)

    if (LAST_SLOT)
        return solution
    end

    return solve(instance, auxiliar; solution = solution, exec_time = exec_time)

end


export displayHelp
function displayHelp()

    print("\n ################################ PBP-Loggi  2021 #################################\n")
    print("#          --------------------------------------------------------------          #\n")
    print("#         |            Hibrid algorithms applied to Last-Mile            |         #\n")
    print("#         |         Dynamic Capacitated Vehicle Routing Problems         |         #\n")
    print("#          --------------------------------------------------------------          #\n")
    print(" ##################################################################################\n\n")

    println("Execution Syntax:")
    println("    \$ julia -O 3 main.jl -i <instance> [options]")
    println()

    println("Where:")
    println("    [ --input  -> -i ]  |>    Required    |> Set instance used (JSON)")
    println()

    println("Options:")
    println("    [ --help   -> -h ]  |>  Not Required  |> Display this message")
    println("    [ --seed   -> -s ]  |>  Not Required  |> Set seed used on random selections")
    println("    [ --k-near -> -k ]  |>  Not Required  |> Set the number of stored delivery nearest adjacents")
    println("    [ --timer  -> -k ]  |>  Not Required  |> Set the heuristic execution time (Milliseconds)")
    println("    [ --DEBUG        ]  |>  Not Required  |> Set debug mode (Profiling)")
    println()

    println("-------------------------------- Execution Examples ---------------------------------")
    println()
    println("\$ julia main.jl -s 1 -i data/input/train/df-0/cvrp-0-df-0.json")
    println("\$ julia main.jl -i data/input/train/rj-5/cvrp-5-rj-89.json -t 9e5 --DEBUG")
    println("\$ julia main.jl -s 1 -i data/input/train/df-0/cvrp-0-df-0.json -t 18e5 -k 50")
    println()

end

end # module
