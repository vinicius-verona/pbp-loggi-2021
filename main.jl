push!(LOAD_PATH, "src/SD-CVRP")
push!(LOAD_PATH, "src/SD-CVRP/verifier/")
using PBP_Loggi

"""
    main(ARGS)

**`Author:`** Vinicius Gabriel Angelozzi Verona de Resende
"""
main(ARGS) = begin

    let args = ARGS, arguments = Argument(), debug=false

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
                arguments.execution_time = parse(Int64, args[i+1])
                i += 1

            elseif (argument == "-k" || argument == "--k-near")
                arguments.k_nearest = parse(Int64, args[i+1])
                i += 1

            elseif (argument == "--DEBUG")
                debug = true
                i += 1

            elseif (argument == "--help" || argument == "-h")
                displayHelp()
                i += 1
            end
        end

        if (arguments.input === "" || match(r".+\.json", arguments.input) === nothing)
            throw("An input JSON file has not been passed as argument! See help using '-h' argument for more information")
        end

        cvrp(arguments; DEBUG=debug)

    end

end

if (!isinteractive())
    main(ARGS)
end
