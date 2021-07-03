module StandardizedPredictors

export
    center,
    center!,
    Center,
    CenteredTerm,
    scale,
    scale!,
    Scale,
    ScaledTerm,
    zscore,    # from StatsBase
    zscore!,   # from StatsBase
    ZScore,
    ZScoredTerm

using StatsModels
using StatsBase
using Statistics

include("utils.jl")
include("centering.jl")
include("scaling.jl")
include("zscoring.jl")

end
