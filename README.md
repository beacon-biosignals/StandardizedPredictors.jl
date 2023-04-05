# StandardizedPredictors

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://beacon-biosignals.github.io/StandardizedPredictors.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://beacon-biosignals.github.io/StandardizedPredictors.jl/dev)
[![CI](https://github.com/beacon-biosignals/StandardizedPredictors.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/beacon-biosignals/StandardizedPredictors.jl/actions)
[![Coverage](https://codecov.io/gh/beacon-biosignals/StandardizedPredictors.jl/branch/main/graph/badge.svg?token=URS2Q6BZ8T)](https://codecov.io/gh/beacon-biosignals/StandardizedPredictors.jl)

This package provides convenient and modular functionality for standardizing
regression predictors.  Standardizing predictors can increase numerical
stability of some estimation procedures when the predictors are on very
different scales or when they are non-orthogonal.  It can also produce more
interpretable regression models in the presence of interaction terms.

The [examples in the docs](https://beacon-biosignals.github.io/StandardizedPredictors.jl/stable/#Centering) demonstrate the use of StandardizedPredictors.jl with GLM.jl,
but they will work with any modeling package that is based on the [StatsModels.jl
formula](https://juliastats.org/StatsModels.jl/stable/formula/).

