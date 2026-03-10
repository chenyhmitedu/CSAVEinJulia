using DataFrames, CSV, Plots, StatsPlots, Measures # Measures is needed for mm units

# --------------------------------------------------
# 0. Load data
# --------------------------------------------------
path = joinpath(@__DIR__, "./runtime/", "mg_sol_time.csv")
df = CSV.read(path, DataFrame)

target_settings = ["56x2", "56x4", "56x8", "56x16"]
df_subset = df[in.(df.setting, Ref(target_settings)), :]

# --------------------------------------------------
# 1. Split by language
# --------------------------------------------------
df_julia = df_subset[df_subset.language .== "Julia", :]
df_gams  = df_subset[df_subset.language .== "GAMS", :]

settings = unique(df_julia.setting)
df_base  = DataFrame(setting = settings)

# --------------------------------------------------
# 2. Extract mg / sol
# --------------------------------------------------
df_mg_j  = df_julia[df_julia.type .== "mg",  [:setting, :sec]]
df_sol_j = df_julia[df_julia.type .== "sol", [:setting, :sec]]
df_mg_g  = df_gams[df_gams.type .== "mg",  [:setting, :sec]]
df_sol_g = df_gams[df_gams.type .== "sol", [:setting, :sec]]

df_final_j = leftjoin(df_base, df_mg_j,  on = :setting); rename!(df_final_j, :sec => :mg)
df_final_j = leftjoin(df_final_j, df_sol_j, on = :setting); rename!(df_final_j, :sec => :sol)

df_final_g = leftjoin(df_base, df_mg_g,  on = :setting); rename!(df_final_g, :sec => :mg)
df_final_g = leftjoin(df_final_g, df_sol_g, on = :setting); rename!(df_final_g, :sec => :sol)

# --------------------------------------------------
# 3. Handle missing
# --------------------------------------------------
df_final_j.mg  = coalesce.(df_final_j.mg,  0.0)
df_final_j.sol = coalesce.(df_final_j.sol, 0.0)
df_final_g.mg  = coalesce.(df_final_g.mg,  0.0)
df_final_g.sol = coalesce.(df_final_g.sol, 0.0)

# --------------------------------------------------
# 4. Plot settings
# --------------------------------------------------
floor_val    = 1e-3
shared_ylims = (floor_val, 3000)
fmt(x) = x < 0.1 ? string(round(x, digits=3)) : string(round(x, digits=1))

# Standard categorical x positions are 1, 2, 3...
xpos = 1:length(settings)

# --------------------------------------------------
# 5. Julia plot
# --------------------------------------------------
p1 = bar(
    settings,
    [df_final_j.sol df_final_j.mg],
    bar_position = :stack,
    bar_width = 0.3,
    yscale = :log10,
    ylims = shared_ylims,
    fillrange = floor_val,
    label = ["sol" "mg"],
    title = "Julia Execution Time",
    ylabel = "Time (sec)",
    guidefontsize = 10,
    xtickfontsize = 10,
    ytickfontsize = 10,
    color = [:orange :steelblue],
    legend = :topleft,
    left_margin = 10Measures.mm  # ← FIX: Adds space for the cut-off ylabel
)

for i in eachindex(xpos)
    total_j = df_final_j.sol[i] + df_final_j.mg[i]
    annotate!(
        p1,
        xpos[i] - 0.5, # Standard center for stacked bar
        total_j * 1.5,
        text("mg+sol = $(fmt(total_j))s", 9, :black, :center)
    )
end

# --------------------------------------------------
# 6. GAMS plot
# --------------------------------------------------
p2 = bar(
    settings,
    [df_final_g.sol df_final_g.mg],
    bar_position = :stack,
    bar_width = 0.3,
    yscale = :log10,
    ylims = shared_ylims,
    fillrange = floor_val,
    label = ["sol" "mg"],
    title = "GAMS Execution Time",
    ylabel = "Time (sec)",
    guidefontsize = 10,
    xtickfontsize = 10,
    ytickfontsize = 10,
    color = [:orange :steelblue],
    legend = :topleft,
    left_margin = 5Measures.mm # Extra breathing room between plots
)

for i in eachindex(xpos)
    total_g = df_final_g.sol[i] + df_final_g.mg[i]
    annotate!(
        p2,
        xpos[i]-0.5,
        total_g * 1.5,
        text("mg+sol = $(fmt(total_g))s", 9, :black, :center)
    )
end

# --------------------------------------------------
# 7. Final layout
# --------------------------------------------------
# Using margin at the layout level ensures global spacing
cp = plot(p1, p2, layout = (1, 2), size = (1000, 400), margin = 5Measures.mm)
display(cp)

# Save
outpath = joinpath(@__DIR__, "./figures/", "stacked_barchart.png")
savefig(cp, outpath)