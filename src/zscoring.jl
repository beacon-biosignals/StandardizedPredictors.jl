"""
    struct ZScore

Represents a scaling scheme, akin to `StatsModels.AbstractContrasts`.  Pass as
value in `Dict` as hints to `schema` (or as `contrasts` kwarg for `fit`).

## Examples

Can specify scale value to use:

```
julia> schema((x=collect(1:10), ), Dict(:x => ZScore(5)))
StatsModels.Schema with 1 entry:
  x => zscore(x, 5)
```

Or scale will be automatically computed if left out:

```
julia> schema((x=collect(1:10), ), Dict(:x => ZScore()))
StatsModels.Schema with 1 entry:
  x => zscore(x, 5.5)
```
"""
struct ZScore
    center
    scale
end

ZScore(; center=nothing, scale=nothing) = ZScore(center, scale)

"""
    struct ZScoredTerm{T,C,S} <: AbstractTerm

A lazily z-scored term.  A wrapper around an `T<:AbstractTerm` which will
produce scaled values with `modelcols` by subtracting `center` from each
element and then dividing by `scale`.

## Fields

- `term::T`: The wrapped term.
- `center::C`: The center value which is subtracted from the resulting `modelcols`.
- `scale::S`: The scale value which the resulting `modelcols` are divided by.

## Examples

Directly construct with given scale:

```
julia> d = (x=collect(1:10), );

julia> t = concrete_term(term(:x), d)
x(continuous)

julia> ts = ScaledTerm(t, 5)
zscore(x, 5)

julia> hcat(modelcols(t + ts, d)...)
10×2 Matrix{Float64}:
  1.0  0.2
  2.0  0.4
  3.0  0.6
  4.0  0.8
  5.0  1.0
  6.0  1.2
  7.0  1.4
  8.0  1.6
  9.0  1.8
 10.0  2.0
```

Construct with lazy scaling via [`Scale`](@ref)

```
julia> ts = concrete_term(term(:x), d, ZScore())
x(scaled: 3.0277)

julia> hcat(modelcols(t + ts, d)...)
10×2 Matrix{Float64}:
  1.0  0.330289
  2.0  0.660578
  3.0  0.990867
  4.0  1.32116
  5.0  1.65145
  6.0  1.98173
  7.0  2.31202
  8.0  2.64231
  9.0  2.9726
 10.0  3.30289
```

Or similarly via schema hints:

```
julia> sch = schema(d, Dict(:x => ZScore()))
StatsModels.Schema with 1 entry:
  x => zscore(x, 3.0277)
```


"""
struct ZScoredTerm{T,C,S} <: AbstractTerm
    term::T
    center::C
    scale::S
end

StatsModels.concrete_term(t::Term, xs::AbstractArray, z::ZScore) =
    zscore(StatsModels.concrete_term(t, xs, nothing), z)
# avoid Type Privateering
# users will need to explicit import our zscore,
# but it doesn't mess up the functionality from StatsBase
zscore(args...; kwargs...) = StatsBase.zscore(args...; kwargs...)

# run-time constructors:
zscore(t::ContinuousTerm, z::ZScore) = ZScoredTerm(t, something(z.center, t.mean), something(z.scale, sqrt(t.var)))
zscore(t::ContinuousTerm; center=nothing, scale=nothing) = ZScoredTerm(t, ZScore(center, scale))
zscore(t::AbstractTerm) = throw(ArgumentError("can only compute z-score for ContinuousTerm; must provide scale value via zscore(t; center, scale)"))

function zscore(t::AbstractTerm, z::ZScore)
    z.scale !== nothing && z.center !== nothing || throw(ArgumentError("xxxcan only compute z-score for ContinuousTerm; must provide scale via zscore(t; center, scale)"))
    ZScoredTerm(t, z.center, z.scale)
end

StatsModels.modelcols(t::ZScoredTerm, d::NamedTuple) = zscore(modelcols(t.term, d), t.center, t.scale)

function StatsBase.coefnames(t::ZScoredTerm)
    if StatsModels.width(t.term) == 1
        return "$(coefnames(t.term))(centered: $(_round(t.center)) scaled: $(_round(t.scale)))"
    elseif length(t.scale) > 1
        return string.(vec(coefnames(t.term)), "(centered: ", _round.(vec(t.center)), " scaled: ", _round.(vec(t.scale)), ")")
    else
        return string.(coefnames(t.term), "(centered: ", _round(t.center), " scaled: ", _round(t.scale), ")")
    end
end
# coef table: "x(scaled: 5.5)"
Base.show(io::IO, t::ZScoredTerm) = print(io, "$(t.term)(centered: $(_round(t.center)) scaled: $(_round(t.scale)))")
# regular show: "x(scaled: 5.5)", used in displaying schema dicts
Base.show(io::IO, ::MIME"text/plain", t::ZScoredTerm) = print(io, "$(t.term)(centered: $(_round(t.center)) scaled: $(_round(t.scale)))")
# long show: "x(scaled: 5.5)"

# statsmodels glue code:
StatsModels.width(t::ZScoredTerm) = StatsModels.width(t.term)
# don't generate schema entries for terms which are already scaled
StatsModels.needs_schema(::ZScoredTerm) = false
StatsModels.termsyms(t::ZScoredTerm) = StatsModels.termsyms(t.term)
