module StandardizedPredictors

export
    center,
    center!,
    Center,
    CenteredTerm,
    scale,
    scale!,
    Scale,
    ScaledTerm

using StatsModels
using StatsBase
using Statistics

include("centering.jl")
include("scaling.jl")

end
