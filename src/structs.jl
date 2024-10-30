using Configurations

export JutulOptions, MeshOptions
export SystemOptions, CO2BrineOptions, get_label
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
    file_key = nothing
    resize::Bool = false
end

@option struct FieldOptions
    name::Symbol = :field
    suboptions
end
FieldOptions(value; kwargs...) = FieldOptions(; kwargs..., suboptions=FieldConstantOptions(; value))

@option struct WellOptions
    active::Bool = true
    trajectory::Array
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
    steps::Int64
    controls::Vector
end

@option struct JutulOptions
    mesh::MeshOptions = MeshOptions()

    "number of time steps stored in one file"
    nt::Int64 = 25

    system::CO2BrineOptions = CO2BrineOptions()

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
    temperature::FieldOptions = FieldOptions(3e2)
    rock_density::FieldOptions = FieldOptions(2000.0)
    rock_heat_capacity::FieldOptions = FieldOptions(900.0)
    rock_thermal_conductivity::FieldOptions = FieldOptions(3.0)
    fluid_thermal_conductivity::FieldOptions = FieldOptions(0.6)
    component_heat_capacity::FieldOptions = FieldOptions(4184.0)

    injection::WellOptions = WellOptions(;
        trajectory=[
            1875.0 50.0 1693.75
            1875.0 50.0 1693.75+37.5
        ], name=:Injector
    )

    production::WellOptions = WellOptions(;
        active=false,
        trajectory=[
            2875.0 50.0 1693.75
            2875.0 50.0 1693.75+37.5
        ],
        name=:Producer,
    )

    time::Vector{TimeDependentOptions} = [
        TimeDependentOptions(;
            years=1.0,
            steps=10,
            controls=[
                WellRateOptions(;
                    type="injector", name=:Injector, fluid_density=5e2, rate_mtons_year=1e-3
                ),
            ],
        ),
        TimeDependentOptions(; years=1.0, steps=10, controls=[]),
    ]
end

# Define copy constructors.
for T in [
        :SystemOptions,
        :CO2BrineOptions,
        :FieldOptions,
        :FieldConstantOptions,
        :FieldFileOptions,
        :FluidOptions,
        :WellOptions,
        :WellRateOptions,
        :WellPressureOptions,
        :TimeDependentOptions
    ]
    @eval function $T(x::$T; kwargs...)
        default_kwargs = (f => getfield(x, f) for f in fieldnames($T))
        return $T(; default_kwargs..., kwargs...)
    end
end
