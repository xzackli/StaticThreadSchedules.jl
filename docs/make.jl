using StaticThreadSchedules
using Documenter

makedocs(;
    modules=[StaticThreadSchedules],
    authors="Zack Li",
    repo="https://github.com/xzackli/StaticThreadSchedules.jl/blob/{commit}{path}#L{line}",
    sitename="StaticThreadSchedules.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xzackli.github.io/StaticThreadSchedules.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/xzackli/StaticThreadSchedules.jl",
)
