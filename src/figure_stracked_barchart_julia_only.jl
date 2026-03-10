using Plots
using StatsPlots

# 1. Prepare the data from the image
settings = ["56x2", "56x4", "56x8", "56x16", "56x32", "56x50", "56x61", "56x74", "56x80"]

# Time in seconds for 'mg'
mg_vals = [0.518886, 1.379776, 3.212122, 8.886282, 23.85234, 49.83804, 65.50798, 89.25249, 110.7142]

# Time in seconds for 'sol' (The last value was missing in the image, so it's set to 0.0)
sol_vals = [0.8015, 1.757708, 4.640871, 61.41209, 194.4679, 558.0575, 1032.779, 2049.525, 0.0]

# 2. Combine into a matrix for stacking (rows = settings, columns = type)
data_matrix = hcat(sol_vals, mg_vals)

# 3. Create the plot
groupedbar(
    settings, 
    data_matrix,
    bar_position = :stack,
    label = ["sol" "mg"],
    title = "Julia Execution Time: mg vs sol",
    xlabel = "Setting",
    ylabel = "Time (sec)",
    legend = :topleft,
    color = [:steelblue :orange],
    size = (800, 500)
)