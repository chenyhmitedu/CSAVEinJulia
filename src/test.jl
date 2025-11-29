# Test how IO.jld2 is loaded into the model

# joinpath is in the Base package
data_path = joinpath(@__DIR__, "IO.jld2")

# load is in JLD2 package
using JLD2
data = load(data_path)  

data["set_cgi"]