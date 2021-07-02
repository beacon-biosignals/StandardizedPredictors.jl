using StandardizedPredictors
using StatsModels
using StatsBase
using Statistics
using Test

using StandardizedPredictors: zscore

string_mime(mime, x) = sprint(show, mime, x)

@testset "StandardizedPredictors.jl" begin
    include("centering.jl")
    include("scaling.jl")
    include("zscoring.jl")
end
