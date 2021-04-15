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

Let's consider a (slightly) synthetic dataset of weights for boys and girls of
different ages, with predictors `age` (continuous, from 13 to 20) and `sex`, and
`weight` in pounds.  The weights are based loosely on the medians from the [CDC
growth charts](https://www.cdc.gov/growthcharts/html_charts/wtage.htm), which
show that the median boys and girls both start off around 100 pounds at age 13,
but by age 20 the median male weights 155 pounds while the median girl weighs
around 125 pounds.

```jldoctest centering
julia> using StandardizedPredictors, DataFrames, GLM

julia> data = DataFrame(age=[13:20; 13:20], 
                        sex=repeat(["male", "female"], inner=8),
                        weight=[range(100, 155; length=8); range(100, 125; length=8)])
16×3 DataFrame
 Row │ age    sex     weight  
     │ Int64  String  Float64 
─────┼────────────────────────
   1 │    13  male    100.0
   2 │    14  male    107.857
   3 │    15  male    115.714
   4 │    16  male    123.571
   5 │    17  male    131.429
   6 │    18  male    139.286
   7 │    19  male    147.143
   8 │    20  male    155.0
   9 │    13  female  100.0
  10 │    14  female  103.571
  11 │    15  female  107.143
  12 │    16  female  110.714
  13 │    17  female  114.286
  14 │    18  female  117.857
  15 │    19  female  121.429
  16 │    20  female  125.0
```

In this dataset, there's obviously a main effect of sex: males are heavier than
females for every age except 13 years.  But if we run a basic linear regression, we
see something rather different:

```jldoctest centering
julia> lm(@formula(weight ~ 1 + sex * age), data)
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}}}}, Matrix{Float64}}

weight ~ 1 + sex + age + sex & age

Coefficients:
───────────────────────────────────────────────────────────────────────────────────────────
                     Coef.   Std. Error                   t  Pr(>|t|)  Lower 95%  Upper 95%
───────────────────────────────────────────────────────────────────────────────────────────
(Intercept)       53.5714   6.52413e-13   82112795579380.03    <1e-99   53.5714    53.5714
sex: male        -55.7143   9.22651e-13  -60385015159419.42    <1e-99  -55.7143   -55.7143
age                3.57143  3.91643e-14   91190809902610.67    <1e-99    3.57143    3.57143
sex: male & age    4.28571  5.53868e-14   77377968076840.64    <1e-99    4.28571    4.28571
───────────────────────────────────────────────────────────────────────────────────────────
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
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}}}}, Matrix{Float64}}

weight ~ 1 + sex + center(age, 16.5) + sex & center(age, 16.5)

Coefficients:
─────────────────────────────────────────────────────────────────────────────────────────────────────
                             Coef.   Std. Error                     t  Pr(>|t|)  Lower 95%  Upper 95%
─────────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)              112.5      5.80156e-15  19391345671018664.00    <1e-99  112.5      112.5
sex: male                 15.0      8.20464e-15   1828233602707956.50    <1e-99   15.0       15.0
center(age)                3.57143  2.53201e-15   1410512847055512.75    <1e-99    3.57143    3.57143
sex: male & center(age)    4.28571  3.5808e-15    1196859838924435.25    <1e-99    4.28571    4.28571
─────────────────────────────────────────────────────────────────────────────────────────────────────
```

We can also center age at a different value, like the start of our range where
the difference is essentially zero:

```jldoctest centering
julia> lm(@formula(weight ~ 1 + sex * age), data; contrasts=Dict(:age => Center(13)))
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}}}}, Matrix{Float64}}

weight ~ 1 + sex + center(age, 13) + sex & center(age, 13)

Coefficients:
───────────────────────────────────────────────────────────────────────────────────────────────────────────────
                                Coef.   Std. Error                    t  Pr(>|t|)      Lower 95%      Upper 95%
───────────────────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)              100.0         2.18363e-14  4579537167175366.00    <1e-99  100.0          100.0
sex: male                 -9.4739e-14  3.08811e-14                -3.07    0.0098   -1.62023e-13   -2.74548e-14
center(age)                3.57143     5.21987e-15   684199229964770.38    <1e-99    3.57143        3.57143
sex: male & center(age)    4.28571     7.38201e-15   580562298228847.88    <1e-99    4.28571        4.28571
───────────────────────────────────────────────────────────────────────────────────────────────────────────────
```
