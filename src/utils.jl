
_round(v::AbstractArray) = _round.(v)
_round(x::Integer) = x
_round(x) = round(x; digits=4)
