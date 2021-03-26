using StandardizedPredictors
using Documenter

DocMeta.setdocmeta!(StandardizedPredictors, :DocTestSetup, :(using StandardizedPredictors); recursive=true)

makedocs(;
    modules=[StandardizedPredictors],
    authors="Dave Kleinschmidt <dave.f.kleinschmidt@gmail.com> and contributors",
    repo="https://github.com/beacon-biosignals/StandardizedPredictors.jl/blob/{commit}{path}#{line}",
    sitename="StandardizedPredictors.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://beacon-biosignals.github.io/StandardizedPredictors.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kleinschmidt/StandardizedPredictors.jl",
    devbranch="main",
    push_preview=true
)
