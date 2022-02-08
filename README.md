# **PBP-Loggi 2021**
> Algorithms applied to Last-Mile Dynamic Capacitated Vehicle Routing Problems
---

## **Last-Mile Dynamic CVRP Solver**

This is a Dynamic CVRP solver developed as an undergraduate research program financed by [Loggi](https://www.loggi.com/).

Please, address suggestions, bugs and contributions to [Vinicius Verona](https://github.com/vvarg-iinet).

# **Getting Started**
## **Requirements:**
* In order to execute, make sure to have installed [Julia Language](julialang.org).
* For each instance, there must have a compressed distance matrix. See [compressed matrix](./data/DistanceMatrix/README.md) for some distance matrix examples.
## **Usage:**
```
Execution Syntax: 
    $ julia -O 3 main.jl -i <instance> [options]

Where:
    [ --input  -> -i ]  |>    Required    |> Set instance used (JSON)

Options:
    [ --help   -> -h ]  |>  Not Required  |> Display this message
    [ --seed   -> -s ]  |>  Not Required  |> Set seed used on random selections
    [ --k-near -> -k ]  |>  Not Required  |> Set the number of stored delivery nearest adjacents
    [ --timer  -> -k ]  |>  Not Required  |> Set the heuristic execution time (Milliseconds)
    [ --DEBUG        ]  |>  Not Required  |> Set debug mode (Profiling)


-------------------------------- Execution Examples ---------------------------------

$ julia main.jl -s 1 -i data/input/train/df-0/cvrp-0-df-0.json
$ julia main.jl -i data/input/train/rj-5/cvrp-5-rj-89.json -t 9e5 --DEBUG
$ julia main.jl -s 1 -i data/input/train/df-0/cvrp-0-df-0.json -t 18e5 -k 50

```