# IGEO7.jl

*Hexagonal Discrete Global Grid Indexing and Neighbor Traversal*

IGEO7.jl is a Julia implementation of the IGEO7 aperture 7 hexagonal discrete global grid (DGGRID) indexing system, known as Z7. This system utilizes the Generalized Balanced Ternary (GBT) numeral system for efficient hierarchical indexing and neighbor traversal on the icosahedral-based spherical grid.

## Core Features

- **Z7 Indexing**: Hierarchical 64-bit integer (`UInt64`) and string-based indexing for IGEO7 cells.
- **Neighbor Traversal**: Efficient computation of the 6 (or 5 for pentagons) immediate neighbors of any cell at any resolution.
- **Resolution Statistics**: Access to precomputed statistics (cell counts, areas, characteristic lengths) for resolutions 0 to 20.
- **Conversion Utilities**: Seamless conversion between hexadecimal, integer, and string representations of Z7 indices.

## Installation

```julia
using Pkg
Pkg.add("IGEO7")
```

## Quick Start

```julia
using IGEO7

# Create an index for a cell at resolution 2
idx = z7string_to_index("0123")

# Get its neighbors
nbs = get_neighbours(idx)

# Print valid neighbor strings
for nb in nbs
    if nb.raw != typemax(UInt64)
        println(index_to_z7string(nb))
    end
end
```

## Table of Contents

```@contents
Pages = ["api.md", "generated/basics.md"]
```
