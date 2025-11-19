using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSAVEinJulia
using DataFrames
using MPSGE


MGE, mge_data = MGE_model();

solve!(MGE, cumulative_iteration_limit = 0)
benchmark = generate_report(MGE)
#println(benchmark)
set_silent(MGE)


df = DataFrame(run = Int[], runtime = Float64[])
N = 5
for t ∈ 1:N
    for i ∈ mge_data["set_fe"], g ∈ mge_data["set_g"]
    set_value!(MGE[:rtfd][i, g, :USA], mge_data["rtfd0"][i, g, :USA]*2*(t-1)/(N-1))
    set_value!(MGE[:rtfi][i, g, :USA], mge_data["rtfi0"][i, g, :USA]*2*(t-1)/(N-1))
    end
    runtime = @elapsed solve!(MGE; cumulative_iteration_limit = 1000, convergence_tolerance = 1e-8)
    push!(df, (run = t, runtime = runtime))
end
println(df)

path = joinpath(@__DIR__, "56x2_5.csv")
CSV.write(path, df)

df = generate_report(MGE)
#println(df) # Why print?

#df_pf = filter(row -> startswith(string(row.var), "PF"), df)

pf = value.(MGE[:PF]) #Can just extract the one wanted variable this way

df_filtered = df[df.margin .> 0.001, :]
println(df_filtered)









