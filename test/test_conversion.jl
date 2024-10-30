
using Test
using Configurations
using ConfigurationsJutulDarcy

@testset "Conversion to and from dictionary" begin
    opt_orig2 = JutulOptions().mesh
    T2 = typeof(opt_orig2)
    d_orig2 = to_dict(opt_orig2, YAMLStyle)
    @test (opt_conv2 = from_dict(T2, d_orig2)) skip=true

    opt_orig = JutulOptions()
    T = typeof(opt_orig)
    d_orig = to_dict(opt_orig, YAMLStyle)
    @test (opt_conv = from_dict(T, d_orig)) skip=true

    @test typeof(opt_orig) == typeof(opt_conv) skip=true
    for f in fieldnames(T)
        @test getfield(opt_orig, f) == getfield(opt_conv, f) skip=true
    end
end
