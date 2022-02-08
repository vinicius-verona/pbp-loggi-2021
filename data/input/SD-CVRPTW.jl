using TerminalMenus
using JSON
using Random

TerminalMenus.config(up_arrow='↑', down_arrow='↓', cursor='→')

function main()

    println("Welcome to SD-CVRPTW instance generator ☻");
    println("- For each of the following commands, choose an option and press enter.\n")

    # Create initial menu
    local path       = "$(@__DIR__)/../../data/input/"
    local dirs_files = readdir(path, sort=false)

    # Delete files from dirs options
    filter!(d->!occursin(r".{1,}\..{1,}", d), dirs_files)
    
    local options = dirs_files
    local menu    = RadioMenu(options, pagesize = 5)
    local choice  = request("Choose an instance directory:", menu)
    
    
    # Create region menu
    path       = "$(path)$(dirs_files[choice])/"
    dirs_files = readdir(path, sort=false)
    
    # Delete files from dirs options
    filter!(d->!occursin(r".{1,}\..{1,}", d), dirs_files)
    
    options = dirs_files
    menu    = RadioMenu(options, pagesize = 5)
    choice  = request("\nChoose an instance region:", menu)


    # Create files menu
    path       = "$(path)$(dirs_files[choice])/"
    dirs_files = readdir(path, sort=false)

    # Delete files from options if file is not json
    filter!(d->occursin(r".+\.json", d), dirs_files)

    options = dirs_files
    menu    = RadioMenu(options, pagesize = 5)
    choice  = request("\nChoose an instance file:", menu)
    path    = "$(path)$(dirs_files[choice])"

    # Get time interval for instance
    println("\n=============================================================")
    println("\n☻ Great! Now please, when asked, insert the values requested
  in order to create the timestamp range for the instance")
    println("\n=============================================================")
    
    print("\n|> Lower limit for timestamp (Integer): ")
    local lowerlimit = parse(Int64, readline())
    
    print("|> Upper limit for timestamp (Integer): ")
    local upperlimit = parse(Int64, readline())
    
    println("\nWait... Instance is beeing generated with range [$lowerlimit,$upperlimit]!")

    generateInstance(path, lowerlimit, upperlimit)

    println("Done generating instances.")

end

@inline function generateInstance(path, lowerlimit, upperlimit)

    local file = JSON.parse(open(path, "r"))
    
    for i in file["deliveries"]
        local ll = rand(lowerlimit:upperlimit-1)
        local ul = rand(ll:upperlimit)
        i["time_interval"] = (ll, ul)
    end

    write(open(path, "w"), JSON.json(file))

end

main()