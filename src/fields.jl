
export create_field

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

"""
`idx` is specified by integer `options.idx` or read from index file. 
  - Index file is at `idx`.
  - If `idx` is a vector of integers, permeability may be a batch of permeabilities.
Permeability in millidarcies is read from `file`
  - Specifically, `file[file_key][idx, :, :]`
Permeability is resized with `imresize` to match grid dimensions.
"""
function create_field(grid_dims::Tuple, options::FieldFileOptions)
    idx = if options.idx isa AbstractString
        load(options.idx, "idx")
    else
        options.idx
    end
    K = jldopen(options.file, "r") do file
        K = file[options.file_key][idx, :, :]
        K = K * mD_to_meters2 # Convert from millidarcy to square meters.
        return K
    end
    if options.resize && grid_dims[[1, end]] != size(field)[(end - 1):end]
        if length(methods(resize_field)) == 0
            error("Load ImageTransformations to be able to resize")
        end
        K = resize_field(grid_dims, field)
    end
    return K
end

function resize_field end
