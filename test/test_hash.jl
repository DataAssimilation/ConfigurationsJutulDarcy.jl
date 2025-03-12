
# Tests that no struct fields are stored using pointers.
a = eval(:(JutulOptions()))
b = eval(:(JutulOptions()))
using Test
function mycompare_leaf(a, b, fs=Symbol[])
    if !is_option(a)
        println(fs)
        @test typeof(a) == typeof(b)
        @test hash(a) == hash(b)
        return nothing
    end
    T = typeof(a)
    for f in fieldnames(T)
        mycompare_leaf(getfield(a, f), getfield(b, f), vcat(fs, [f]))
    end
end
c = @testset begin
    mycompare_leaf(a, b)
end

function mycompare_all(a, b, fs=Symbol[])
    println(fs)
    @test typeof(a) == typeof(b)
    @test hash(a) == hash(b)
    if !is_option(a)
        return nothing
    end
    T = typeof(a)
    for f in fieldnames(T)
        mycompare_all(getfield(a, f), getfield(b, f), vcat(fs, [f]))
    end
end
c = @testset begin
    mycompare_all(a, b)
end
