using JuMP, Ipopt, MPSGE, JLD2, DataFrames, CSV, BenchmarkTools, GTAPdata, Makie, CairoMakie

io(joinpath(@__DIR__, "data"))
data = load("./IO.jld2")    #k = keys(data)
for (k, v) in data
    @eval $(Symbol(k)) = $v
end

# Declare Vector similar to set declaration in GAMS
s_fe      = [:coa, :gas, :p_c]
s_elec    = [:ely]
s_ne      = setdiff(setdiff(set_i, s_fe), s_elec)
s_tr      = [:wtp, :atp, :otp]

include("model.jl")

# Define the Benchmark object
b = @benchmarkable csave(s_fe, s_elec, s_ne, s_tr) samples = 10 evals = 1 seconds = 180
model_generation_time = run(b)

include("barchart.jl")
figure = draw_barchart(model_generation_time,"Model Generation time")
Makie.save("Distribution_for_model_generation_time.png", figure)

#solve!(MGE, cumulative_iteration_limit = 0)
#baseline = generate_report(MGE)

MGE, rtfd, rtfi = csave(s_fe, s_elec, s_ne, s_tr)

for i ∈ s_fe, g ∈ set_g
    set_value!(rtfd[i, g, :USA], rtfd0[i, g, :USA]*1)
    set_value!(rtfi[i, g, :USA], rtfi0[i, g, :USA]*1)
end

b2 = @benchmarkable solve!(MGE; cumulative_iteration_limit = 1000, convergence_tolerance = 1e-8) samples = 200 evals = 1 seconds = 1800
solvetime = run(b2)    

# Run the benchmark with the configured parameters
figure = draw_barchart(solvetime,"Solve time")
Makie.save("Distribution_for_solve_time.png", figure)

df_results = generate_report(MGE)
println(df_results)

df_Y = filter(:var => x -> startswith(string(x), "Y["), df_results)
df_M = filter(:var => x -> startswith(string(x), "M["), df_results)
df_YM = vcat(df_Y, df_M)

df_P = filter(:var => x -> startswith(string(x), "P["), df_results)

path = joinpath(@__DIR__, "56x2_YM.csv")
CSV.write(path, df_YM)

#df_pf = filter(row -> startswith(string(row.var), "PF"), df)
#df_filtered = df[df.margin .> 0.001, :]
#println(df_filtered)
