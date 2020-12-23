# StaticThreadSchedules

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://xzackli.github.io/StaticThreadSchedules.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xzackli.github.io/StaticThreadSchedules.jl/dev) -->
[![Build Status](https://github.com/xzackli/StaticThreadSchedules.jl/workflows/CI/badge.svg)](https://github.com/xzackli/StaticThreadSchedules.jl/actions)
[![Coverage](https://codecov.io/gh/xzackli/StaticThreadSchedules.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/xzackli/StaticThreadSchedules.jl)

This package extends `Threads.@threads` static scheduling to handle loops with different costs per iteration.

## Usage
```julia
using StaticThreadSchedules

v = zeros(12)
# suppose this operation scales like log(i)
@threads :static (i->log(i+1)) for i in 1:12
    v[i] = Threads.threadid()
end
print(v)
```
```
[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
```

Sometimes when you're computing something expensive, you might already know how the cost of a loop scales with iteration. For example, if you're filling in the upper triangle of a matrix by iterating over the rows and columns, then the number of relevant elements in a column scales linearly.

This package exports `@threads :static [cost function]`, allowing one to specify the cost of loop iteration when passed an index. For example, computing the mode-coupling matrix used in cosmology requires ~ `ℓ^3` operations, and each iteration of the outer loop costs `ℓ^2`. Then you can write `@threads :static (ℓ->ℓ^2) for ...` to balance the cost over threads evenly.

You can also pass a function.
```julia
v = zeros(12)
cost(x) = x^3
@threads :static cost for i in 1:12
    v[i] = Threads.threadid()
end
print(v)
```
```
[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 5.0, 6.0]
```
