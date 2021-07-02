@testset "Z Scoring" begin

    data = (x=collect(1:10),
            y=rand(10) .+ 3,
            z=Symbol.(repeat('a':'e', 2)))

    @testset "Automatic scaling" begin
        xc = concrete_term(term(:x), data, ZScore())
        @test xc isa ZScoredTerm
        @test xc.center ≈ mean(data.x)
        @test xc.scale ≈ std(data.x)
        @test modelcols(xc, data) ≈ zscore(data.x) ≈ zscore(data.x, xc.center, xc.scale)

        yc = concrete_term(term(:y), data, ZScore())
        @test yc.center ≈ mean(data.y)
        @test yc.scale ≈ std(data.y)
        @test modelcols(yc, data) ≈ zscore(data.y) ≈ zscore(data.y, yc.center, yc.scale)
    end

    @testset "Manual scaling" begin
        xc = concrete_term(term(:x), data, ZScore(center=5))
        @test xc isa ZScoredTerm
        @test xc.center ≈ 5 != mean(data.x)
        @test xc.scale ≈ std(data.x)
        @test modelcols(xc, data) ≈ zscore(data.x, xc.center, xc.scale)

        yc = concrete_term(term(:y), data, ZScore(scale=3))
        @test yc isa ZScoredTerm
        @test yc.center ≈ mean(data.y)
        @test yc.scale == 3 != std(data.y)
        @test modelcols(yc, data) ≈ zscore(data.y, yc.center, yc.scale)

        yc = concrete_term(term(:y), data, ZScore(scale=3, center=1))
        @test yc isa ZScoredTerm
        @test yc.center ≈ 1 != mean(data.y)
        @test yc.scale == 3 != std(data.y)
        @test modelcols(yc, data) ≈ zscore(data.y, yc.center, yc.scale)
    end

    @testset "Schema hints dict" begin
        sch = schema(data, Dict(:x => ZScore(), :y => ZScore(center=2.2,scale=5)))
        xc = sch[term(:x)]
        @test xc isa ZScoredTerm
        @test !StatsModels.needs_schema(xc)
        @test xc.center == mean(data.x)
        @test xc.scale == std(data.x)

        yc = sch[term(:y)]
        @test yc isa ZScoredTerm
        @test yc.center == 2.2
        @test yc.scale == 5

        @test modelcols(xc, data) ≈ zscore(data.x)
        @test modelcols(yc, data) ≈ zscore(data.y, 2.2, 5)
    end

    @testset "zscore function" begin
        # taken care of by StatsBase 😎
    end

    @testset "plays nicely with formula" begin
        f = @formula(0 ~ x * y)

        sch = schema(f, data)

        sch_c = schema(f, data, Dict(:x => ZScore(), :y => ZScore(center=2.2,scale=5)))
        ff_c = apply_schema(f, sch_c)

        mm_c = modelcols(ff_c.rhs, data)
        @test mm_c ≈ hcat(zscore(data.x),
                          zscore(data.y, 2.2, 5),
                          zscore(data.x) .* zscore(data.y, 2.2, 5))

        @test coefnames(ff_c.rhs) ==  ["x(centered: 5.5 scaled: 3.0277)",
                                       "y(centered: 2.2 scaled: 5)",
                                       "x(centered: 5.5 scaled: 3.0277) & y(centered: 2.2 scaled: 5)"]

        # round-trip schema is empty since needs_schema is false
        sch_2 = schema(ff_c, data)
        @test isempty(sch_2.schema)
    end

    @testset "printing" begin
        xc = concrete_term(term(:x), data, ZScore())
        @test StatsModels.termsyms(xc) == Set([:x])
        @test "$(xc)" == string_mime(MIME("text/plain"), xc) == "x(centered: 5.5 scaled: 3.0277)"
        @test coefnames(xc) == "x(centered: 5.5 scaled: 3.0277)"
    end

    @testset "categorical term" begin
        z = concrete_term(term(:z), data)
        @test_throws ArgumentError zscore(z)
        @test_throws ArgumentError zscore(z, ZScore())
        zc = zscore(z, ZScore(center=0.5, scale=3))
        @test modelcols(zc, data) ≈ (modelcols(z, data) .- 0.5) ./ 3
        @test StatsModels.width(zc) == StatsModels.width(z)
        @test coefnames(zc) == coefnames(z) .* "(centered: 0.5 scaled: 3)"

        zc2 = zscore(z, ZScore(center=[1 2 3 4], scale=[5 6 7 8]))
        @test string_mime(MIME("text/plain"), zc2) == "z(centered: [1 2 3 4] scaled: [5 6 7 8])"
        @test modelcols(zc2, data) ≈ (modelcols(z, data) .- [1 2 3 4]) ./ [5 6 7 8]
        @test coefnames(zc2) == coefnames(z) .* "(centered: " .* string.([1, 2, 3, 4]) .* " scaled: " .* string.([5, 6, 7, 8]) .* ")"
    end
end
