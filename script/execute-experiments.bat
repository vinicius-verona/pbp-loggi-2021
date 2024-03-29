echo DF-0
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-0/cvrp-0-df-0.json  1> data/output/cvrp-0-df-0.txt  2> data/output/cvrp-0-df-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-0/cvrp-0-df-29.json 1> data/output/cvrp-0-df-29.txt 2> data/output/cvrp-0-df-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-0/cvrp-0-df-89.json 1> data/output/cvrp-0-df-89.txt 2> data/output/cvrp-0-df-89-errors.txt

echo DF-1
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-1/cvrp-1-df-0.json  1> data/output/cvrp-1-df-0.txt  2> data/output/cvrp-1-df-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-1/cvrp-1-df-29.json 1> data/output/cvrp-1-df-29.txt 2> data/output/cvrp-1-df-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-1/cvrp-1-df-89.json 1> data/output/cvrp-1-df-89.txt 2> data/output/cvrp-1-df-89-errors.txt

echo DF-2
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-2/cvrp-2-df-0.json  1> data/output/cvrp-2-df-0.txt  2> data/output/cvrp-2-df-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-2/cvrp-2-df-29.json 1> data/output/cvrp-2-df-29.txt 2> data/output/cvrp-2-df-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/df-2/cvrp-2-df-89.json 1> data/output/cvrp-2-df-89.txt 2> data/output/cvrp-2-df-89-errors.txt

echo PA-0
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/pa-0/cvrp-0-pa-0.json  1> data/output/cvrp-0-pa-0.txt  2> data/output/cvrp-0-pa-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/pa-0/cvrp-0-pa-29.json 1> data/output/cvrp-0-pa-29.txt 2> data/output/cvrp-0-pa-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/pa-0/cvrp-0-pa-89.json 1> data/output/cvrp-0-pa-89.txt 2> data/output/cvrp-0-pa-89-errors.txt

echo PA-1
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/pa-1/cvrp-1-pa-0.json  1> data/output/cvrp-1-pa-0.txt  2> data/output/cvrp-1-pa-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/pa-1/cvrp-1-pa-29.json 1> data/output/cvrp-1-pa-29.txt 2> data/output/cvrp-1-pa-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/pa-1/cvrp-1-pa-89.json 1> data/output/cvrp-1-pa-89.txt 2> data/output/cvrp-1-pa-89-errors.txt

echo RJ-0
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-0/cvrp-0-rj-0.json  1> data/output/cvrp-0-rj-0.txt  2> data/output/cvrp-0-rj-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-0/cvrp-0-rj-29.json 1> data/output/cvrp-0-rj-29.txt 2> data/output/cvrp-0-rj-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-0/cvrp-0-rj-89.json 1> data/output/cvrp-0-rj-89.txt 2> data/output/cvrp-0-rj-89-errors.txt

echo RJ-1
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-1/cvrp-1-rj-0.json  1> data/output/cvrp-1-rj-0.txt  2> data/output/cvrp-1-rj-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-1/cvrp-1-rj-29.json 1> data/output/cvrp-1-rj-29.txt 2> data/output/cvrp-1-rj-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-1/cvrp-1-rj-89.json 1> data/output/cvrp-1-rj-89.txt 2> data/output/cvrp-1-rj-89-errors.txt

echo RJ-2
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-2/cvrp-2-rj-0.json  1> data/output/cvrp-2-rj-0.txt  2> data/output/cvrp-2-rj-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-2/cvrp-2-rj-29.json 1> data/output/cvrp-2-rj-29.txt 2> data/output/cvrp-2-rj-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-2/cvrp-2-rj-89.json 1> data/output/cvrp-2-rj-89.txt 2> data/output/cvrp-2-rj-89-errors.txt

echo RJ-3
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-3/cvrp-3-rj-0.json  1> data/output/cvrp-3-rj-0.txt  2> data/output/cvrp-3-rj-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-3/cvrp-3-rj-29.json 1> data/output/cvrp-3-rj-29.txt 2> data/output/cvrp-3-rj-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-3/cvrp-3-rj-89.json 1> data/output/cvrp-3-rj-89.txt 2> data/output/cvrp-3-rj-89-errors.txt

echo RJ-4
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-4/cvrp-4-rj-0.json  1> data/output/cvrp-4-rj-0.txt  2> data/output/cvrp-4-rj-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-4/cvrp-4-rj-29.json 1> data/output/cvrp-4-rj-29.txt 2> data/output/cvrp-4-rj-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-4/cvrp-4-rj-89.json 1> data/output/cvrp-4-rj-89.txt 2> data/output/cvrp-4-rj-89-errors.txt

echo RJ-5
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-5/cvrp-5-rj-0.json  1> data/output/cvrp-5-rj-0.txt  2> data/output/cvrp-5-rj-0-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-5/cvrp-5-rj-29.json 1> data/output/cvrp-5-rj-29.txt 2> data/output/cvrp-5-rj-29-errors.txt
julia --color=yes -O 3 main.jl -s 1 -i data/input/train/rj-5/cvrp-5-rj-89.json 1> data/output/cvrp-5-rj-89.txt 2> data/output/cvrp-5-rj-89-errors.txt