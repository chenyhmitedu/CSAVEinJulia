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
        Y[g=set_g, r=set_r],          (description = "Supply")
        M[i=set_i, r=set_r],          (description = "Imports")
        YT[i=set_i],                  (description = "Transportation services")
        E[i=set_i, r=set_r, s=set_r], (description = "Subsidy and transport service included exports")
        A[i=set_i, g=set_g, r=set_r], (description = "Armington good")
    end)

    @commodities(MGE, begin
        P[g=set_g, r=set_r],             (description = "Domestic output price")
        PM[i=set_i, r=set_r],            (description = "Import price")
        PT[i=set_i],                     (description = "Transportation services")
        PF[mf=set_mf, r=set_r],          (description = "Non-sector-specific primary factor rent")
        PS[sf=set_sf, g=set_g, r=set_r], (description = "Sector-specific primary factor rent")  
        PX[i=set_i, r=set_r, s=set_r],   (description = "Price index for exports (include subsidy and transport service)")
        PA[i=set_i, g=set_g, r=set_r],   (description = "Price index for Armington good")
        PE[i=set_i, r=set_r],            (description = "Price index for exports (exclude subsidy and transport service)")
    end)

    @consumers(MGE, begin
        RA[r=set_r],              (description = "Representative agent")
    end)

    @production(MGE, A[i = set_i, g = set_g, r = set_r], [t = 0, s = data["esubd"][i]], begin
        @output(PA[i, g, r],    data["vafm"][i, g, r],  t)
        @input(P[i, r],         data["vdfm"][i, g, r],  s,   taxes = [Tax(RA[r], rtfd[i, g, r])],   reference_price = 1 + data["rtfd0"][i, g, r])
        @input(PM[i, r],        data["vifm"][i, g, r],  s,   taxes = [Tax(RA[r], rtfi[i, g, r])],   reference_price = 1 + data["rtfi0"][i, g, r])  
    end)

    @production(MGE, Y[g = set_i, r = set_r], [t = data["etadx"][g], s = data["esub"][g], sn => s = data["esubn"][g], sve => sn = data["esubve"][g], sva => sve = data["esubva"][g], sef => sve = data["esubef"][g], sf => sef = data["esubf"][g]], begin
        @output(P[g, r],               data["vhm"][g, r],      t,  taxes = [Tax(RA[r], rto[g, r])], reference_price = 1-data["rto0"][g, r])
        @output(PE[g, r],              data["vxm"][g, r],      t,  taxes = [Tax(RA[r], rto[g, r])], reference_price = 1-data["rto0"][g, r])    
        @input(PA[i = set_fe, g, r],   data["vafm"][i, g, r], sf)
        @input(PA[i = set_elec, g, r], data["vafm"][i, g, r], sef) 
        @input(PA[i = set_ne, g, r],   data["vafm"][i, g, r], sn) 
        @input(PS[sf = set_sf, g, r],  data["vfm"][sf, g, r],  s,   taxes = [Tax(RA[r], rtf[sf, g, r])],   reference_price = 1 + data["rtf0"][sf, g, r])   
        @input(PF[mf = set_mf, r],     data["vfm"][mf, g, r],  sva, taxes = [Tax(RA[r], rtf[mf, g, r])],   reference_price = 1 + data["rtf0"][mf, g, r])   
    end)

    @production(MGE, Y[g = set_cgi, r=set_r], [t = 0, s = data["esub"][g], sn => s = data["esubn"][g], sef => sn = data["esubef"][g], sf => sef = data["esubf"][g]], begin
        @output(P[g, r],               data["vom"][g, r], t, taxes = [Tax(RA[r], rto[g, r])])
        @input(PA[i = set_fe, g, r],   data["vafm"][i, g, r], sf)
        @input(PA[i = set_elec, g, r], data["vafm"][i, g, r], sef)
        @input(PA[i = set_ne, g, r],   data["vafm"][i, g, r], sn)
    end)
    
    @production(MGE, YT[j = set_i], [t = 0, s = 1], begin
        @output(PT[j],           data["vtw"][j],         t)
        @input(PE[j, r = set_r], data["vst"][j, r],      s)
    end)
    
    data["vxmr"] = Dict(
            (i, s, r) => data["vxmd"][i, s, r]*(1 - data["rtxs0"][i, s, r]) + sum(data["vtwr"][j, i, s, r] for j ∈ set_tr)
            for i∈set_i, r∈set_r, s∈set_r
        )

    @production(MGE, M[i = set_i, r = set_r], [t = 0, s = data["esubm"][i]], begin
        @output(PM[i, r],           data["vim"][i, r],      t)
        @input(PX[i, s = set_r, r], data["vxmr"][i, s, r], taxes = [Tax(RA[r], rtms[i, s, r])], reference_price = data["pvtwr"][i, s, r])
    end)
    
    @production(MGE, E[i = set_i, s = set_r, r = set_r], [t = 0, s = 0], begin
        @output(PX[i, s, r],  data["vxmr"][i, s, r], t)
        @input(PE[i, s],      data["vxmd"][i, s, r], s,   taxes = [Tax(RA[s], -rtxs[i, s, r])],   reference_price = 1 - data["rtxs0"][i, s, r])
        @input(PT[j = set_i], data["vtwr"][j, i, s, r], s)
    end)
    
    @demand(MGE, RA[r = set_r], begin
        @final_demand(P[:c, r],                  data["vom"][:c, r])
        @endowment(P[:c, :USA],                  data["vb"][r])
        @endowment(P[:g, r],                    -data["vom"][:g, r])
        @endowment(P[:i, r],                    -data["vom"][:i, r])
        @endowment(PF[f = set_mf, r],            data["evom"][f, r])
        @endowment(PS[f = set_sf, j = set_i, r], data["vfm"][f, j, r])
    end)
    

    fix(P[:c, :USA], 1)


    return MGE, data

end