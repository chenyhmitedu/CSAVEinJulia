using Pkg
Pkg.add(url="https://github.com/chenyhmitedu/CSVtoDIC")
Pkg.add(url="https://github.com/chenyhmitedu/GTAPdata")
Pkg.activate(".")
Pkg.instantiate()

using CSAVEinJulia
using DataFrames
using MPSGE
using CSV

data = load_gtap_data()

# Vectors below may be changed depending on the sectoral names and resolution
data["set_fe"]      = [:coa, :gas, :p_c]
data["set_elec"]    = [:ely]
data["set_ne"]      = setdiff(data["set_i"], union(data["set_fe"], data["set_elec"]))
data["set_tr"]      = [:wtp, :atp, :otp]

MGE = MGE_model(data);

solve!(MGE, cumulative_iteration_limit = 0)
df_calib = generate_report(MGE)

df_calib = df_calib[df_calib.margin .> 0.001, :]
println(df_calib)

set_silent(MGE)


df = DataFrame(run = Int[], runtime = Float64[])
N = 5
for t ∈ 1:N
    for i ∈ data["set_fe"], g ∈ data["set_g"]
        set_value!(MGE[:rtfd][i, g, :USA], data["rtfd0"][i, g, :USA]*2*(t-1)/(N-1))
        set_value!(MGE[:rtfi][i, g, :USA], data["rtfi0"][i, g, :USA]*2*(t-1)/(N-1))
    end
    runtime = @elapsed solve!(MGE; cumulative_iteration_limit = 1000, convergence_tolerance = 1e-8)
    push!(df, (run = t, runtime = runtime))
end
println(df)

path = joinpath(@__DIR__, "src/results/", "56x2_5.csv")
CSV.write(path, df)

df = generate_report(MGE)
#println(df) # Why print?

#df_pf = filter(row -> startswith(string(row.var), "PF"), df)

pf = value.(MGE[:PF]) #Can just extract the one wanted variable this way

df_filtered = df[df.margin .> 0.001, :]
println(df_filtered)









