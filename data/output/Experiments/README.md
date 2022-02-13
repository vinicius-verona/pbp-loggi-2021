# Experiments

## What is this directory for?
* This directory contains all `TXT` files to be considered when comparing the Dynamic CVRP solution.
* An experiment `TXT` file must have the string `-EXPER` in its name and follow the format:
```
	[BLANK SPACE]
	======> Start loading instance data
	=> Instance name     : [NAME_HERE]
	=> Instance region   : [REGION_HERE]
	=> Instance capacity : [VEHICLE_CAPACITY]
	=> Instance # of deliveries   : [INSTANCE_SIZE]
	=> Instance min # of vehicles : [MINIMUM_SOLUTION_LENGTH]

	======> Start Slotted Solver solution
	=> Start timestamp : [YYYY-MM-DDTH:M:S.MS] (# DateTime format)
	=> # of vehicles   : [SOLUTION_LENGTH] routes
	=> Compl. timestamp: [YYYY-MM-DDTH:M:S.MS]

	======> Start Pos-Heuristic reordering solution
	=> Start timestamp : [YYYY-MM-DDTH:M:S.MS]
	=> # of vehicles   : [SOLUTION_LENGTH] routes
	=> Compl. timestamp: [YYYY-MM-DDTH:M:S.MS]

	======> Start Train + Cluster Greedy solution
	=> Start timestamp : [YYYY-MM-DDTH:M:S.MS]
	=> # of vehicles   : [SOLUTION_LENGTH] routes
	=> Compl. timestamp: [YYYY-MM-DDTH:M:S.MS]

	======> Start Classic CVRP solution
	=> Start timestamp : [YYYY-MM-DDTH:M:S.MS]
	=> # of vehicles   : [SOLUTION_LENGTH] routes
	=> Compl. timestamp: [YYYY-MM-DDTH:M:S.MS]

	======> Results (Distance in KM)
	Classic : [SOLUTION_VALUE]
	Cluster : [SOLUTION_VALUE]
	Solver  : [SOLUTION_VALUE]
	LKH-3   : [SOLUTION_VALUE]
```
