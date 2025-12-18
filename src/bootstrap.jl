using Pkg
using CSVtoDIC
using DataFrames
using StatsBase # Needed for median and sampling

function bstrap(d1::String, d2::String)

    rdata   = joinpath(@__DIR__, "runtime")

    # "source" in CSVtoDIC returns "d (dictionary) and s(vector)." But each time one of them will be empty, depending on how many columns each CSV file has.
    # In here, each CSV file only has one column, and so d is empty, and s stores the data needed. d and s can be accessed by v[1] and v[2], respectively.
    v       = CSVtoDIC.source(rdata)
    #rt      = Dict()
    #merge!(rt, v[2])
    rt      = v[2]
    rt      = Dict(k => parse.(Float64, String.(v)) for (k, v) in rt)

    #X1 = rt["mg_gams_56x2"]
    #X2 = rt["mg_julia_56x2"]

    X1 = rt[d1]
    X2 = rt[d2]

    # 2. Bootstrap Setup
    B = 10_000 # Number of bootstrap iterations
    n1 = length(X1)
    n2 = length(X2)
    bootstrap_differences = Float64[] # Store the B results

    # 3. Bootstrap Loop 
    for i in 1:B
        # Resample with replacement
        X1_star = sample(X1, n1, replace=true) 
        X2_star = sample(X2, n2, replace=true)

        # Calculate the statistic (difference in medians)
        delta_star = median(X1_star) - median(X2_star)

        # Append "delta_star" to the end of an array ("bootstrap_differences") one element at a time.
        push!(bootstrap_differences, delta_star)
    end

    # 4. Construct the Confidence Interval (e.g., 95% CI)
    CI_lower = quantile(bootstrap_differences, 0.025)
    CI_upper = quantile(bootstrap_differences, 0.975)

#    println("95% CI for Median Difference: [$(CI_lower), $(CI_upper)]")

    return X1, X2, CI_lower, CI_upper

end
