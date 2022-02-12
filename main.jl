push!(LOAD_PATH, "$(@__DIR__)/src/SD-CVRP")
push!(LOAD_PATH, "$(@__DIR__)/src/SD-CVRP/verifier/")
using PBP_Loggi

"""
    main(ARGS)

**`Author:`** Vinicius Gabriel Angelozzi Verona de Resende
"""
main(ARGS) = begin

    let args = ARGS, arguments = Argument(), debug=false, exper=false

        if (length(args) < 2)
            displayHelp()
            exit()
        end

        for i = 1 : length(args)
            local argument = lowercase(args[i])

            if (argument == "-s" || argument == "--seed")
                arguments.seed = parse(Int64, args[i+1])
                i += 1

            elseif (argument == "-i" || argument == "--input")
                arguments.input = args[i+1]
                i += 1

            elseif (argument == "-t" || argument == "--timer")
                arguments.execution_time = parse(Float64, args[i+1])
                i += 1

            elseif (argument == "-k" || argument == "--k-near")
                arguments.k_nearest = parse(Int64, args[i+1])
                i += 1

            elseif (argument == "--debug")
                debug = true
                i += 1

            elseif (argument == "--exper")
                exper = true
                i += 1

            elseif (argument == "--help" || argument == "-h")
                displayHelp()
                i += 1
            end
        end

        if (arguments.input === "" || match(r".+\.json", arguments.input) === nothing)
            throw("An input JSON file has not been passed as argument! See help using '-h' argument for more information")
        end

        cvrp(arguments; DEBUG=debug, experiment=exper)

    end

end

if (!isinteractive())
    main(ARGS)
else
    println()
    print("What are the execution arguments: ")
    local arguments = split(readline(), " ")
    main(arguments)
end
# -s 1 -i data/input/train/rj-5/cvrp-5-rj-89.json -t 9e4 -k 20 --EXPER
