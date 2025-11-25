
using JuMP, Ipopt, MPSGE, JLD2, DataFrames, CSV, BenchmarkTools, CSVtoDIC, GTAPdata

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

# Define the Benchmark object: This step is simple and has no parameters to confuse the parser.
b = @benchmarkable csave(s_fe, s_elec, s_ne, s_tr)

# Access the parameters field and set values
b.params.samples = 5
b.params.evals = 2
b.params.seconds = 180

# Run the benchmark with the configured parameters
model_generation_time = run(b)

# model_generation_time = @benchmark csave(s_fe, s_elec, s_ne, s_tr) samples=5 evals=2 seconds=180

df1 = DataFrame(run = "MG", runtime = model_generation_time)

#solve!(MGE, cumulative_iteration_limit = 0)
#baseline = generate_report(MGE)

MGE, rtfd, rtfi = csave(s_fe, s_elec, s_ne, s_tr)
solvetime = Vector{BenchmarkTools.Trial}(undef, 1)
n = length(solvetime)

for t ∈ 1:n
    for i ∈ s_fe, g ∈ set_g
#    set_value!(rtfd[i, g, :USA], rtfd0[i, g, :USA]*2*(t-1)/(n-1))
#    set_value!(rtfi[i, g, :USA], rtfi0[i, g, :USA]*2*(t-1)/(n-1))
    set_value!(rtfd[i, g, :USA], rtfd0[i, g, :USA]*1)
    set_value!(rtfi[i, g, :USA], rtfi0[i, g, :USA]*1)
    end
    solvetime[t] = @benchmark solve!(MGE; cumulative_iteration_limit = 1000, convergence_tolerance = 1e-8)
end

df2 = DataFrame(run = 1:length(solvetime), runtime = solvetime)

df = vcat(df1, df2)

path = joinpath(@__DIR__, "56x2_base.csv")
CSV.write(path, df)

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
