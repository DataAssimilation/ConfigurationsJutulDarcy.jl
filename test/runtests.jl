using Pkg: Pkg
using ConfigurationsJutulDarcy
using Test
using TestReports
using Aqua
using Documenter

ts = @testset ReportingTestSet "" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ConfigurationsJutulDarcy; ambiguities=false)
        Aqua.test_ambiguities(ConfigurationsJutulDarcy)
    end

    # Set metadata for doctests.
    DocMeta.setdocmeta!(
        ConfigurationsJutulDarcy,
        :DocTestSetup,
        :(using ConfigurationsJutulDarcy, Test);
        recursive=true,
    )

    # Run doctests.
    doctest(ConfigurationsJutulDarcy; manual=true)
    if ConfigurationsJutulDarcy.HAS_NATIVE_EXTENSIONS
        using JutulDarcy
        doctest(
            ConfigurationsJutulDarcy.get_extension(
                ConfigurationsJutulDarcy, :JutulDarcyExt
            );
            manual=true,
        )
        using ImageTransformations
        doctest(
            ConfigurationsJutulDarcy.get_extension(
                ConfigurationsJutulDarcy, :ImageTransformationsExt
            );
            manual=true,
        )
        using JLD2
        doctest(
            ConfigurationsJutulDarcy.get_extension(ConfigurationsJutulDarcy, :JLD2Ext);
            manual=true,
        )
    end

    # Run unit tests.
    include("test_conversion.jl")
    include("test_hash.jl")
end

outputfilename = joinpath(@__DIR__, "..", "report.xml")
open(outputfilename, "w") do fh
    print(fh, report(ts))
end
@assert any_problems(ts) == 0
