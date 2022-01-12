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

"""
    _standard(xs::AbstractArray, val)

Translate an abstract standardization value to a concrete one based on `xs`.

`nothing` and already concrete `Number` `val`s are passed through.
Otherwise, `val(xs)` is returned.
"""
_standard(::AbstractArray, t::Number) = t
_standard(::AbstractArray, ::Nothing) = nothing
_standard(xs::AbstractArray, t) = t(xs)

include("utils.jl")
include("centering.jl")
include("scaling.jl")
include("zscoring.jl")

end
