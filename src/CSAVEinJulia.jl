module CSAVEinJulia

    using CSV
    using NamedArrays
    using JLD2
    using MPSGE

    include("load_data.jl")

    export load_gtap9_data


    include("mge.jl")
    export MGE_model


end