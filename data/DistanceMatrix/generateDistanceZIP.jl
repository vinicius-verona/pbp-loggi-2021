# Insert lib directory to julia's LOAD_PATH 
push!(LOAD_PATH, "../../src/lib/")

using Base
using Dates
using Crayons
using Printf
using PBP_Loggi_Lib
using OrderedCollections
using JSON
using Distances 
using GZip
using HTTP

function main(ARGS)
    
    local files = ["cvrp-0-df-","cvrp-0-pa-","cvrp-0-rj-","cvrp-1-df-",
    "cvrp-1-pa-","cvrp-1-rj-","cvrp-2-df-","cvrp-2-rj-",
    "cvrp-3-rj-","cvrp-4-rj-","cvrp-5-rj-"]

    local dirs = ["df-0", "pa-0", "rj-0", "df-1", "pa-1", "rj-1", "df-2",
                  "rj-2", "rj-3", "rj-4", "rj-5"]

    local counter = 1
    for i in files
        local dir = dirs[counter]
        counter += 1

        for j in [0,29,89]
            local cvrp_dict = JSON.parse(open("../instances/cvrp-instances-1.0/train/$(dir)/$(i)$(j).json", "r"))
            
            println("\n========================================\n")
            println("|> FILE: $(i)$(j).json")
            println("\n========================================\n")

            println("|> Start generating distance table  ...")
            local cvrp = readInstance(cvrp_dict)
            local distance_table = createRequestRoute(cvrp)
            println("|> Done generating distance table ...")
            
            println("\n========================================\n")

            println("|> Start generating compressed table ...")
            local compressedTable = GZip.open("$(i)$(j).json.gz", "w", 9) # Compress table with compression level 9
            writeDistanceTable(compressedTable, distance_table)
            println("|> Done generating compressed table  ...")
        end
    end

end

function writeDistanceTable(compressedFile, table)

    local dict_table = OrderedDict("Distance_Table" => table)
    local parsedDict = JSON.json(dict_table)

    write(compressedFile, "$(parsedDict)")
    
end


function createRequestRoute(cvrp)

    local request_string = "$(cvrp.origin.lng),$(cvrp.origin.lat);$(cvrp.deliveries[1].point.lng),$(cvrp.deliveries[1].point.lat)"    
    for i in 2:length(cvrp.deliveries)
        request_string = "$(request_string);$(cvrp.deliveries[i].point.lng),$(cvrp.deliveries[i].point.lat)"    
    end

    local route_request
    
    try
        route_request = HTTP.get("http://localhost:5000/table/v1/driving/$(request_string)?annotations=distance")
    catch
        run(`cmd /c docker restart osrm`)
        sleep(60)
        route_request = HTTP.get("http://localhost:5000/table/v1/driving/$(request_string)?annotations=distance")
    end

    local body = JSON.parse(String(route_request.body))
    local matrix = body["distances"]

    return transpose(reduce(hcat, matrix))

end


main(ARGS)