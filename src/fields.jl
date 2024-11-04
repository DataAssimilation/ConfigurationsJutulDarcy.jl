
export create_field, resize_field


export Kto3
Kto3(Kx::AbstractArray{T}; kvoverkh::T) where T = vcat(vec(Kx)', vec(Kx)', kvoverkh * vec(Kx)')
Kto3(Kx::T; kvoverkh::T) where T = [Kx, Kx, kvoverkh * Kx]


function create_field(mesh_options::MeshOptions, options::FieldOptions)
    return create_field(mesh_options.n, options)
end

function create_field(grid_dims, options::FieldOptions)
    field = create_field(grid_dims, options.suboptions)
    return field
end

function create_field(grid_dims, options::FieldConstantOptions)
    return options.value
end

function resize_field end
