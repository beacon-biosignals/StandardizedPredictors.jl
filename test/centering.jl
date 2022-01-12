@testset "Centering" begin
    data = (x=collect(1:10),
            y=rand(10) .+ 3,
            z=Symbol.(repeat('a':'e', 2)))

    @testset "Automatic centering" begin
        xc = concrete_term(term(:x), data, Center())
        @test xc isa CenteredTerm
        @test xc.center == mean(data.x)
        @test modelcols(xc, data) == data.x .- mean(data.x) == data.x .- xc.center

        yc = concrete_term(term(:y), data, Center())
        @test yc isa CenteredTerm
        @test yc.center == mean(data.y)
        @test modelcols(yc, data) == data.y .- mean(data.y) == data.y .- yc.center

        @testset "alternative center function" begin
            f = first
            xc = concrete_term(term(:x), data, Center(f))
            @test xc isa CenteredTerm
            @test xc.center == f(data.x)
            @test modelcols(xc, data) == data.x .- f(data.x) == data.x .- xc.center
            # why test this? well this makes sure that our tests
            # wouldn't pass if we were using the default center function
            # in other words, this tests we're actually hitting a different codepath
            @test !isapprox(mean(data.x), f(data.x))
        end
    end

    @testset "Manual centering" begin
        xc = concrete_term(term(:x), data, Center(5))
        @test xc isa CenteredTerm
        @test xc.center == 5 != mean(data.x)
        @test modelcols(xc, data) == data.x .- 5 == data.x .- xc.center

        yc = concrete_term(term(:y), data, Center(5))
        @test yc isa CenteredTerm
        @test yc.center == 5 != mean(data.y)
        @test modelcols(yc, data) == data.y .- 5 == data.y .- yc.center
    end

    @testset "Schema hints dict" begin
        sch = schema(data, Dict(:x => Center(), :y => Center(2)))
        xc = sch[term(:x)]
        @test xc isa CenteredTerm
        @test !StatsModels.needs_schema(xc)
        @test xc.center == mean(data.x)

        yc = sch[term(:y)]
        @test yc isa CenteredTerm
        @test yc.center == 2

        @test modelcols(xc, data) == data.x .- mean(data.x)
        @test modelcols(yc, data) == data.y .- 2
    end

    @testset "center function" begin
        sch = schema(data)
        x = sch[term(:x)]

        xc = center(x)
        @test xc isa CenteredTerm
        @test xc.center == x.mean

        xc2 = center(x, Center(2))
        xc22 = center(x, 2)
        @test xc2.center == xc22.center == 2

        @testset "centering vectors" begin
            x = collect(1:5)
            y = x .+ 5.0
            xc = x .- 3

            @test center(x) == xc
            @test center(y) == xc
            @test center(maximum, x) == (x .- 5)
            @test all(center(y, x) .== 5)

            y2 = copy(y)
            @test center!(y2) == xc
            @test all(y2 .!= y)
            @test y2 == xc

            # this is int on int so you can modify in place
            @test center!(maximum, copy(x)) == (x .- 5)
            # this converts exactly to int, so you can do it in place
            center!(mean, copy(x)) == center(mean, x)
            @test_throws ArgumentError center!(mean, [1, 2])
            @test_throws ArgumentError center!([1, 2])
            @test_throws MethodError center!(v -> 1, ["a", "b"])
        end
    end

    @testset "plays nicely with formula" begin
        f = @formula(0 ~ x * y)

        sch = schema(f, data)

        sch_c = schema(f, data, Dict(:x => Center(), :y => Center(2)))
        ff_c = apply_schema(f, sch_c)

        mm_c = modelcols(ff_c.rhs, data)
        @test mm_c == hcat(data.x .- mean(data.x),
                           data.y .- 2,
                           (data.x .- mean(data.x)) .* (data.y .- 2))

        @test coefnames(ff_c.rhs) ==
              ["x(centered: 5.5)", "y(centered: 2)", "x(centered: 5.5) & y(centered: 2)"]

        # round-trip schema is empty since needs_schema is false
        sch_2 = schema(ff_c, data)
        @test isempty(sch_2.schema)

        @testset "missing omit" begin
            d = (x=[1, 2, missing, 3], y=[1, missing, 2, 3], z=[missing, 1, 2, 3])
            dd, nonmissing = StatsModels.missing_omit(d, ff_c)
            @test findall(nonmissing) == [1, 4]
            @test dd.x == d.x[nonmissing]
            @test dd.y == d.y[nonmissing]
        end
    end

    @testset "printing" begin
        xc = concrete_term(term(:x), data, Center())
        @test StatsModels.termsyms(xc) == Set([:x])
        @test "$(xc)" == string_mime(MIME("text/plain"), xc) == "x(centered: 5.5)"
        @test coefnames(xc) == "x(centered: 5.5)"
    end

    @testset "categorical term" begin
        z = concrete_term(term(:z), data)
        @test_throws ArgumentError center(z)
        @test_throws ArgumentError center(z, Center())
        zc = center(z, Center(0.5))
        @test modelcols(zc, data) == modelcols(z, data) .- 0.5
        @test StatsModels.width(zc) == StatsModels.width(z)
        @test coefnames(zc) == coefnames(z) .* "(centered: 0.5)"

        zc2 = center(z, Center([1 2 3 4]))
        @test modelcols(zc2, data) == modelcols(z, data) .- [1 2 3 4]
        @test coefnames(zc2) ==
              coefnames(z) .* "(centered: " .* string.([1, 2, 3, 4]) .* ")"
    end

    # @testset "utilities" begin

    # end

end
