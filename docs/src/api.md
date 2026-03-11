# API Reference

## Resolution Statistics

Precomputed data for IGEO7 grid resolutions (0–20).

```@docs
get_resolution_stats
get_num_cells
get_cell_area_m2
get_cell_area_km2
get_cls_m
get_cls_km
find_resolution_by_value
find_resolution_by_cls_m
find_resolution_by_area_m2
find_resolution_by_num_cells
```

## Indexing and Types

The core data structures and conversion utilities for Z7 cell indices.

```@docs
Z7IndexUInt64
Z7IndexComp
z7string_to_index
index_to_z7string
decode_z7hex_index
encode_z7hex_index
decode_z7int
encode_z7int
get_resolution
get_base_cell
get_digit
get_digits
get_parent
```

## Neighbor Traversal

Methods for finding adjacent cells and navigating the grid.

```@docs
get_neighbours
get_neighbour
get_base_cell_neighbours
get_base_cell_neighbour
```
