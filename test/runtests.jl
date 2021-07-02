using StandardizedPredictors
using StatsModels
using StatsBase
using Statistics
using Test

string_mime(mime, x) = sprint(show, mime, x)

@testset "StandardizedPredictors.jl" begin
    include("centering.jl")
end
