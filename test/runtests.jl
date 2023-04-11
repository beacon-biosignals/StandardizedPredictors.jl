using Aqua
using StandardizedPredictors
using StatsModels
using StatsBase
using Statistics
using Test

string_mime(mime, x) = sprint(show, mime, x)

@testset "StandardizedPredictors.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(StandardizedPredictors; ambiguities=false)
    end
    include("centering.jl")
    include("scaling.jl")
    include("zscoring.jl")
end
