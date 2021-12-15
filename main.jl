push!(LOAD_PATH, "src/")
using PBP_Loggi

"""
    main(ARGS)

**`Author:`** Vinicius Gabriel Angelozzi Verona de Resende
"""
main(ARGS) = begin
    
    let args = ARGS, arguments = Argument()

        if (length(args) <= 3)
            displayHelp()
        end

        for i = 1 : length(args)
            local argument = lowercase(args[i])

            if (argument == "-s" || arguments == "--seed")
                arguments.seed = parse(Int64, args[i+1])
                i += 1 
                
            elseif (argument == "-i" || arguments == "--input")
                arguments.input = args[i+1]
                i += 1 
                
            elseif (argument == "-t" || arguments == "--timer")
                arguments.execution_time = parse(Int64, args[i+1])
                i += 1 
                
            elseif (argument == "-k" || arguments == "--k-near")
                arguments.k_nearest = parse(Int64, args[i+1])
                i += 1 
            end
        end

        if (arguments.input === "" || match(r".+\.json", arguments.input) === nothing)
            throw("An input JSON file has not been passed as argument! See help using '-h' argument for more information")
        end
        
        cvrp(arguments)

    end

end

main(ARGS)