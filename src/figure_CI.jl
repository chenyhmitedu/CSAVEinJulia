using Plots
using Measures
pyplot() # Using PyPlot for reliable rendering

# --------------------------------------------------
# 1. Input Data
# --------------------------------------------------

# Point Estimate (Calculated as the midpoint for visualization)
POINT_ESTIMATE = (CI_lower + CI_upper) / 2 

# The name/label for the comparison
#COMPARISON_LABEL = "jMedian Difference (CGE wrapped - CGE unwrapped)"

# --------------------------------------------------

# --------------------------------------------------
# 2. Define Plot Parameters
# --------------------------------------------------
ZERO_LINE = 0.0
X_MIN = -0.04
X_MAX = 0.00 
Y_POSITION = 0.75

# --------------------------------------------------
# 3. Create the Plot (REVISED to show Y-Axis Label)
# --------------------------------------------------
p = plot(
    # --- 1. Draw the Line of No Difference (The Null Hypothesis) ---
    [ZERO_LINE, ZERO_LINE], 
    [0, 1], 
    label="No Difference (Zero)", 
    linestyle=:dash, 
    linecolor=:black, 
    linewidth=1.5,
    
    # --- 2. Set Overall Plot Attributes ---
    title="95% Confidence Interval for Median Runtime Difference",
    xlabel="Runtime Difference (Seconds)",
    
    xlims=(X_MIN, X_MAX),
    
    # Ensure the Y-axis has a bit of space
    ylims=(0.5, 1.5), 
    
    # --- REVISIONS TO SHOW Y-AXIS LABEL AND TICKS ---
    yguide=nothing,                     # Keep Y-axis label text hidden (we are using yticks for labeling)
    yformatter = _ -> "",               # Keep Y-axis tick numbers hidden
    
    # RESTORED: Show the comparison label on the Y-axis tick
    #yticks=([Y_POSITION], [COMPARISON_LABEL]), 
    yticks=([Y_POSITION]), 
    
    # ADDED: Set the font size for the label restored via yticks
    ytickfont=font(10, :black),
    
    showaxis=:x,                        # Only show the X-axis line (hides the vertical axis line)
    grid=false,
    
    # Font and size settings
    size=(900, 400), 
    margin=5mm,
    titlefont=font(14),
    xguidefont=font(10),
    tickfont=font(10),
    legend=:none
)

# --- 3. Draw the Confidence Interval Bar (Error Bar) ---
scatter!([POINT_ESTIMATE], [Y_POSITION], 
    xerr=([POINT_ESTIMATE - CI_lower], [CI_upper - POINT_ESTIMATE]),
    marker=:none, 
    linecolor=:red, 
    linewidth=3, 
    label=nothing
)

# --- 4. Draw the Point Estimate Dot ---
scatter!([POINT_ESTIMATE], [Y_POSITION], 
    marker=:circle, 
    markersize=5, 
    markercolor=:red, 
    label="Point Estimate"
)

# --- 5. Annotate the CI Limits ---
annotate!(CI_lower, Y_POSITION + 0.15, text(@sprintf("%.3f", CI_lower), 10, :red, :left))
annotate!(CI_upper, Y_POSITION + 0.15, text(@sprintf("%.3f", CI_upper), 10, :red, :right))

display(p)
# Save the figure
fig_path = joinpath(@__DIR__, "./figures/", "median_ci_dotplot.png")
savefig(p, fig_path)