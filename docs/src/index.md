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

Let's consider a (slightly) synthetic dataset of weights for adolescents of
different ages, with predictors `age` (continuous, from 13 to 20) and `sex`, and
`weight` in pounds.  The weights are based loosely on the medians from the [CDC
growth charts](https://www.cdc.gov/growthcharts/html_charts/wtage.htm), which
show that the median male and female both start off around 100 pounds at age 13,
but by age 20 the median male weighs around 155 pounds while the median female
weighs around 125 pounds.

```jldoctest centering
julia> using StandardizedPredictors, DataFrames, StatsModels, GLM, StableRNGs

julia> rng = StableRNG(1);

julia> data = DataFrame(age=[13:20; 13:20], 
                        sex=repeat(["male", "female"], inner=8),
                        weight=[range(100, 155; length=8); range(100, 125; length=8)] .+ randn(rng, 16))
16×3 DataFrame
 Row │ age    sex     weight
     │ Int64  String  Float64
─────┼─────────────────────────
   1 │    13  male     99.4675
   2 │    14  male    107.956
   3 │    15  male    116.467
   4 │    16  male    122.728
   5 │    17  male    129.415
   6 │    18  male    139.016
   7 │    19  male    148.175
   8 │    20  male    155.676
   9 │    13  female  100.082
  10 │    14  female  103.818
  11 │    15  female  105.642
  12 │    16  female  111.043
  13 │    17  female  112.433
  14 │    18  female  117.52
  15 │    19  female  121.464
  16 │    20  female  125.232
```

In this dataset, there's obviously a main effect of sex: males are heavier than
females for every age except 13 years.  But if we run a basic linear regression, we
see something rather different:

```jldoctest centering
julia> lm(@formula(weight ~ 1 + sex * age), data)
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}, Vector{Int64}}}}, Matrix{Float64}}

weight ~ 1 + sex + age + sex & age

Coefficients:
──────────────────────────────────────────────────────────────────────────────
                     Coef.  Std. Error       t  Pr(>|t|)  Lower 95%  Upper 95%
──────────────────────────────────────────────────────────────────────────────
(Intercept)       52.9701     2.5343     20.90    <1e-10   47.4483    58.4918
sex: male        -56.9962     3.58404   -15.90    <1e-08  -64.8052   -49.1873
age                3.58693    0.152134   23.58    <1e-10    3.25545    3.9184
sex: male & age    4.37602    0.21515    20.34    <1e-09    3.90725    4.84479
──────────────────────────────────────────────────────────────────────────────
```

There is a main effect of sex but it goes in the exact opposite direction of
what we know to be true, and says that males are 55 pounds *lighter*.  The
reason is that because there's an interaction between sex and age in this model,
the main effect of sex the (extrapolated) difference in weight between sexes
when age is 0.

That's a non-sensical value, since it's far outside of our range of ages.  When
we [`Center`](@ref) age, we get something more meaningful:

```jldoctest centering
julia> lm(@formula(weight ~ 1 + sex * age), data; contrasts=Dict(:age => Center()))
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}, Vector{Int64}}}}, Matrix{Float64}}

weight ~ 1 + sex + age(centered: 16.5) + sex & age(centered: 16.5)

Coefficients:
──────────────────────────────────────────────────────────────────────────────────────────────
                                     Coef.  Std. Error       t  Pr(>|t|)  Lower 95%  Upper 95%
──────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                      112.154      0.348583  321.74    <1e-24  111.395    112.914
sex: male                         15.2081     0.492971   30.85    <1e-12   14.134     16.2822
age(centered: 16.5)                3.58693    0.152134   23.58    <1e-10    3.25545    3.9184
sex: male & age(centered: 16.5)    4.37602    0.21515    20.34    <1e-09    3.90725    4.84479
──────────────────────────────────────────────────────────────────────────────────────────────
```

We can also center age at a different value, like the start of our range where
the difference is essentially zero:

```jldoctest centering
julia> lm(@formula(weight ~ 1 + sex * age), data; contrasts=Dict(:age => Center(13)))
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}, Vector{Int64}}}}, Matrix{Float64}}

weight ~ 1 + sex + age(centered: 13) + sex & age(centered: 13)

Coefficients:
────────────────────────────────────────────────────────────────────────────────────────────
                                   Coef.  Std. Error       t  Pr(>|t|)  Lower 95%  Upper 95%
────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                    99.6001      0.636422  156.50    <1e-20   98.2134   100.987
sex: male                      -0.107954    0.900037   -0.12    0.9065   -2.06897    1.85306
age(centered: 13)               3.58693     0.152134   23.58    <1e-10    3.25545    3.9184
sex: male & age(centered: 13)   4.37602     0.21515    20.34    <1e-09    3.90725    4.84479
────────────────────────────────────────────────────────────────────────────────────────────
```
