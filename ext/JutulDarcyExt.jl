module JutulDarcyExt

using ConfigurationsJutulDarcy
using JutulDarcy
using JutulDarcy.Jutul

function Jutul.CartesianMesh(options::MeshOptions)
    return CartesianMesh(options.n, options.n .* options.d; origin=options.origin)
end

function ConfigurationsJutulDarcy.create_field(mesh::CartesianMesh, options::FieldOptions)
    return create_field(mesh.dims, options)
end

function ConfigurationsJutulDarcy.create_field(
    mesh::UnstructuredMesh, options::FieldOptions
)
    return create_field(nothing, options.suboptions)
end

function JutulDarcy.reservoir_domain(mesh, options::JutulOptions; kwargs...)
    porosity = create_field(mesh, options.porosity)
    temperature = create_field(mesh, options.temperature)
    permeability = create_field(mesh, options.permeability)
    permeability = Kto3(permeability; kvoverkh=options.permeability_v_over_h)
    rock_density = create_field(mesh, options.rock_density)
    rock_heat_capacity = create_field(mesh, options.rock_heat_capacity)
    rock_thermal_conductivity = create_field(mesh, options.rock_thermal_conductivity)
    fluid_thermal_conductivity = create_field(mesh, options.fluid_thermal_conductivity)
    component_heat_capacity = create_field(mesh, options.component_heat_capacity)
    return domain = reservoir_domain(
        mesh;
        permeability,
        porosity,
        temperature,
        rock_density,
        rock_heat_capacity,
        rock_thermal_conductivity,
        fluid_thermal_conductivity,
        component_heat_capacity,
        kwargs...,
    )
end

import JutulDarcy.Jutul: find_enclosing_cells

function JutulDarcy.setup_well(D::DataDomain, options::WellOptions; kwargs...)
    mesh = physical_representation(D)
    reservoir_cells = find_enclosing_cells(mesh, collect(options.trajectory))
    if length(reservoir_cells) == 0
        error(
            "Invalid options: well trajectory does not pass through mesh: $(options.name) $(options.trajectory)",
        )
    end
    return setup_well(
        D, reservoir_cells; name=options.name, simple_well=options.simple_well, kwargs...
    )
end

function JutulDarcy.InjectorControl(options::WellRateOptions)
    rate_kg_s = options.rate_mtons_year * 1e9 / (365.2425 * 24 * 60 * 60)
    rate_m3_s = rate_kg_s / options.fluid_density
    rate_target = TotalRateTarget(rate_m3_s)
    return I_ctrl = InjectorControl(rate_target, [0.0, 1.0]; density=options.fluid_density)
end

function setup_control(options)
    if options.type == "injector"
        return InjectorControl(options)
    end
    return error("Not implemented for type: $type")
end

function JutulDarcy.setup_reservoir_forces(model, options::Tuple; bc)
    nsteps = sum(x -> x.steps, options)
    dt = fill(0.0, nsteps)
    forces = Vector{Any}(undef, nsteps)

    start_step = 1
    for opt in options
        stop_step = start_step + opt.steps - 1
        control = Dict(Symbol(o.name) => setup_control(o) for o in opt.controls)
        forces_opt = setup_reservoir_forces(model; control, bc)
        dt[start_step:stop_step] .= (365.2425 * 24 * 60 * 60) * opt.years / opt.steps
        fill!(view(forces, start_step:stop_step), forces_opt)
        start_step = stop_step + 1
    end
    return dt, forces
end

function JutulDarcy.setup_reservoir_model(domain, options::SystemOptions; extra_out=false, kwargs...)
    model = setup_reservoir_model(
        domain, get_label(options); get_kwargs(options)..., extra_out=false, kwargs...
    )
    sys = model.models.Reservoir.system
    replace_variables!(
        model;
        RelativePermeabilities=BrooksCoreyRelativePermeabilities(
            sys, [2.0, 2.0], [0.1, 0.1], 1.0
        ),
    )
    if extra_out
        parameters = setup_parameters(model)
        return model, parameters
    end
    return model
end

function JutulDarcy.setup_reservoir_state(
    model, options::CO2BrineOptions; Saturations=nothing, kwargs...
)
    if options.co2_physics == :immiscible
        state0 = setup_reservoir_state(model; Saturations, kwargs...)
    else
        state0 = setup_reservoir_state(model; OverallMoleFractions=Saturations, kwargs...)
    end
end

function JutulDarcy.setup_reservoir_model(mesh, options::JutulOptions)
    domain = reservoir_domain(mesh, options)
    Injector = setup_well(domain, options.injection)
    return setup_reservoir_model(domain, options.system; wells=Injector)
end

function JutulDarcy.setup_reservoir_model(
    domain::DataDomain,
    ::Val{:co2brine_simple};
    ρH2O=1053.0, # kg/m^3
    ρCO2=501.9,  # kg/m^3
    visCO2=1e-4, # Pascal seconds (decapoise) Reference: https://github.com/lidongzh/FwiFlow.jl
    visH2O=1e-3, # Pascal seconds (decapoise) Reference: https://github.com/lidongzh/FwiFlow.jl
    compCO2=8e-9, # 1 / Pascals
    compH2O=3.6563071e-10, # 1 / Pascals
    p_ref=1.5e7, # Pascals
    extra_out=false,
    kwargs...,
)
    sys = ImmiscibleSystem((LiquidPhase(), VaporPhase()); reference_densities=[ρH2O, ρCO2])
    model = setup_reservoir_model(domain, sys; kwargs..., extra_out=false)
    domain[:PhaseViscosities, NoEntity()] = [visH2O, visCO2]

    outvar = model[:Reservoir].output_variables
    push!(outvar, :Saturations)
    push!(outvar, :PhaseMassDensities)
    unique!(outvar)

    density_ref = [ρH2O, ρCO2]
    compressibility = [compH2O, compCO2]
    ρ = ConstantCompressibilityDensities(; p_ref, density_ref, compressibility)
    replace_variables!(model; PhaseMassDensities=ρ)

    for (k, m) in pairs(model.models)
        if k == :Reservoir || JutulDarcy.model_or_domain_is_well(m)
            set_secondary_variables!(m; PhaseMassDensities=ρ)
            set_parameters!(m; Temperature=JutulDarcy.Temperature())
        end
    end
    if extra_out
        parameters = setup_parameters(model)
        return model, parameters
    end
    return model
end

function Jutul.default_parameter_values(data_domain, model, param::JutulDarcy.PhaseViscosities, symb)
    if haskey(data_domain, :PhaseViscosities, Cells())
        return data_domain[:PhaseViscosities]
    end
    if haskey(data_domain, :PhaseViscosities, NoEntity())
        nc = data_domain.entities[Cells()]
        vis = data_domain[:PhaseViscosities, NoEntity()]
        return repeat(vis, 1, nc)
    end
    return Jutul.default_values(model, param)
end

end # module
