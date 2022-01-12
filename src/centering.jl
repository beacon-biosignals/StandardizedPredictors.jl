"""
    center(f=mean, x, y=f(skipmissing(x)))

Center an array `x` about a scalar `y`.

See also [`center!`](@ref)
"""
center(x) = center(mean, x)
center(f::Function, x) = center(x, f(skipmissing(x)))
center(x, y) = x .- y

"""
    center!(f=mean, x, y=f(skipmissing(x)))

Center an array `x` in place about a scalar `y`.

See also [`center`](@ref)
"""
center!(x) = center!(mean, x)
center!(f::Function, x) = center!(x, f(skipmissing(x)))

function center!(x, y)
    try
        y = convert(eltype(x), y)
        # verify that we also don't hit problems during substraction
        # I can't think of any common number type that isn't closed under
        # subtraction, but maybe somebody has created a PositiveInt type
        convert(eltype(x), first(x) - y)
    catch e
        if e isa InexactError
            throw(ArgumentError("Subtracting the center $(y) changes the eltype of " *
                                "the array. Promote to $(typeof(first(x) - y)) first."))
        else
            rethrow(e)
        end
    end
    x .-= y
    return x
end

"""
    struct Center

Represents a centering scheme, akin to `StatsModels.AbstractContrasts`.  Pass as
value in `Dict` as hints to `schema` (or as `contrasts` kwarg for `fit`).

## Examples

Can specify center value to use:

```
julia> schema((x=collect(1:10), ), Dict(:x => Center(5)))
StatsModels.Schema with 1 entry:
  x => center(x, 5)
```

You can use a function to compute the center value:

julia> schema((x=collect(1:10), ), Dict(:x => Center(median)))
StatsModels.Schema with 1 entry:
  x => x(centered: 5.5)

Or [`center`](@ref) will be automatically computed if omitted:

```
julia> schema((x=collect(1:10), ), Dict(:x => Center()))
StatsModels.Schema with 1 entry:
  x => center(x, 5.5)
```
"""
struct Center
    center::Any
end

Center() = Center(nothing)

"""
    struct CenteredTerm{T,C} <: AbstractTerm

A lazily centered term.  A wrapper around an `T<:AbstractTerm` which will
produce centered values with `modelcols` by subtracting `center` from each
element generated by the wrapped term with `modelcols`.

## Fields

- `term::T`: The wrapped term.
- `center::C`: The center value subtracted from the resulting `modelcols`.

## Examples

Directly construct with given center:

```
julia> d = (x=collect(1:10), );

julia> t = concrete_term(term(:x), d)
x(continuous)

julia> tc = CenteredTerm(t, 5)
x(centered: 5)

julia> hcat(modelcols(t + tc, d)...)
10×2 Matrix{Int64}:
  1  -4
  2  -3
  3  -2
  4  -1
  5   0
  6   1
  7   2
  8   3
  9   4
 10   5
```

Construct with lazy centering via [`Center`](@ref)

```
julia> tc = concrete_term(term(:x), d, Center())
center(x, 5.5)

julia> hcat(modelcols(t + tc, d)...)
10×2 Matrix{Float64}:
  1.0  -4.5
  2.0  -3.5
  3.0  -2.5
  4.0  -1.5
  5.0  -0.5
  6.0   0.5
  7.0   1.5
  8.0   2.5
  9.0   3.5
 10.0   4.5
```

Or similarly via schema hints:

```
julia> sch = schema(d, Dict(:x => Center()))
StatsModels.Schema with 1 entry:
  x => center(x, 5.5)
```

"""
struct CenteredTerm{T,C} <: AbstractTerm
    term::T
    center::C
end

Center(xs::AbstractArray, c::Center) = Center(_standard(xs, c.center))

function StatsModels.concrete_term(t::Term, xs::AbstractArray, c::Center)
    return center(StatsModels.concrete_term(t, xs, nothing), Center(xs, c))
end

# run-time constructors:
center(t::ContinuousTerm, c::Center) = CenteredTerm(t, something(c.center, t.mean))
center(t::ContinuousTerm, c) = CenteredTerm(t, c)
center(t::ContinuousTerm) = CenteredTerm(t, t.mean)
center(t::AbstractTerm) = throw(ArgumentError("can only compute center for ContinuousTerm; must provide center value via center(t, c)"))

function center(t::AbstractTerm, c::Center)
    c.center !== nothing || throw(ArgumentError("can only compute center for ContinuousTerm; must provide center via center(t, c)"))
    return CenteredTerm(t, c.center)
end

StatsModels.modelcols(t::CenteredTerm, d::NamedTuple) = modelcols(t.term, d) .- t.center
function StatsBase.coefnames(t::CenteredTerm)
    if StatsModels.width(t.term) == 1
        return "$(coefnames(t.term))(centered: $(_round(t.center)))"
    elseif length(t.center) > 1
        return string.(vec(coefnames(t.term)), "(centered: ", _round.(vec(t.center)), ")")
    else
        return string.(coefnames(t.term), "(centered: ", _round.(t.center), ")")
    end
end
# coef table: "x(centered: 5.5)"
Base.show(io::IO, t::CenteredTerm) = print(io, "$(t.term)(centered: $(_round(t.center)))")
# regular show: "x(centered: 5.5)", used in displaying schema dicts
Base.show(io::IO, ::MIME"text/plain", t::CenteredTerm) = print(io, "$(t.term)(centered: $(_round(t.center)))")
# long show: "x(centered: 5.5)"

# statsmodels glue code:
StatsModels.width(t::CenteredTerm) = StatsModels.width(t.term)
# don't generate schema entries for terms which are already centered
StatsModels.needs_schema(::CenteredTerm) = false
StatsModels.termsyms(t::CenteredTerm) = StatsModels.termsyms(t.term)
StatsModels.termvars(t::CenteredTerm) = StatsModels.termvars(t.term)
