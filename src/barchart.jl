function draw_barchart(trial_object, fig_title)

    CairoMakie.activate!() # Use a reliable backend for saving files

    # 1. Run your benchmark and get the Trial object (b)
    b = trial_object

    # 2. Extract key data points
    raw_times_ms = b.times ./ 1_000_000 # Times in milliseconds
    median_time = b.times |> median |> x -> x / 1_000_000 # Median time in ms

    # 3. Create the Figure and Axis
    fig = Figure(size = (800, 500))
    ax = Axis(fig[1, 1], 
        title = fig_title, 
        xlabel = "Time (ms)", 
        ylabel = "Frequency"
    )

    # 4. Plot the histogram
    hist!(ax, raw_times_ms, bins=20, color=(:blue, 0.6))
    vlines!(ax, median_time, color = :red, linestyle = :dash, linewidth=2)

    # 5. Add the statistical summary as text (Optional but mimics your request)

    # 5. Add the statistical summary as text (CORRECTED)
    stats_text = string(
        "BenchmarkTools.Trial: ", length(b.times), " samples\n",
        "---------------------------------------------------\n",
        "Median: ", round((b.times |> median) / 1_000_000, digits=3), " ms\n",
        "Mean (± σ): ", round((b.times |> mean) / 1_000_000, digits=3), " ± ", 
        round((b.times |> std) / 1_000_000, digits=3), " ms\n",
        "Range: ", round((b.times |> minimum) / 1_000_000, digits=3), " ms ... ",
        round((b.times |> maximum) / 1_000_000, digits=3), " ms"
    )

    Label(fig[1, 2], stats_text, justification = :left, tellheight = false)

    return fig
end

