module JLD2Ext

using ConfigurationsJutulDarcy

using JLD2: load, jldopen

"""
`idx` is specified by integer `options.idx` or read from index file. 
  - Index file is at `idx`.
  - If `idx` is a vector of integers, permeability may be a batch of permeabilities.
Permeability in millidarcies is read from `file`
  - Specifically, `file[key][idx, :, :]`
  - If `idx` is `nothing`, then `file[key]`.
Permeability is resized with `imresize` to match grid dimensions.
"""
function ConfigurationsJutulDarcy.create_field(grid_dims::Tuple, options::FieldFileOptions)
    idx = if options.idx isa AbstractString
        load(options.idx, "idx")
    else
        options.idx
    end
    field = jldopen(options.file, "r") do file
        field = file[options.key]
        if !isnothing(idx)
            field = field[idx, :, :]
        end
        field = field * options.scale # Unit conversion
        return field
    end
    if options.resize && grid_dims[[1, end]] != size(field)[(end - 1):end]
        if length(methods(resize_field)) == 0
            error("Load ImageTransformations to be able to resize")
        end
        field = resize_field(grid_dims, field)
    end
    return reshape(field, :)
end


end # module
