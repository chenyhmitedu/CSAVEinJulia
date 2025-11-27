
struct GTAPSet <: AbstractArray{String,1}
    elements::Vector{String}
    function GTAPSet(file_path::String)
        data = CSV.File(file_path) |>
            x -> [String(row[:Dim1]) for row in x]
        new(data)
    end
end

Base.size(s::GTAPSet) = size(s.elements)
Base.getindex(s::GTAPSet, i::Int) = s.elements[i]
Base.getindex(s::GTAPSet, I::Vararg{Int,N}) where {N} = getindex(s.elements, I...)


struct ParameterInfo{N,T}
    name::String
    domain::NTuple{N,Vector{T}}
    dimension_names::NTuple{N,Symbol}
    column_labels::NTuple{N,Symbol}
    ParameterInfo(name::String, dimension_names::NTuple{N,Symbol}, column_labels::NTuple{N,Symbol}, gtap_sets::Dict{Symbol, GTAPSet}) where {N} = begin
        domain = Tuple(
            gtap_sets[dimension_names[i]] for i in 1:N
        )
        new{N,String}(name, domain, dimension_names, column_labels)
    end
end

parameter_name(p::ParameterInfo) = p.name
parameter_domain(p::ParameterInfo) = p.domain
dimension_names(p::ParameterInfo) = p.dimension_names
column_labels(p::ParameterInfo) = p.column_labels

function load_parameter(parameter_info; base_dir = "/src/data/")

    X = NamedArray(
        zeros(length.(parm[:domain])),
        parm[:domain],
        parm[:actual_columns],
    )

    cols = parm[:columns]

    for row in CSV.File("src/data/eco2d.csv") 
        X[ [String(row[i]) for i in cols]...] = row[:Val]
    end

end

const __GTAP_PARAMETERS__ = [
    (name = "eco2d",   domain = (:i, :g, :r), columns = (:ii, :Dim2, :rr)),
    (name = "eco2i",   domain = (:i, :g, :r), columns = (:ii, :Dim2, :rr)),
    (name = "epsilon", domain = (:i, :r), columns = (:ii, :rr)),
    (name = "esubd",   domain = (:i,), columns = (:ii,)),
    (name = "esubm",   domain = (:i,), columns = (:ii,)),
    (name = "esubva",  domain = (:i,), columns = (:jj,)),
    (name = "eta",     domain = (:i,:r), columns = (:ii,:rr)),
    (name = "evd",     domain = (:i, :g, :r), columns = (:ii,:Dim2, :rr)),
    (name = "evi",     domain = (:i, :g, :r), columns = (:ii,:Dim2, :rr)),
    (name = "evt",     domain = (:i, :r, :r), columns = (:ii,:rr, :rr_1)),
    (name = "rtf",     domain = (:f, :i, :r), columns = (:ff,:Dim2, :rr)),
    (name = "rtfd",    domain = (:i, :g, :r), columns = (:ii,:Dim2, :rr)),
    (name = "rtfi",    domain = (:i, :g, :r), columns = (:ii,:Dim2, :rr)),
    (name = "rtms",    domain = (:i, :r, :r), columns = (:ii,:rr, :ss)),
    (name = "rto",     domain = (:g,  :r), columns = (:Dim1,:rr)),
    (name = "rtxs",    domain = (:i,  :r, :r), columns = (:ii, :rr, :ss)),
    (name = "vdfm",    domain = (:i, :g, :r), columns = (:ii, :Dim2, :rr)),
    (name = "vfm",     domain = (:f, :i, :r), columns = (:ff, :Dim2, :rr)),
    (name = "vifm",    domain = (:i, :g, :r), columns = (:ii, :Dim2, :rr)),
    (name = "vst",     domain = (:i, :r), columns = (:ii, :rr)),
    (name = "vst",     domain = (:i, :r), columns = (:ii, :rr)),
    (name = "vtwr",    domain = (:i, :i, :r, :r), columns = (:ii, :jj, :rr, :ss)),
    (name = "vxmd",    domain = (:i, :r, :r), columns = (:ii, :rr, :ss)),
]

const __GTAP_SETS__ = [:i, :f, :g, :r]

function load_gtap9_data(; base_directory::String = joinpath(@__DIR__, "data"))
    sets = Dict(
        s => GTAPSet(joinpath(base_directory, "set_$(s).csv")) for s in __GTAP_SETS__
    )

    parameters = Dict{Symbol, Any}()

    for pp in __GTAP_PARAMETERS__
        parm_info = ParameterInfo(pp.name, pp.domain, pp.columns, sets)
        name = parameter_name(parm_info)
        path = joinpath(base_directory, "$(name).csv")
        data_array = NamedArray(
            zeros(length.(parameter_domain(parm_info))),
            parameter_domain(parm_info),
            dimension_names(parm_info),
        )

        cols = column_labels(parm_info)

        for row in CSV.File(path)
            data_array[ [String(row[i]) for i in cols]...] = row[:Val]
        end

        parameters[Symbol(name)] = data_array
    end

    return (sets = sets, parameters = parameters)

end