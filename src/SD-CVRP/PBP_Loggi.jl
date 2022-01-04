module PBP_Loggi

using Dates
using CVRP_Structures
using Load_Instance
using Cluster_Instance: train
using Initial_Solution: greedySolution
using ClarkeWright: clarkewrightSolution
using Plots 


# Execution Structures
export Argument
mutable struct Argument
    
    seed::Int64
    input::String
    execution_time::Int64
    k_nearest::Int64

    Argument(attributes...) = begin
        local seed  = 0
        local input = ""
        local execution_time = 0
        local k_nearest = 0

        isdefined(attributes, 1) ? seed  = attributes[1] : nothing
        isdefined(attributes, 2) ? input = attributes[2] : nothing
        isdefined(attributes, 3) ? execution_time = attributes[3] : nothing
        isdefined(attributes, 4) ? k_nearest = attributes[4] : nothing

        return new(seed, input, execution_time, k_nearest)
    end

end

mutable struct ExecStatistic

    train_initial_timestamp::DateTime
    train_completion_timestamp::DateTime

    greedy_initial_timestamp::DateTime # Greedy Solution timestamp
    greedy_completion_timestamp::DateTime # Greedy Solution timestamp

    cw_initial_timestamp::DateTime # Clarke-Wright Solution timestamp
    cw_completion_timestamp::DateTime # Clarke-Wright Solution timestamp

end

# CVRP Program
export cvrp
function cvrp(arguments::Argument)

    println("\n======> Start loading instance data")
    local instance  = loadInstance(arguments.input)
    local auxiliars = loadDistanceMatrix(instance.name)
    println("=> Instance name     : ", instance.name)
    println("=> Instance region   : ", instance.region)
    println("=> Instance capacity : ", instance.capacity)
    println("=> Instance # of deliveries   : ", length(instance.deliveries))
    println("=> Instance min # of vehicles : ", instance.min_number_routes, " routes")
    
    local execution_stats = ExecStatistic(now(), now(), now(), now(), now(), now())

    # Clustering instance
    println("\n======> Start clustering instance")
    execution_stats.train_initial_timestamp = now()
    println("=> Start timestamp : ", execution_stats.train_initial_timestamp)
    
    local model = train(instance.region)
    execution_stats.train_completion_timestamp = now()
    println("=> # of clusters   : ", length(model.centroids), " centroids")
    println("=> Compl. timestamp: ", execution_stats.train_completion_timestamp)
    
    # Greedy Solution
    println("\n======> Start greedy solution")
    execution_stats.greedy_initial_timestamp = now()
    println("=> Start timestamp : ", execution_stats.greedy_initial_timestamp)
    
    local greedy_solution = greedySolution(instance, auxiliars, model)
    execution_stats.greedy_completion_timestamp = now()
    println("=> # of vehicles   : ", length(filter(r->length(r.deliveries) > 1, greedy_solution)), " routes")
    println("=> Compl. timestamp: ", execution_stats.greedy_completion_timestamp)
    
    # Clarke-Wright Solution
    println("\n======> Start Clrke-Wright solution")
    execution_stats.cw_initial_timestamp = now()
    println("=> Start timestamp : ", execution_stats.cw_initial_timestamp)
    
    local cw_solution = clarkewrightSolution(instance, auxiliars)
    execution_stats.cw_completion_timestamp = now()
    println("=> # of vehicles   : ", length(filter(r->length(r.deliveries) > 1, cw_solution)), " routes")
    println("=> Compl. timestamp: ", execution_stats.cw_completion_timestamp)
    

    # Heuristic Solution
    # println("\n======> Start Heuristic solution")
    # execution_stats.heuristic_initial_timestamp = now()
    # println("=> Start timestamp : ", execution_stats.heuristic_initial_timestamp)

    # local heuristic_solution = ils(instance, auxiliars, greedy_solution)
    # local heuristic_solution = ils(instance, auxiliars, clarkeWright_solution)
    # execution_stats.heuristic_completion_timestamp = now()


    # Generate Output
    # generateOutput(greedy_solution)
    # generateOutput(heuristic_solution)

    println("\n======> Results (Distance in KM)")
    println("Greedy       :", sum(map(x -> x.distance, greedy_solution)) / 1000)
    println("Clarke-Wright:", sum(map(x -> x.distance, cw_solution)) / 1000)

    # Plot routes
    plotRoute(greedy_solution)
    

    println()
    
end

function plotRoute(routes)

    foreach(r -> begin
        local points = map(x->(x.point.lng, x.point.lat), r.deliveries)
        plot!(points)
    end, routes)
    savefig("myplot.png")

end


export displayHelp
function displayHelp()

    print("\n ################################ PBP-Loggi  2021 #################################\n")
    print("#          --------------------------------------------------------------          #\n")
    print("#         |            Hibrid algorithms applied to Last-Mile            |         #\n")
    print("#         |         Dynamic Capacitated Vehicle Routing Problems         |         #\n")
    print("#          --------------------------------------------------------------          #\n")
    print(" ##################################################################################\n\n")
    
    print(" ------------------------------------ Commands --------------------------------------\n")
    print("|                                                                                    |\n")
    print("|> [ --help   → -h ]  |>  Not Required  |> Display this menu                         |\n")
    print("|> [ --seed   → -s ]  |>  Not Required  |> Set seed used                             |\n")
    print("|> [ --input  → -i ]  |>    Required    |> Set instance used                         |\n")
    print("|                                                                                    |\n")
    print(" ------------------------------------------------------------------------------------\n\n")
    
    print(" ----------- Type ------------\n")
    print("|                             |\n")
    print("|> -h → <JSON> → NOT REQUIRED |\n")
    print("|> -s → <INT.> → NOT REQUIRED |\n")
    print("|> -i → <STR.> →   REQUIRED   |\n")
    print("|                             |\n")
    print(" -----------------------------\n\n")
    
    print(" -------------------------------- Execution Example ---------------------------------\n")
    print("|                                                                                    |\n")
    print("|> Syntax: julia -O 3 main.jl -i path/instance.json -s 1                             |\n")
    print("|                                                                                    |\n")
    print(" ------------------------------------------------------------------------------------\n\n")

end

end # module
