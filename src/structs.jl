using Configurations: Configurations, @option
using StaticArrays: SVector

export JutulOptions, MeshOptions
export SystemOptions, CO2BrineOptions, CO2BrineSimpleOptions, get_label, get_kwargs
export FieldOptions, FieldConstantOptions, FieldFileOptions
export FluidOptions
export WellOptions, WellRateOptions, WellPressureOptions
export TimeDependentOptions

@option struct MeshOptions
    "Grid dimensions"
    n::Tuple = (30, 1, 20)

    "Grid cell size"
    d::Tuple = (12.5, 100.0, 6.25)

    origin::Tuple = (0.0, 0.0, 0.0)
end

abstract type SystemOptions end

@option struct CO2BrineOptions <: SystemOptions
    co2_physics::Symbol = :immiscible
    thermal::Bool = false
    extra_kwargs = (;)
end

get_label(::CO2BrineOptions) = :co2brine

function get_kwargs(options::CO2BrineOptions)
    return (;
        thermal=options.thermal, co2_physics=options.co2_physics, options.extra_kwargs...
    )
end

@option struct CO2BrineSimpleOptions <: SystemOptions
    viscosity_CO2 = 1e-4 # Pascal seconds (decapoise) Reference: https://github.com/lidongzh/FwiFlow.jl
    viscosity_H2O = 1e-3 # Pascal seconds (decapoise) Reference: https://github.com/lidongzh/FwiFlow.jl
    density_CO2 = 501.9 # kg/m^3
    density_H2O = 1053.0 # kg/m^3
    reference_pressure = 1.5e7 # Pascals
    compressibility_CO2 = 8e-9 # 1 / Pascals (should be reciprocal of bulk modulus)
    compressibility_H2O = 3.6563071e-10 # 1 / Pascals (should be reciprocal of bulk modulus)
    extra_kwargs = (;)
end

get_label(::CO2BrineSimpleOptions) = :co2brine_simple

function get_kwargs(options::CO2BrineSimpleOptions)
    return (;
        visCO2=options.viscosity_CO2,
        visH2O=options.viscosity_H2O,
        ρCO2=options.density_CO2,
        ρH2O=options.density_H2O,
        p_ref=options.reference_pressure,
        compCO2=options.compressibility_CO2,
        compH2O=options.compressibility_H2O,
        options.extra_kwargs...,
    )
end

@option struct FluidOptions
    "Identifier for viewing options"
    name::Any

    "Pascal seconds (decapoise) Reference: https://github.com/lidongzh/FwiFlow.jl"
    viscosity::Float64

    "kg/m^3"
    density::Float64

    "1 / Pascals (should be reciprocal of bulk modulus)"
    compressibility::Float64
end

@option struct FieldConstantOptions
    value::Any
end

@option struct FieldFileOptions
    file = nothing
    idx = nothing
    key = nothing
    scale = 1
    resize::Bool = false
end

@option struct FieldOptions
    name::Symbol = :field
    suboptions
end
function FieldOptions(value; kwargs...)
    return FieldOptions(; kwargs..., suboptions=FieldConstantOptions(; value))
end

@option struct WellOptions
    active::Bool = true
    trajectory::Tuple
    simple_well::Bool = true
    name::Symbol
end

@option struct WellRateOptions
    type
    name
    "kg/m^3"
    fluid_density::Float64
    rate_mtons_year::Float64
end

@option struct WellPressureOptions
    "Pa"
    bottom_hole_pressure_target::Float64
end

@option struct TimeDependentOptions
    years::Float64
    steps::Int64 = 1
    controls::Tuple
end

@option struct JutulOptions
    mesh::MeshOptions = MeshOptions()

    "number of time steps stored in one file"
    nt::Int64 = 25

    system::SystemOptions = CO2BrineOptions()

    "time interval between 2 adjacent time steps (in days)"
    dt::Float64 = 73.0485

    "number of files, each of which has nt timesteps."
    nbatches::Int64 = 1

    "ratio of vertical permeability over horizontal permeability."
    kv_over_kh::Float64 = 0.36

    sat0_radius_cells::Int64 = 4
    sat0_range::Tuple{Float64,Float64} = (0.2, 0.8)

    fluid1::FluidOptions = FluidOptions(;
        name="H₂O", viscosity=1e-3, density=1.053e3, compressibility=3.6563071e-10
    )

    fluid2::FluidOptions = FluidOptions(;
        name="CO₂", viscosity=1e-4, density=7.766e2, compressibility=8e-9
    )

    "m/s^2"
    g::Float64 = 9.81

    "Pascals"
    reference_pressure::Float64 = 1.5e7

    porosity::FieldOptions = FieldOptions(0.1)
    permeability::FieldOptions = FieldOptions(9.869233e-14)
    permeability_v_over_h::Float64 = 0.36
    temperature::FieldOptions = FieldOptions(3e2)
    rock_density::FieldOptions = FieldOptions(2000.0)
    rock_heat_capacity::FieldOptions = FieldOptions(900.0)
    rock_thermal_conductivity::FieldOptions = FieldOptions(3.0)
    fluid_thermal_conductivity::FieldOptions = FieldOptions(0.6)
    component_heat_capacity::FieldOptions = FieldOptions(4184.0)

    injection::WellOptions = WellOptions(;
        trajectory=(SVector(1875.0, 50.0, 1693.75), SVector(1875.0, 50.0, 1693.75 + 37.5)),
        name=:Injector,
    )

    production::WellOptions = WellOptions(; active=false, trajectory=(), name=:Producer)

    time::Tuple = (
        TimeDependentOptions(;
            years=1.0,
            steps=10,
            controls=(
                WellRateOptions(;
                    type="injector", name=:Injector, fluid_density=5e2, rate_mtons_year=1e-3
                ),
            ),
        ),
        TimeDependentOptions(; years=1.0, steps=10, controls=()),
    )
end

# Define copy constructors and hash function.
for T in [
    :JutulOptions,
    :MeshOptions,
    :CO2BrineOptions,
    :CO2BrineSimpleOptions,
    :FieldOptions,
    :FieldConstantOptions,
    :FieldFileOptions,
    :FluidOptions,
    :WellOptions,
    :WellRateOptions,
    :WellPressureOptions,
    :TimeDependentOptions,
]
    @eval function $T(x::$T; kwargs...)
        default_kwargs = (f => getfield(x, f) for f in fieldnames($T))
        return $T(; default_kwargs..., kwargs...)
    end

    @eval function Base.hash(x::$T, h::UInt)
        hash_init = Base.hash(:ConfigurationsJutulDarcy, Base.hash(Symbol($T), h))
        h = foldl((r, f) -> Base.hash(getfield(x, f), r), fieldnames($T); init=hash_init)
        return h
    end
end
