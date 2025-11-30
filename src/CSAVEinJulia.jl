module CSAVEinJulia

    using CSV
    using JLD2
    using MPSGE
    using GTAPdata

    include("load_data.jl")
    export load_gtap_data

    include("mge.jl")
    export MGE_model

end