```@meta
EditURL = "../../examples/basics.jl"
```

# Basics of IGEO7.jl

This tutorial introduces the basic concepts of the IGEO7 grid indexing system (Z7)
and how to use the `IGEO7.jl` package for indexing and neighbor traversal.

````@example basics
using IGEO7
````

## Understanding Z7 Indices

Z7 indices represent cells in the IGEO7 hexagonal discrete global grid.
There are two primary internal representations:

1. `Z7IndexUInt64`: A lightweight wrapper around a `UInt64` (most memory efficient).
2. `Z7IndexComp`: Decodes the digits once upon construction (faster for multiple accesses).

You can create an index from a string:

````@example basics
idx_str = "0103"
idx = z7string_to_index(idx_str)
````

We can inspect its properties:

````@example basics
println("Base Cell: ", get_base_cell(idx))
println("Resolution: ", get_resolution(idx))
println("Digits: ", get_digits(idx)[1:get_resolution(idx)])
````

## Neighbor Traversal

Finding the immediate neighbors of a cell is the primary feature of this package.
For most hexagonal cells, there are 6 neighbors. However, at the 12 vertices
of the icosahedron (the "base cells"), the grid contains pentagonal cells,
which only have 5 neighbors.

````@example basics
neighbors = get_neighbours(idx)

println("Neighbors of ", idx_str, ":")
for (i, n) in enumerate(neighbors)
    if n.raw != typemax(UInt64)
        println("  Direction ", i, ": ", index_to_z7string(n))
    else
        println("  Direction ", i, ": (Invalid/Pentagon Gap)")
    end
end
````

## Hierarchy and Parents

The IGEO7 grid is hierarchical. Every cell (except for resolution 0) has a parent cell
that contains it at the previous resolution.

````@example basics
parent_idx = get_parent(idx)
println("Parent of ", idx_str, ": ", index_to_z7string(parent_idx))
````

## Resolution Statistics

You can also look up precomputed statistics for any resolution level (0 to 20):

````@example basics
res = 10
stats = get_resolution_stats(res)

println("Resolution ", res, " Stats:")
println("  Total Cells: ", stats.num_cells)
println("  Cell Area:   ", stats.area_km2, " km²")
println("  Length:      ", stats.cls_km, " km")
````

You can also search for the best resolution for your target requirements:

````@example basics
target_len = 100.0 # meters
found_res = find_resolution_by_cls_m(target_len, prefer=:closest)
println("Resolution closest to ", target_len, "m is: ", found_res)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

