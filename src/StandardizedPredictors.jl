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
    # no explicit export -- avoid Type Piracy the FilePathsBase Way
    # zscore,
    # zscore!,
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
