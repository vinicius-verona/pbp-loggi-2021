test:
	julia -O 3 main.jl -i data\input\train\df-0\cvrp-0-df-0.json -s 1 --DEBUG -t 0
execute:
	script\execute-experiments.bat
experiments:
	script\experiments.bat
