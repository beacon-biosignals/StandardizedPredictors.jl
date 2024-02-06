using Aqua
using StandardizedPredictors
using StatsModels
using StatsBase
using Statistics
using Test
using TestSetExtensions

string_mime(mime, x) = sprint(show, mime, x)

@testset ExtendedTestSet "StandardizedPredictors.jl" begin
    @testset "Aqua" begin
        # technically we're pirating StatsBase.zscore(::AbstractTerm)
        Aqua.test_all(StandardizedPredictors; ambiguities=false, piracy=false)
    end
    include("centering.jl")
    include("scaling.jl")
    include("zscoring.jl")
end
