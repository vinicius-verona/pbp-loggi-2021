test:
# julia -O 3 main.jl -i data\input\train\df-1\cvrp-1-df-0.json -s 1
	julia -O 3 main.jl -i data\input\train\df-0\cvrp-0-df-0.json -s 1 --DEBUG
execute:
	script\execute-experiments.bat
