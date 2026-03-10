using DataFrames, CSV, Plots, StatsPlots, Plots.Measures

# 0. Load your data
# Assuming your CSV has columns: Sector, USA, ROW
path_julia = joinpath(@__DIR__, "./results/", "output_y.csv")
df_j = CSV.read(path_julia, DataFrame)

path_gams = joinpath(@__DIR__, "./results/", "output_y_gams.csv")
df_g = CSV.read(path_gams, DataFrame)

# If output = 0 Julia reports output index = 0 while GAMS reports output index = 1. Fix GAMS output index to 0 here:


for i ∈ 1: nrow(df_g)
    if df_g.y[i]  == 1.0 && df_j.y[i] == 0.0
        df_g.y[i] = 0.0
    else
        # Do nothing 
    end
end


# 1. Ensure the labels are Strings, not Symbols
df_j.Sector = string.(df_j.x1) 
df_g.Sector = string.(df_g.x1) 


# ----------------------------------------------------------
# Split data by region
# ----------------------------------------------------------
df_j_usa = filter(row -> row.x2 == "USA", df_j)
df_j_row = filter(row -> row.x2 == "ROW", df_j)
df_g_usa = filter(row -> row.x2 == "USA", df_g)
df_g_row = filter(row -> row.x2 == "ROW", df_g)

# Optional: sort by value
sort!(df_j_usa, :y)
sort!(df_j_row, :y)
sort!(df_g_usa, :y)
sort!(df_g_row, :y)

gr() # Force the GR backend explicitly

# Create a new dataframe without those rows
df_j_usa_r = df_j_usa[Not(1:1), :][Not(11:48), :]
df_g_usa_r = df_g_usa[Not(1:1), :][Not(11:48), :]

#df_usa_r = df_usa

# Get the bar label vector and bar value vector
x_j_data = string.(df_j_usa_r.x1)
y_j_data = df_j_usa_r.y
x_g_data = string.(df_g_usa_r.x1)
y_g_data = df_g_usa_r.y

# CSAVEinJulia

function bchart(x_data::Vector{String3}, y_data::Vector{Float64}, titl::String)

    p_usa = bar(
        x_data, 
        y_data,   
        color = "#d8e2dc",              # Bar color, e.g., :blue
        xtickfont = font(9),            # Control font size
        xrotation = 90,                 # Present the bar labels vertically
        xticks = :all,                  # Tell Plots to show every label
    #    bottom_margin = 15mm,           # Increase margin significantly
        size = (400, 360),
        ylabel = "Output index",
        title = titl,
        titlefont = font(12),           # ← change title font size here
        ylims = (0.65, 1.1),             # ← y-axis range
        legend = false
    )

    # Horizontal shift to move label inside bar
    x_shift = 0.5   # tune between 0.25–0.4 if needed

    # Vertical offset (inside bar)
    # y_offset = -0.15 * maximum(y_data)
    y_offset = -0.1

    annotate!(
        p_usa,
        [(i - x_shift,
          y_data[i] + y_offset,
          text(string(round(y_data[i], digits=4)),
               9, :black, :center, rotation=90))
         for i in eachindex(y_data)]
    )

    hline!(p_usa, [1.0], linestyle = :dash, color = :black)

    return p_usa

end

p_usa_julia = bchart(x_j_data, y_j_data, "Selected sectoral outputs of USA:\n CSAVEinJulia")
p_usa_gams = bchart(x_g_data, y_g_data, "Selected sectoral outputs of USA:\n CSAVEinGAMS")

p_usa_combined = plot(
        p_usa_julia, 
        p_usa_gams, 
        layout=(1,2), 
        size=(1080,450), 
        titlefont=font(12),
        margin = 15mm 
    )

outpath = joinpath(@__DIR__, "./figures/", "barchart_USA.png")
savefig(p_usa_combined, outpath)