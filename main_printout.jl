using Pkg

Pkg.add("CSV")
Pkg.add("JLD2")
Pkg.add("MPSGE")
Pkg.add("JuMP")
Pkg.add(url="https://github.com/chenyhmitedu/CSVtoDIC")
Pkg.add(url="https://github.com/chenyhmitedu/GTAPdata")
Pkg.add("DataFrames")
Pkg.add("StatsBase")
Pkg.add("StatsPlots")
Pkg.add("Plots")
Pkg.add("PyPlot")
Pkg.add("Measures")
Pkg.add("Distributions")
Pkg.add("BenchmarkTools")
Pkg.add("PATHSolver")

Pkg.activate(".")               # Selects which environment you are working in
Pkg.instantiate()               # Installs the packages listed in that environment

using CSAVEinJulia
using DataFrames
using MPSGE
using CSV
using BenchmarkTools
using JuMP

import PATHSolver
PATHSolver.c_api_License_SetString("1259252040&Courtesy&&&USR&GEN2035&5_1_2026&1000&PATH&GEN&31_12_2035&0_0_0&6000&0_0")

data = load_gtap_data()

# Vectors below may be changed depending on the sectoral names and resolution
data["set_fe"]      = [:coa, :gas, :p_c]
data["set_elec"]    = [:ely]
data["set_ne"]      = setdiff(data["set_i"], union(data["set_fe"], data["set_elec"]))
data["set_tr"]      = [:wtp, :atp, :otp]

# Define the Benchmark object
b = @benchmarkable MGE_model(data) samples = 1 evals = 1 seconds = 18000
model_gen = run(b)

raw_times_ns = model_gen.times
raw_times_seconds = raw_times_ns ./ 1_000_000_000
df_sol_time = DataFrame(:sec => raw_times_seconds)
path = joinpath(@__DIR__, "src/results/", "56x2_1_mg_time.csv")
CSV.write(path, df_sol_time)

MGE = MGE_model(data);

solve!(MGE, cumulative_iteration_limit = 0)

for i ∈ data["set_fe"], g ∈ data["set_g"]
    set_value!(MGE[:rtfd][i, g, :USA], data["rtfd0"][i, g, :USA]*2)
    set_value!(MGE[:rtfi][i, g, :USA], data["rtfi0"][i, g, :USA]*2)
end

sol = @benchmarkable solve!(MGE; cumulative_iteration_limit = 1000, convergence_tolerance = 1e-8) samples = 1 evals = 1 seconds = 18000
model_sol = run(sol)
sol_times_seconds = model_sol.times ./ 1_000_000_000
df_sol_time = DataFrame(:sec => sol_times_seconds)

path = joinpath(@__DIR__, "src/results/", "56x2_sol_time.csv")
CSV.write(path, df_sol_time)

solve!(MGE, cumulative_iteration_limit = 1000)
df = generate_report(MGE)

df_filtered = df[df.margin .> 0.001, :]
println(df_filtered)

pf  = value.(MGE[:PF])  #Can just extract the one wanted variable this way
y   = value.(MGE[:Y])

# Why Containers.rowtable is convenient: If one uses the built-in JuMP utility, there's no to worry about 
# the internal structure of the keys at all. It handles the "unpacking" logic for you automatically:

df_y = DataFrame(Containers.rowtable(y))

output = "./src/results/output_y.csv"
CSV.write(output, df_y)

# Conducting bootstrap and producing figures: CGE wrapped in a function vs. CGE not wrapped
# "CGE wrapped in a function\n(sample size = 1000)"
# "CGE not wrapped in a function\n(sample size = 1000)"

include("./src/bootstrap.jl")
b = bstrap("56x2_1000_sol_time", "56x2_1000_sol_time_slow2")

include("./src/figure_histogram.jl")
hist_plot = fig_hist(b[1], b[2], "CGE wrapped in a function\n(sample size = 1000)", "CGE not wrapped in a function\n(sample size = 1000)", 0.675, 2.1, 0.0, 0.22)
fig_hist_path = joinpath(@__DIR__, "./src/figures/", "wrapped_vs_not_wrapped.png")
savefig(hist_plot, fig_hist_path)

include("./src/figure_CI.jl")
ci_plot = fig_ci(b[3], b[4], "95% Confidence Interval for Median Runtime Difference", -0.04, 0.0)
fig_ci_path = joinpath(@__DIR__, "./src/figures/", "median_ci_dotplot.png")
savefig(ci_plot, fig_ci_path)

# Conducting bootstrap and producing figures: Model generation time - Julia vs. GAMS 

include("./src/bootstrap.jl")
b = bstrap("56x2_1000_mg_time", "56x2_1000_GAMS_mg_time")

include("./src/figure_histogram.jl")
hist_plot = fig_hist(b[1], b[2], "Model generation time with 56x2 setting: Julia", "Model generation time with 56x2 setting: GAMS",0.0, 1.4, 0.0, 0.4,"","Time (sec)")
fig_hist_path = joinpath(@__DIR__, "./src/figures/", "mg_julia_gams.png")
savefig(hist_plot, fig_hist_path)

include("./src/figure_CI.jl")
ci_plot = fig_ci(b[3], b[4], "95% Confidence Interval for Median Model Generation Time Difference:\n Julia time minus GAMS time", 0.56, 0.6)
fig_ci_path = joinpath(@__DIR__, "./src/figures/", "mg_julia_gams_median_ci_dotplot.png")
savefig(ci_plot, fig_ci_path)

# Conducting bootstrap and producing figures: Solve time - Julia vs. GAMS 

include("./src/bootstrap.jl")
b = bstrap("56x2_1000_sol_time", "56x2_1000_GAMS_sol_time")

include("./src/figure_histogram.jl")
hist_plot = fig_hist(b[1], b[2], "Solve time with 56x2 setting: Julia", "Solve time with 56x2 setting: GAMS",0.0, 9.0, 0.0, 0.4,"","Time (sec)")
fig_hist_path = joinpath(@__DIR__, "./src/figures/", "sol_julia_gams.png")
savefig(hist_plot, fig_hist_path)

include("./src/figure_CI.jl")
ci_plot = fig_ci(b[3], b[4], "95% Confidence Interval for Median Solve Time Difference:\n Julia time minus GAMS time", -6.45, -6.35)
fig_ci_path = joinpath(@__DIR__, "./src/figures/", "sol_julia_gams_median_ci_dotplot.png")
savefig(ci_plot, fig_ci_path)



