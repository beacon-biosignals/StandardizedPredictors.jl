"""
    scale(f=std, x, y=f(skipmissing(x)))

Scale an array `x` by a scalar `y`.


!!! warning
    This only scales and does not center the values, unlike `scale` in R.
    See `StatsBase.zscore` for that functionality.

See also [`scale!`](@ref)
"""
scale(x) = scale(std, x)
scale(f::Function, x) = scale(x, f(skipmissing(x)))
scale(x, y) = x ./ y

"""
    scale(f=std, x, y=f(skipmissing(x)))

Scale an array `x` in place by a scalar `y`.

!!! warning
    This only scales and does not center the values, unlike `scale` in R.
    See `StatsBase.zscore` for that functionality.

See also [`scale`](@ref)
"""
scale!(x) = scale!(std, x)
scale!(f::Function, x) = scale!(x, f(skipmissing(x)))

function scale!(x, y)
    try
        y = convert(eltype(x), y)
        # verify that we also don't hit problems during substraction
        # I can't think of any common number type that isn't closed under
        # subtraction, but maybe somebody has created a PositiveInt type
        convert(eltype(x), first(x) / y)
    catch e
        if e isa InexactError
            throw(ArgumentError("Dividing the scale $(y) changes the eltype of " *
                                "the array. Promote to $(typeof(first(x) - y)) first."))
        else
            rethrow(e)
        end
    end
    x ./= y
    return x
end

"""
    struct Scale

Represents a scaling scheme, akin to `StatsModels.AbstractContrasts`.  Pass as
value in `Dict` as hints to `schema` (or as `contrasts` kwarg for `fit`).

## Examples

Can specify scale value to use:

```
julia> schema((x=collect(1:10), ), Dict(:x => Scale(5)))
StatsModels.Schema with 1 entry:
  x => scale(x, 5)
```

Or scale will be automatically computed if left out:

```
julia> schema((x=collect(1:10), ), Dict(:x => Scale()))
StatsModels.Schema with 1 entry:
  x => scale(x, 5.5)
```
"""
struct Scale
    scale
end

Scale() = Scale(nothing)


"""
    struct ScaledTerm{T,S} <: AbstractTerm

A lazily scaled term.  A wrapper around an `T<:AbstractTerm` which will
produce scaled values with `modelcols` by dividing each element by `scale`.

## Fields

- `term::T`: The wrapped term.
- `scale::S`: The scale value which the resulting `modelcols` are divided by.

## Examples

Directly construct with given scale:

```
julia> d = (x=collect(1:10), );

julia> t = concrete_term(term(:x), d)
x(continuous)

julia> ts = ScaledTerm(t, 5)
scale(x, 5)

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
julia> ts = concrete_term(term(:x), d, Scale())
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
julia> sch = schema(d, Dict(:x => Scale()))
StatsModels.Schema with 1 entry:
  x => scale(x, 3.0277)
```


"""
struct ScaledTerm{T,S} <: AbstractTerm
    term::T
    scale::S
end

StatsModels.concrete_term(t::Term, xs::AbstractArray, s::Scale) =
    scale(StatsModels.concrete_term(t, xs, nothing), s)

# run-time constructors:
scale(t::ContinuousTerm, s::Scale) = ScaledTerm(t, something(s.scale, sqrt(t.var)))
scale(t::ContinuousTerm, s) = ScaledTerm(t, s)
scale(t::ContinuousTerm) = ScaledTerm(t, sqrt(t.var))
scale(t::AbstractTerm) = throw(ArgumentError("can only compute scale for ContinuousTerm; must provide scale value via scale(t, s)"))

function scale(t::AbstractTerm, s::Scale)
    s.scale !== nothing || throw(ArgumentError("can only compute scale for ContinuousTerm; must provide scale via scale(t, s)"))
    ScaledTerm(t, s.scale)
end

StatsModels.modelcols(t::ScaledTerm, d::NamedTuple) = modelcols(t.term, d) ./ t.scale

function StatsBase.coefnames(t::ScaledTerm)
    if StatsModels.width(t.term) == 1
        return "$(coefnames(t.term))(scaled: $(_round(t.scale)))"
    elseif length(t.scale) > 1
        return string.(vec(coefnames(t.term)), "(scaled: ", _round.(vec(t.scale)), ")")
    else
        return string.(coefnames(t.term), "(scaled: ", _round(t.scale), ")")
    end
end
# coef table: "x(scaled: 5.5)"
Base.show(io::IO, t::ScaledTerm) = print(io, "$(t.term)(scaled: $(_round(t.scale)))")
# regular show: "x(scaled: 5.5)", used in displaying schema dicts
Base.show(io::IO, ::MIME"text/plain", t::ScaledTerm) = print(io, "$(t.term)(scaled: $(_round(t.scale)))")
# long show: "x(scaled: 5.5)"

# statsmodels glue code:
StatsModels.width(t::ScaledTerm) = StatsModels.width(t.term)
# don't generate schema entries for terms which are already scaled
StatsModels.needs_schema(::ScaledTerm) = false
StatsModels.termsyms(t::ScaledTerm) = StatsModels.termsyms(t.term)
