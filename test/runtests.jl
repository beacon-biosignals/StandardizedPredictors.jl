using StandardizedPredictors
using StatsModels
using StatsBase
using Statistics
using Test

function string_mime(mime, x)
    io = IOBuffer()
    show(io, mime, x)
    seekstart(io)
    return read(io, String)
end

@testset "StandardizedPredictors.jl" begin
    include("centering.jl")
end
