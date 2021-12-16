export Swap
mutable struct Swap
end

export execute
function execute() # Delta evaluation

    # 1 - Select a route
    # 2 - Select another route
    # 3 - If both routes have the same indexer or one does not have deliveries, repeat 1/2

    # 4 - Select `n` from first route
    # 5 - Select `m` from second route

    # 6  - Get the value of the selected string in the first route -> function
    # 7  - Get the value of the selected string in the second route -> function
    # 8  - Get value of removing the string in the first route -> function
    # 9  - Get value of removing the string in the second route -> function
    # 10 - Get value of inserting first string into second route -> function
    # 11 - Get value of inserting second string into first route -> function
    # 12 - Update index for each delivery inserted and neighbor to inserted string -> function
    
end

export accept
function accept()

    # 1 - Remove frist string in first route -> function
    # 2 - Insert frist string in second route -> function
    # 3 - Remove second string in second route -> function
    # 4 - Insert second string in first route -> function

end

export reject
function reject()
    # Update statistics
end