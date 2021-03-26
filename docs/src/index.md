```@meta
CurrentModule = StandardizedPredictors
```

# StandardizedPredictors

This package provides convenient and modular functionality for standardizing
regression predictors.  Standardizing predictors can increase numerical
stability of some estimation procedures when the predictors are on very
different scales or when they are non-orthogonal.  It can also produce more
interpretable regression models in the presence of interaction terms.

The examples below demonstrate the use of StandardizedPredictors.jl with GLM.jl,
but they will work with any modeling package that is based on the [StatsModels.jl
formula](https://juliastats.org/StatsModels.jl/stable/formula/).

## Centering

Centering a predictor removes a fixed offset by subtraction.

```jldoctest

using StandardizedPredictors, DataFrames, GLM, StableRNGs

rng = StableRNG(1)

data = DataFrame()

```
