@testset "Exact literals" begin
    x = @exact 0.5
    @test (2 * x) isa Float64
    Y = interval(2) * x
    @test isguaranteed(Y)
    @test in_interval(1, Y)

    @exact function f(x)
       return x^2 - 2x + 1
    end

    Z = f(interval(1))
    @test f(1.22) isa Real
    @test isguaranteed(Z)
    @test in_interval(0, Z)

    @test_throws MethodError convert(ExactReal{Float64}, 2)

    @test has_exact_display(0.5)
    @test !has_exact_display(0.1)

    @test (@exact 2im) isa Complex{<:ExactReal}
    @test (@exact 1.2 + 3.4im) isa Complex{<:ExactReal}
    @test_throws ArgumentError (@exact 1.2 + 3im)
end
