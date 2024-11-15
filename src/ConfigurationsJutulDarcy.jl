module ConfigurationsJutulDarcy

include("structs.jl")
include("fields.jl")

using PackageExtensionCompat
function __init__()
    @require_extensions
end

export HAS_NATIVE_EXTENSIONS
HAS_NATIVE_EXTENSIONS = PackageExtensionCompat.HAS_NATIVE_EXTENSIONS

if HAS_NATIVE_EXTENSIONS
    get_extension = Base.get_extension
else
    get_extension(mod, sym) = getfield(mod, sym)
end

end # module ConfigurationsJutulDarcy
