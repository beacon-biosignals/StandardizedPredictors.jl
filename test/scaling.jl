@testset "Scaling" begin

    data = (x=collect(1:10),
            y=rand(10) .+ 3,
            z=Symbol.(repeat('a':'e', 2)))

    @testset "Automatic scaling" begin
        xc = concrete_term(term(:x), data, Scale())
        @test xc isa ScaledTerm
        @test xc.scale == std(data.x)
        @test modelcols(xc, data) == data.x ./ std(data.x) == data.x ./ xc.scale

        yc = concrete_term(term(:y), data, Scale())
        @test yc isa ScaledTerm
        @test yc.scale == std(data.y)
        @test modelcols(yc, data) == data.y ./ std(data.y) == data.y ./ yc.scale
    end

    @testset "Manual scaling" begin
        xc = concrete_term(term(:x), data, Scale(5))
        @test xc isa ScaledTerm
        @test xc.scale == 5 != std(data.x)
        @test modelcols(xc, data) == data.x ./ 5 == data.x ./ xc.scale

        yc = concrete_term(term(:y), data, Scale(5))
        @test yc isa ScaledTerm
        @test yc.scale == 5 != std(data.y)
        @test modelcols(yc, data) == data.y ./ 5 == data.y ./ yc.scale
    end

    @testset "Schema hints dict" begin
        sch = schema(data, Dict(:x => Scale(), :y => Scale(2)))
        xc = sch[term(:x)]
        @test xc isa ScaledTerm
        @test !StatsModels.needs_schema(xc)
        @test xc.scale == std(data.x)

        yc = sch[term(:y)]
        @test yc isa ScaledTerm
        @test yc.scale == 2

        @test modelcols(xc, data) == data.x ./ std(data.x)
        @test modelcols(yc, data) == data.y ./ 2
    end

    @testset "scale function" begin
        sch = schema(data)
        x = sch[term(:x)]

        xc = scale(x)
        @test xc isa ScaledTerm
        @test xc.scale == sqrt(x.var)

        xc2 = scale(x, Scale(2))
        xc22 = scale(x, 2)
        @test xc2.scale == xc22.scale == 2

        @testset "scaling vectors" begin
            x = collect(1:5) # int
            y = x * 5.0      # float
            @test scale(x) ==  x ./ std(x)
            @test scale(y) ==  y ./ std(y)
            @test scale(maximum, x) == (x ./ 5)
            @test all(scale(y, x) .== 5)

            @test scale!(copy(y)) == scale(y)
            # test mutation
            y2 = copy(y)
            scale!(y2)
            @test y2 == scale(y)

            # this is int on int so you can modify in place
            @test scale!(minimum, copy(x)) == x
            # this converts exactly to int, so you can do it in place
            @test scale!([2 4 6]) == scale([2 4 6])
            @test_throws ArgumentError scale!(std, [1, 2])
            @test_throws ArgumentError scale!([1, 2])
            @test_throws MethodError scale!(v -> 1, ["a","b"])
        end
    end

    @testset "plays nicely with formula" begin
        f = @formula(0 ~ x * y)

        sch = schema(f, data)

        sch_c = schema(f, data, Dict(:x => Scale(), :y => Scale(2)))
        ff_c = apply_schema(f, sch_c)

        mm_c = modelcols(ff_c.rhs, data)
        @test mm_c == hcat(data.x ./ std(data.x),
                           data.y ./ 2,
                           (data.x ./ std(data.x)) .* (data.y ./ 2))

        @test coefnames(ff_c.rhs) == ["x(scaled: 3.0277)", "y(scaled: 2)", "x(scaled: 3.0277) & y(scaled: 2)"]

        # round-trip schema is empty since needs_schema is false
        sch_2 = schema(ff_c, data)
        @test isempty(sch_2.schema)
    end

    @testset "printing" begin
        xc = concrete_term(term(:x), data, Scale())
        @test StatsModels.termsyms(xc) == Set([:x])
        @test "$(xc)" == "$(xc.term)"
        @test string_mime(MIME("text/plain"), xc) == "x(scaled: 3.0277)"
        @test coefnames(xc) == "x(scaled: 3.0277)"
    end

    @testset "categorical term" begin
        z = concrete_term(term(:z), data)
        @test_throws ArgumentError scale(z)
        @test_throws ArgumentError scale(z, Scale())
        zc = scale(z, Scale(0.5))
        @test modelcols(zc, data) == modelcols(z, data) ./ 0.5
        @test StatsModels.width(zc) == StatsModels.width(z)
        @test coefnames(zc) == coefnames(z) .* "(scaled: 0.5)"

        zc2 = scale(z, Scale([1 2 3 4]))
        @test string_mime(MIME("text/plain"), zc2) == "z(scaled: [1 2 3 4])"
        @test modelcols(zc2, data) == modelcols(z, data) ./ [1 2 3 4]
        @test coefnames(zc2) == coefnames(z) .* "(scaled: " .* string.([1, 2, 3, 4]) .* ")"
    end
end
