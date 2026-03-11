# IGEO7 - Index functions and neighbor traversal in the IGEO7/Z7 DGGS

[![Build Status](https://github.com/allixender/IGEO7.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/allixender/IGEO7.jl/actions/workflows/CI.yml?query=branch%3Amain)

This is a work-in-progress to explore the possibility of neighbor traversal in the IGEO7/Z7. Z7 is an indexing system for the IGEO7 aperture 7 hexagonal discrete global grid DGGRID/Sahr Kmoch et al. (2025). It is based on the Generalized Balanced Ternary (GBT) numeral system described in Lucas, Gibson (1982), van Roessel (1988), Sahr (2019), and Wikipedia (2025).

## Usage Example

```julia
using IGEO7

# Create an index from a string
idx = z7string_to_index("0103")

# Get resolution of the cell
res = get_resolution(idx) # returns 2

# Find all 6 neighbors
neighbors = get_neighbours(idx)
for n in neighbors
    if n.raw != typemax(UInt64)
        println(index_to_z7string(n))
    end
end
```

## Rotation Pattern

For reference purposes a rendering of three hierarchies of alternating GBT rotation is included (CW, CCW, CW).

## Acknowledgements

2019-2026 Kevin Sahr <sahrk@sou.edu> DGGRID https://github.com/sahrk/DGGRID/

https://github.com/wrenoud/Z7/

- 2025-2026 Javier Jimenez Shaw https://github.com/jjimenezshaw
- 2025-2026 Weston James Renoud https://github.com/wrenoud
