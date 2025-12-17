using Plots
using StatsBase
using Printf
using Measures # Provides units like 'mm'
using Distributions # Needed for generating skewed sample data
pyplot() # Using PyPlot backend
# --------------------------------------------------

# --------------------------------------------------
# 1. Sample Data Generation (REPLACE WITH YOUR X1, X2)
# --------------------------------------------------
N = 1000 # Number of samples
data_A = X1
data_B = X2
# --------------------------------------------------

# --------------------------------------------------
# 2. Compute statistics
# --------------------------------------------------
stats_A = (min=minimum(data_A), median=median(data_A), mean=mean(data_A), max=maximum(data_A))
stats_B = (min=minimum(data_B), median=median(data_B), mean=mean(data_B), max=maximum(data_B))

# --------------------------------------------------
# 3. Helper function: upward arrows + labels 
# --------------------------------------------------
function add_stat_arrows!(p, stats; base_frac=0.04, step_frac=0.05, digits=2, axis_pad_frac=0.15)
    xs = [stats.min, stats.median, stats.mean, stats.max]
    names = ["Min", "Median", "Mean", "Max"]
    labels = [@sprintf("%s = %.*f", n, digits, x) for (n, x) in zip(names, xs)]

    xmin, xmax = xlims(p)
    ymin, ymax = ylims(p)
    xrange = xmax - xmin
    yrange = ymax - ymin
    y_axis = ymin

    x_nudge = xrange * 0.015
    x_offsets = [-x_nudge, 0.0, 0.0, x_nudge] 

    new_ymin = ymin - axis_pad_frac * yrange
    plot!(p, ylims=(new_ymin, ymax))

    lengths = yrange .* (base_frac .+ step_frac .* (0:3)) 
    
    # Define a custom, VERY SMALL arrow style
    smaller_arrow = arrow(:closed, 0.3, 0.3) # <--- Small size for PyPlot

    for (i, (x, lab, dy)) in enumerate(zip(xs, labels, lengths))
        y0 = y_axis - dy
        
        # Draw the quiver with a MINIMAL linewidth (0.5) to ensure rendering
        quiver!([x],[y0], quiver=([0.0],[dy]), arrow=smaller_arrow, linewidth=0.5, color=:red, label=nothing) # <--- LINEWIDTH CHANGE

        label_x = x + x_offsets[i]
        align = x_offsets[i] < 0 ? :right : (x_offsets[i] > 0 ? :left : :center)

        # Set font size for labels of statistics 
        annotate!(p, label_x, y0 - 0.3dy, text(lab, 10, :red, align)) 
    end
end
# --------------------------------------------------

# --------------------------------------------------
# 4. Plot A
# --------------------------------------------------
p1 = histogram(data_A, bins=:auto, normalize=:probability,
               label=nothing, title="CGE wrapped in a function\n(sample size = 1000)",
               xlabel="Time (sec)", ylabel="Probability", fillcolor=:green,     # Set histogram bar color
               size=(450,500),
               xticks=false,
               xguidefont=font(10), # Set font size for horizontal axis label
               yguidefont=font(10), # Set font size for vertical axis label
               ytickfont=font(10),  # Set font size for the y axis tick mark
               ylims = (0.0, 0.22)  # Set the range of y axis
               )

add_stat_arrows!(p1, stats_A)

# --------------------------------------------------
# 5. Plot B
# --------------------------------------------------
p2 = histogram(data_B, bins=:auto, normalize=:probability,
               label=nothing, title="CGE not wrapped in a function\n(sample size = 1000)",
               xlabel="Time (sec)", ylabel="Probability", fillcolor=:orange,    # Set histogram bar color    
               size=(450,500),
               xticks=false,
               xguidefont=font(10), # Set font size for horizontal axis label 
               yguidefont=font(10), # Set font size for vertical axis label
               ytickfont=font(10),  # Set font size for the y axis tick mark
               ylims = (0.0, 0.22)  # Set the range of y axis
               )

add_stat_arrows!(p2, stats_B)

# --------------------------------------------------
# 6. Combine plots 
# --------------------------------------------------
final_plot = plot(
    p1, 
    p2, 
    layout=(1,2), 
    size=(1200,500), 
    titlefont=font(14),
    margin = 15mm 
)

display(final_plot)
fig_path = joinpath(@__DIR__, "./figures/", "wrapped_vs_not_wrapped.png")
savefig(final_plot, fig_path)