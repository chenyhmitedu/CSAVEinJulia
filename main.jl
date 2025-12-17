using Pkg

Pkg.add("CSV")
Pkg.add("JLD2")
Pkg.add("MPSGE")
Pkg.add(url="https://github.com/chenyhmitedu/CSVtoDIC")
Pkg.add(url="https://github.com/chenyhmitedu/GTAPdata")
Pkg.add("DataFrames")
Pkg.add("StatsBase")
Pkg.add("Plots")
Pkg.add("PyPlot")
Pkg.add("StatsBase")
Pkg.add("Printf")
Pkg.add("Measures")
Pkg.add("Distributions")
Pkg.add("BenchmarkTools")
Pkg.add("PATHSolver")

Pkg.activate(".")
Pkg.instantiate()

using CSAVEinJulia
using DataFrames
using MPSGE
using CSV
using BenchmarkTools

import PATHSolver
PATHSolver.c_api_License_SetString("2830898829&Courtesy&&&USR&45321&5_1_2021&1000&PATH&GEN&31_12_2025&0_0_0&6000&0_0")

data = load_gtap_data()

# Vectors below may be changed depending on the sectoral names and resolution
data["set_fe"]      = [:coa, :gas, :p_c]
data["set_elec"]    = [:ely]
data["set_ne"]      = setdiff(data["set_i"], union(data["set_fe"], data["set_elec"]))
data["set_tr"]      = [:wtp, :atp, :otp]

# Define the Benchmark object
b = @benchmarkable MGE_model(data) samples = 1000 evals = 1 seconds = 18000
model_gen = run(b)

raw_times_ns = model_gen.times
raw_times_seconds = raw_times_ns ./ 1_000_000_000
df_sol_time = DataFrame(:sec => raw_times_seconds)
path = joinpath(@__DIR__, "src/results/", "56x2_1000_mg_time.csv")
CSV.write(path, df_sol_time)

MGE = MGE_model(data);

solve!(MGE, cumulative_iteration_limit = 0)
df_calib = generate_report(MGE)

df_calib = df_calib[df_calib.margin .> 0.001, :]
println(df_calib)

set_silent(MGE)

#==
df = DataFrame(run = Int[], runtime = Float64[])
N = 30
for t ∈ 1:N
    for i ∈ data["set_fe"], g ∈ data["set_g"]
        #set_value!(MGE[:rtfd][i, g, :USA], data["rtfd0"][i, g, :USA]*2*(t-1)/(N-1))
        #set_value!(MGE[:rtfi][i, g, :USA], data["rtfi0"][i, g, :USA]*2*(t-1)/(N-1))
        set_value!(MGE[:rtfd][i, g, :USA], data["rtfd0"][i, g, :USA]*2)
        set_value!(MGE[:rtfi][i, g, :USA], data["rtfi0"][i, g, :USA]*2)
    end
    runtime = @elapsed solve!(MGE; cumulative_iteration_limit = 1000, convergence_tolerance = 1e-8)
    push!(df, (run = t, runtime = runtime))
end
println(df)
==#

for i ∈ data["set_fe"], g ∈ data["set_g"]
    set_value!(MGE[:rtfd][i, g, :USA], data["rtfd0"][i, g, :USA]*2)
    set_value!(MGE[:rtfi][i, g, :USA], data["rtfi0"][i, g, :USA]*2)
end

sol = @benchmarkable solve!(MGE; cumulative_iteration_limit = 1000, convergence_tolerance = 1e-8) samples = 1000 evals = 1 seconds = 18000
model_sol = run(sol)
sol_times_seconds = model_sol.times ./ 1_000_000_000
df_sol_time = DataFrame(:sec => sol_times_seconds)

path = joinpath(@__DIR__, "src/results/", "56x2_1000_sol_time.csv")
CSV.write(path, df_sol_time)

df_sol_time = generate_report(MGE)

df_pf = filter(row -> startswith(string(row.var), "PF"), df_sol_time)
pf = value.(MGE[:PF]) #Can just extract the one wanted variable this way

df_filtered = df[df.margin .> 0.001, :]
println(df_filtered)









