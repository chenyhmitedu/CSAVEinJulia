using Plots
using Measures
using Printf
pyplot()

function fig_ci_lower(CI_lower::Float64, POINT_ESTIMATE::Float64,
                      ti::String, x_min::Float64, x_max::Float64)

    ZERO_LINE = 0.0
    X_MIN = x_min
    X_MAX = x_max
    Y_POSITION = 0.75

    p = plot(
        [ZERO_LINE, ZERO_LINE],
        [0, 1],
        label="No Difference (Zero)",
        linestyle=:dash,
        linecolor=:black,
        linewidth=1.5,

        title=ti,
        xlabel="Time Difference (Seconds)",
        xlims=(X_MIN, X_MAX),
        #xlims=(0,1),
        ylims=(0.5, 1.5),

        yguide=nothing,
        yformatter=_ -> "",
        yticks=([Y_POSITION]),

        ytickfont=font(10, :black),
        showaxis=:x,
        grid=false,

        size=(900, 400),
        margin=5mm,
        titlefont=font(14),
        xguidefont=font(10),
        tickfont=font(10),
        legend=:none
    )

    # --- Draw one-sided CI line (from lower bound to right edge) ---
    plot!([CI_lower, X_MAX], [Y_POSITION, Y_POSITION],
        linecolor=:red,
        linewidth=3,
        label=nothing
    )

    # --- Add arrow to indicate continuation ---
    annotate!(X_MAX, Y_POSITION,
        text("→", 14, :red, :left)
    )

    # --- Draw point estimate ---
    scatter!([POINT_ESTIMATE], [Y_POSITION],
        marker=:circle,
        markersize=5,
        markercolor=:red,
        label="Point Estimate"
    )

    # --- Annotate lower bound ---
    annotate!(CI_lower, Y_POSITION + 0.15,
        text(@sprintf("%.3f", CI_lower), 10, :red, :left)
    )

    display(p)
    return p
end