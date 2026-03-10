using DataFrames, CSV, Plots, StatsPlots

# --------------------------------------------------
# 0. Load data
# --------------------------------------------------
path = joinpath(@__DIR__, "./runtime/", "mg_sol_time.csv")
df = CSV.read(path, DataFrame)

# Because "56x16" comes before "56x2" alphabetically, we need to tell Julia to sort based on 
# the numeric value after the "x"

df = sort(df, :setting, by = x -> parse(Int, split(x, 'x')[2]))

#target_settings = ["56x2", "56x4", "56x8", "56x16", "56x32", "56x50", "56x61", "56x74", "56x80"]
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

x_j_data = string.(df_final_j.setting)
y_j_data = df_final_j.mg
x_g_data = string.(df_final_g.setting)
y_g_data = df_final_g.mg

y_max = max(maximum(y_j_data), maximum(y_g_data))


function bchart(x_data::Vector{String7}, y_data::Vector{Float64}, titl::String)

    p_usa = bar(
        x_data, 
        y_data,   
        color = "#d8e2dc",              # Bar color, e.g., :blue
        bar_width = 0.3,
        xtickfont = font(9),            # Control font size
        xrotation = 90,                 # Present the bar labels vertically
        xticks = :all,                  # Tell Plots to show every label
    #    bottom_margin = 15mm,           # Increase margin significantly
        size = (400, 360),
        ylabel = "Time (sec)",
        title = titl,
        titlefont = font(12),           # ← change title font size here
        ylims = (0, y_max*1.1),             # ← y-axis range
        legend = false
    )

    # Horizontal shift to move label inside bar
    x_shift = 0.5   # tune between 0.25–0.4 if needed

    # Vertical offset (inside bar)
    # y_offset = -0.15 * maximum(y_data)
    y_offset = 0.5

    
    annotate!(
        p_usa,
        [(i - x_shift,
          y_data[i] + y_offset,
        #  text(string(round(y_data[i], digits=3)),
        #       9, :black, :center, rotation=90))
        #  text(string(round(y_data[i], digits=3)), 9, :black, :center))
        text("$(round(y_data[i], digits=3)) s", 9, :black, :center))
         for i in eachindex(y_data)]
    )

    # hline!(p_usa, [1.0], linestyle = :dash, color = :black)
    
    return p_usa

end

p_usa_julia = bchart(x_j_data, y_j_data, "Model generation time:\n CSAVEinJulia")
p_usa_gams = bchart(x_g_data, y_g_data, "Model generation time:\n CSAVEinGAMS")

p_usa_combined = plot(
        p_usa_julia, 
        p_usa_gams, 
        layout=(1,2), 
        size=(1080,450), 
        titlefont=font(12),
        margin = 15mm 
    )

outpath = joinpath(@__DIR__, "./figures/", "barchart_MG_julia_vs_GAMS.png")
savefig(p_usa_combined, outpath)