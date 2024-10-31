
export create_field, resize_field

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
