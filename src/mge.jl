function MGE_model(; data_path::String = joinpath(@__DIR__, "IO.jld2"))

    data = load(data_path)    #k = keys(data)

    # Declare Vector similar to set declaration in GAMS
    data["set_fe"]      = [:coa, :gas, :p_c]
    data["set_elec"]    = [:ely]
    data["set_ne"]      = setdiff(data["set_i"], union(data["set_fe"], data["set_elec"]))
    data["set_tr"]      = [:wtp, :atp, :otp]


    set_i      = data["set_i"]
    set_g      = data["set_g"]
    set_r      = data["set_r"]
    set_f      = data["set_f"]
    set_sf     = data["set_sf"]
    set_mf     = data["set_mf"]
    set_fe     = data["set_fe"]
    set_elec   = data["set_elec"]
    set_ne     = data["set_ne"]
    set_tr     = data["set_tr"]
    set_cgi   = data["set_cgi"]
    

    MGE  = MPSGEModel()

    @parameters(MGE, begin
        rtfd[i=set_i, g=set_g, r=set_r],    data["rtfd0"][i, g, r], (description = "Firms' domestic tax rates")
        rtfi[i=set_i, g=set_g, r=set_r],    data["rtfi0"][i, g, r], (description = "Firms' import tax rates")
        rtms[i=set_i, r=set_r, s=set_r],    data["rtms0"][i, r, s], (description = "Import tax rates")
        rtxs[i=set_i, r=set_r, s=set_r],    data["rtxs0"][i, r, s], (description = "Export subsidy rates")
        rto[g=set_g, r=set_r],              data["rto0"][g, r],     (description = "Output subsidy rates")              
        rtf[f=set_f, i=set_i, r=set_r],     data["rtf0"][f, i, r],  (description = "Primary factor tax rates")
    end)

    @sectors(MGE, begin
        Y[set_g, set_r],            (description = "Supply")
        M[set_i, set_r],            (description = "Imports")
        YT[set_i],                  (description = "Transportation services")
        E[set_i, set_r, set_r],     (description = "Subsidy and transport service included exports")
        A[set_i, set_g, set_r],     (description = "Armington good")
    end)

    @commodities(MGE, begin
        P[set_g, set_r],            (description = "Domestic output price")
        PM[set_i, set_r],           (description = "Import price")
        PT[set_i],                  (description = "Transportation services")
        PF[set_mf, set_r],          (description = "Non-sector-specific primary factor rent")
        PS[set_sf, set_g, set_r],   (description = "Sector-specific primary factor rent")  
        PX[set_i, set_r, set_r],    (description = "Price index for exports (include subsidy and transport service)")
        PA[set_i, set_g, set_r],    (description = "Price index for Armington good")
        PE[set_i, set_r],           (description = "Price index for exports (exclude subsidy and transport service)")
    end)

    @consumers(MGE, begin
        RA[set_r],                  (description = "Representative agent")
    end)

    for i ∈ set_i, g ∈ set_g, r ∈ set_r
        @production(MGE, A[i, g, r], [t = 0, s = data["esubd"][i]], begin
            @output(PA[i, g, r],    data["vafm"][i, g, r],  t)
            @input(P[i, r],         data["vdfm"][i, g, r],  s,   taxes = [Tax(RA[r], rtfd[i, g, r])],   reference_price = 1 + data["rtfd0"][i, g, r])
            @input(PM[i, r],        data["vifm"][i, g, r],  s,   taxes = [Tax(RA[r], rtfi[i, g, r])],   reference_price = 1 + data["rtfi0"][i, g, r])  
        end)
    end

    for g ∈ set_i, r ∈ set_r
        @production(MGE, Y[g, r], [t = data["etadx"][g], s = data["esub"][g], sn => s = data["esubn"][g], sve => sn = data["esubve"][g], sva => sve = data["esubva"][g], sef => sve = data["esubef"][g], sf => sef = data["esubf"][g]], begin
            @output(P[g, r],         data["vhm"][g, r], t, taxes = [Tax(RA[r], rto[g, r])], reference_price = 1-data["rto0"][g, r])
            @output(PE[g, r],        data["vxm"][g, r], t, taxes = [Tax(RA[r], rto[g, r])], reference_price = 1-data["rto0"][g, r])    
            [@input(PA[i, g, r],     data["vafm"][i, g, r], sf) for i ∈ set_fe]...
            [@input(PA[i, g, r],     data["vafm"][i, g, r], sef) for i ∈ set_elec]...
            [@input(PA[i, g, r],     data["vafm"][i, g, r], sn) for i ∈ set_ne]...
            [@input(PS[sf, g, r],    data["vfm"][sf, g, r],  s, taxes = [Tax(RA[r], rtf[sf, g, r])],   reference_price = 1 + data["rtf0"][sf, g, r])   for sf ∈ set_sf]...
            [@input(PF[mf, r],       data["vfm"][mf, g, r],  sva, taxes = [Tax(RA[r], rtf[mf, g, r])],   reference_price = 1 + data["rtf0"][mf, g, r])   for mf ∈ set_mf]...
        end)
    end






    for g ∈ set_cgi, r ∈ set_r
        @production(MGE, Y[g, r], [t = 0, s = data["esub"][g], sn => s = data["esubn"][g], sef => sn = data["esubef"][g], sf => sef = data["esubf"][g]], begin
            @output(P[g, r],         data["vom"][g, r], t, taxes = [Tax(RA[r], rto[g, r])])
            [@input(PA[i, g, r],     data["vafm"][i, g, r], sf) for i ∈ set_fe]...
            [@input(PA[i, g, r],     data["vafm"][i, g, r], sef) for i ∈ set_elec]...
            [@input(PA[i, g, r],     data["vafm"][i, g, r], sn) for i ∈ set_ne]...
        end)
    end

    for j ∈ set_i
        @production(MGE, YT[j], [t = 0, s = 1], begin
            @output(PT[j],          data["vtw"][j],         t)
            [@input(PE[j, r],       data["vst"][j, r],      s)   for r ∈ set_r]...
        end)
    end

    for i ∈ set_i, r ∈ set_r
        @production(MGE, M[i, r], [t = 0, s = data["esubm"][i]], begin
            @output(PM[i, r],       data["vim"][i, r],      t)
            [@input(PX[i, s, r],    data["vxmd"][i, s, r]*(1 - data["rtxs0"][i, s, r]) + sum(data["vtwr"][j, i, s, r] for j ∈ set_tr), s, taxes = [Tax(RA[r], rtms[i, s, r])], reference_price = data["pvtwr"][i, s, r]) for s ∈ set_r]...
        end)
    end

    # vxmr = Dict((i, s, r) => vxmd[i, s, r]*(1 - rtxs0[i, s, r]) + sum(vtwr[j, i, s, r] for j ∈ set_tr)

    for i ∈ set_i, s ∈ set_r, r ∈ set_r
        @production(MGE, E[i, s, r], [t = 0, s = 0], begin
            [@output(PX[i, s, r],   data["vxmd"][i, s, r]*(1 - data["rtxs0"][i, s, r]) + sum(data["vtwr"][j, i, s, r] for j ∈ set_tr), t)]...
            @input(PE[i, s],        data["vxmd"][i, s, r], s,   taxes = [Tax(RA[s], -rtxs[i, s, r])],   reference_price = 1 - data["rtxs0"][i, s, r])
            [@input(PT[j],          data["vtwr"][j, i, s, r], s) for j ∈ set_i]...
        end)
    end

    for r ∈ set_r 
        @demand(MGE, RA[r], begin
            @final_demand(P[:c, r], data["vom"][:c, r])
            @endowment(P[:c, :USA], data["vb"][r])
            @endowment(P[:g, r], -data["vom"][:g, r])
            @endowment(P[:i, r], -data["vom"][:i, r])
            [@endowment(PF[f, r], data["evom"][f, r]) for f ∈ set_mf]...
            [@endowment(PS[f, j, r], data["vfm"][f, j, r]) for f ∈ set_sf, j ∈ set_i]...
        end)
    end

    fix(P[:c, :USA], 1)


    return MGE, data

end