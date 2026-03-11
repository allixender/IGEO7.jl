using IGEO7
using Documenter
using Literate

# Generate examples with Literate.jl
EXAMPLE_DIR = joinpath(@__DIR__, "examples")
OUTPUT_DIR = joinpath(@__DIR__, "src/generated")

# List of examples to process
examples = [
    "basics.jl"
]

for example in examples
    Literate.markdown(joinpath(EXAMPLE_DIR, example), OUTPUT_DIR; documenter=true)
end

DocMeta.setdocmeta!(IGEO7, :DocTestSetup, :(using IGEO7); recursive=true)

makedocs(;
    modules=[IGEO7],
    authors="Alexander Kmoch <alexander.kmoch@ut.ee> and contributors",
    sitename="IGEO7.jl",
    format=Documenter.HTML(;
        canonical="https://allixender.github.io/IGEO7.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Examples" => [
            "Basics" => "generated/basics.md",
        ],
        "API Reference" => "api.md",
    ],
    warnonly = [:missing_docs, :cross_references, :example_block, :docs_block],
)

deploydocs(;
    repo="github.com/allixender/IGEO7.jl",
    devbranch="main",
)
