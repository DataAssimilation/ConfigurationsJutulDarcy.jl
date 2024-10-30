module ImageTransformationsExt

using ConfigurationsJutulDarcy

using ImageTransformations: imresize

function ConfigurationsJutulDarcy.resize_field(grid_dims::Tuple, field)
    if ndims(field) == 2
        field = imresize(field, n[1], n[end])
    else
        field = cat(
            collect(
                reshape(imresize(field[i, :, :], n[1], n[end]), 1, n[1], n[end]) for
                i in 1:size(field, 1)
            )...;
            dims=1,
        )
    end
    return field
end

end # module
