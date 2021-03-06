"""
    struct ZScore

Represents a z-scoring scheme, akin to `StatsModels.AbstractContrasts`.  Pass as
value in `Dict` as hints to `schema` (or as `contrasts` kwarg for `fit`).

## Examples

Can specify the center and scale values to use:

```
julia> schema((x=collect(1:10), ), Dict(:x => ZScore(; center=5, scale=3)))
StatsModels.Schema with 1 entry:
  x => x(centered: 5 scaled: 3)
```

Or scale will be automatically computed if left out:

```
julia> schema((x=collect(1:10), ), Dict(:x => ZScore()))
StatsModels.Schema with 1 entry:
  x => x(centered: 5.5 scaled: 3.03)
```
"""
struct ZScore
    center::Any
    scale::Any
end

ZScore(; center=nothing, scale=nothing) = ZScore(center, scale)

function ZScore(xs::AbstractArray, zs::ZScore)
    center = _standard(xs, zs.center)
    scale = _standard(xs, zs.scale)
    return ZScore(center, scale)
end

"""
    struct ZScoredTerm{T,C,S} <: AbstractTerm

A lazily z-scored term. A wrapper around an `T<:AbstractTerm` which will
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

julia> ts = ZScoredTerm(t, 3, 5)
x(centered: 3 scaled: 5)

julia> hcat(modelcols(t + ts, d)...)
10×2 Matrix{Float64}:
  1.0  -0.4
  2.0  -0.2
  3.0   0.0
  4.0   0.2
  5.0   0.4
  6.0   0.6
  7.0   0.8
  8.0   1.0
  9.0   1.2
 10.0   1.4
```

Construct with lazy scaling via [`ZScore`](@ref)

```
julia> ts = concrete_term(term(:x), d, ZScore())
x(centered: 5.5 scaled: 3.03)

julia> hcat(modelcols(t + ts, d)...)
10×2 Matrix{Float64}:
  1.0  -1.4863
  2.0  -1.15601
  3.0  -0.825723
  4.0  -0.495434
  5.0  -0.165145
  6.0   0.165145
  7.0   0.495434
  8.0   0.825723
  9.0   1.15601
 10.0   1.4863
```

Or similarly via schema hints:

```
julia> sch = schema(d, Dict(:x => ZScore()))
StatsModels.Schema with 1 entry:
  x => x(centered: 5.5 scaled: 3.03)
```


"""
struct ZScoredTerm{T,C,S} <: AbstractTerm
    term::T
    center::C
    scale::S
end

function StatsModels.concrete_term(t::Term, xs::AbstractArray, z::ZScore)
    return zscore(StatsModels.concrete_term(t, xs, nothing), ZScore(xs, z))
end

# run-time constructors:
function StatsBase.zscore(t::ContinuousTerm, z::ZScore)
    return ZScoredTerm(t, something(z.center, t.mean), something(z.scale, sqrt(t.var)))
end
function StatsBase.zscore(t::ContinuousTerm; center=nothing, scale=nothing)
    return ZScoredTerm(t, center, scale)
end
function StatsBase.zscore(t::AbstractTerm)
    throw(ArgumentError("can only compute z-score for ContinuousTerm; must provide scale value via zscore(t; center, scale)"))
end

function StatsBase.zscore(t::AbstractTerm, z::ZScore)
    z.scale !== nothing && z.center !== nothing ||
        throw(ArgumentError("can only compute z-score for ContinuousTerm; must provide scale via zscore(t; center, scale)"))
    return ZScoredTerm(t, z.center, z.scale)
end

function StatsModels.modelcols(t::ZScoredTerm, d::NamedTuple)
    return zscore(modelcols(t.term, d), t.center, t.scale)
end

function StatsBase.coefnames(t::ZScoredTerm)
    if StatsModels.width(t.term) == 1
        return "$(coefnames(t.term))(centered: $(_round(t.center)) scaled: $(_round(t.scale)))"
    elseif length(t.scale) > 1
        return string.(vec(coefnames(t.term)), "(centered: ", _round.(vec(t.center)),
                       " scaled: ", _round.(vec(t.scale)), ")")
    else
        return string.(coefnames(t.term), "(centered: ", _round(t.center), " scaled: ",
                       _round(t.scale), ")")
    end
end
# coef table: "x(scaled: 5.5)"
function Base.show(io::IO, t::ZScoredTerm)
    return print(io, "$(t.term)(centered: $(_round(t.center)) scaled: $(_round(t.scale)))")
end
# regular show: "x(scaled: 5.5)", used in displaying schema dicts
function Base.show(io::IO, ::MIME"text/plain", t::ZScoredTerm)
    return print(io, "$(t.term)(centered: $(_round(t.center)) scaled: $(_round(t.scale)))")
end
# long show: "x(scaled: 5.5)"

# statsmodels glue code:
StatsModels.width(t::ZScoredTerm) = StatsModels.width(t.term)
# don't generate schema entries for terms which are already scaled
StatsModels.needs_schema(::ZScoredTerm) = false
StatsModels.termsyms(t::ZScoredTerm) = StatsModels.termsyms(t.term)
StatsModels.termvars(t::ZScoredTerm) = StatsModels.termvars(t.term)
