module Z7

using StaticArrays

# more import intended use functions, e.g. sort of core API
export Z7IndexUInt64, get_base_cell, get_digits, get_digit, get_resolution, get_parent, index_to_z7string, z7string_to_index
export get_base_cell_neighbour, get_base_cell_neighbours, get_neighbours

# convenience functions for resolution lookup based on target metrics
export find_resolution_by_cls_m, find_resolution_by_area_m2, find_resolution_by_num_cells, get_resolution_stats, RESOLUTION_STATS, find_resolution_by_value, get_num_cells, get_cell_area_m2, get_cell_area_km2, get_cls_m, get_cls_km
export get_z7hex_resolution, get_z7hex_local_pos, get_z7string_resolution, get_z7string_local_pos, decode_z7hex_index, encode_z7hex_index, z7hex_to_z7string, z7hex_to_z7int, z7int_to_z7hex, decode_z7int, encode_z7int

# some experimental functions
export Z7IndexComp, get_neighbour, Z7Carry


"""
IGEO7 approximat resolution statistics

Precomputed statistics for each resolution level (0-20).
"""
const RESOLUTION_STATS = Dict{Int, NamedTuple{(:num_cells, :area_km2, :area_m2, :cls_km, :cls_m), Tuple{Int, Float64, Float64, Float64, Float64}}}(
    0 => (num_cells = 12, area_km2 = 51006562.1724089, area_m2 = 51006562172408.9, cls_km = 8199.5003701, cls_m = 8199500.3701),
    1 => (num_cells = 72, area_km2 = 7286651.7389156, area_m2 = 7286651738915.6, cls_km = 3053.2232428, cls_m = 3053223.2428),
    2 => (num_cells = 492, area_km2 = 1040950.2484165, area_m2 = 1040950248416.5, cls_km = 1151.6430095, cls_m = 1151643.0095),
    3 => (num_cells = 3432, area_km2 = 148707.1783452, area_m2 = 148707178345.2, cls_km = 435.1531492, cls_m = 435153.1492),
    4 => (num_cells = 24012, area_km2 = 21243.8826207, area_m2 = 21243882620.7, cls_km = 164.4655799, cls_m = 164465.5799),
    5 => (num_cells = 168072, area_km2 = 3034.8403744, area_m2 = 3034840374.4, cls_km = 62.1617764, cls_m = 62161.7764),
    6 => (num_cells = 1176492, area_km2 = 433.5486249, area_m2 = 433548624.9, cls_km = 23.4949231, cls_m = 23494.9231),
    7 => (num_cells = 8235432, area_km2 = 61.9355178, area_m2 = 61935517.8, cls_km = 8.8802451, cls_m = 8880.2451),
    8 => (num_cells = 57648012, area_km2 = 8.8479311, area_m2 = 8847931.1, cls_km = 3.3564171, cls_m = 3356.4171),
    9 => (num_cells = 403536072, area_km2 = 1.2639902, area_m2 = 1263990.2, cls_km = 1.2686064, cls_m = 1268.6064),
    10 => (num_cells = 2824752492, area_km2 = 0.1805700, area_m2 = 180570.0, cls_km = 0.4794882, cls_m = 479.4882),
    11 => (num_cells = 19773267432, area_km2 = 0.0257957, area_m2 = 25795.7, cls_km = 0.1812295, cls_m = 181.2295),
    12 => (num_cells = 138412872012, area_km2 = 0.0036851, area_m2 = 3685.1, cls_km = 0.0684983, cls_m = 68.4983),
    13 => (num_cells = 968890104072, area_km2 = 0.0005264, area_m2 = 526.4, cls_km = 0.0258899, cls_m = 25.8899),
    14 => (num_cells = 6782230728492, area_km2 = 0.0000752, area_m2 = 75.2, cls_km = 0.0097855, cls_m = 9.7855),
    15 => (num_cells = 47475615099432, area_km2 = 0.0000107, area_m2 = 10.7, cls_km = 0.0036986, cls_m = 3.6986),
    16 => (num_cells = 332329305696012, area_km2 = 0.0000015, area_m2 = 1.5, cls_km = 0.0013979, cls_m = 1.3979),
    17 => (num_cells = 2326305139872072, area_km2 = 0.0000002, area_m2 = 0.2, cls_km = 0.0005284, cls_m = 0.5284),
    18 => (num_cells = 16284135979104492, area_km2 = 0.0000000, area_m2 = 0.0, cls_km = 0.0001997, cls_m = 0.1997),
    19 => (num_cells = 113988951853731432, area_km2 = 0.0000000, area_m2 = 0.0, cls_km = 0.0000755, cls_m = 0.0755),
    20 => (num_cells = 797922662976120012, area_km2 = 0.0000000, area_m2 = 0.0, cls_km = 0.0000285, cls_m = 0.0285)
)

function get_resolution_stats(resolution::Int)
	haskey(RESOLUTION_STATS, resolution) || throw(ArgumentError("Resolution must be 0-20, got $resolution"))
	return RESOLUTION_STATS[resolution]
end

get_num_cells(resolution::Int) = get_resolution_stats(resolution).num_cells
get_cell_area_m2(resolution::Int) = get_resolution_stats(resolution).area_m2
get_cell_area_km2(resolution::Int) = get_resolution_stats(resolution).area_km2
get_cls_m(resolution::Int) = get_resolution_stats(resolution).cls_m
get_cls_km(resolution::Int) = get_resolution_stats(resolution).cls_km

function find_resolution_by_value(target::Real, metric::Symbol; prefer::Symbol=:closest)
    # Validate metric
    valid_metrics = (:num_cells, :area_km2, :area_m2, :cls_km, :cls_m)
    metric in valid_metrics || throw(ArgumentError("Metric must be one of $valid_metrics"))
    
    # Validate prefer strategy
    prefer in (:closest, :larger, :smaller) || throw(ArgumentError("prefer must be :closest, :larger, or :smaller"))
    
    best_res = nothing
    best_diff = Inf
    
    for res in 0:20
        value = getfield(RESOLUTION_STATS[res], metric)
        
        if prefer == :closest
            diff = abs(value - target)
            if diff < best_diff
                best_diff = diff
                best_res = res
            end
            
        elseif prefer == :larger
            # Find smallest value >= target
            if value >= target
                diff = value - target
                if diff < best_diff
                    best_diff = diff
                    best_res = res
                end
            end
            
        else  # prefer == :smaller
            # Find largest value <= target
            if value <= target
                diff = target - value
                if diff < best_diff
                    best_diff = diff
                    best_res = res
                end
            end
        end
    end
    
    return best_res
end

function find_resolution_by_cls_m(target_m::Real; prefer::Symbol=:closest)
    return find_resolution_by_value(target_m, :cls_m, prefer=prefer)
end

function find_resolution_by_area_m2(target_m2::Real; prefer::Symbol=:closest)
    return find_resolution_by_value(target_m2, :area_m2, prefer=prefer)
end

function find_resolution_by_num_cells(target_cells::Integer; prefer::Symbol=:closest)
    return find_resolution_by_value(target_cells, :num_cells, prefer=prefer)
end

## Some IGEO7 functions

### Z7_hex-based

function decode_z7hex_index(z7_hex_str::String)
    """
    Decode a Z7 hexadecimal index (provided as hex string).
    
    Format:
    - First 4 bits: base cell number (0-11)
    - Remaining 60 bits: 20 groups of 3 bits each for resolution digits (0-6, 7 for beyond resolution)
    
    Args:
        z7_hex_str: Hexadecimal string representing the Z7 cell index
        
    Returns:
        Tuple: (base_cell, resolution_digits)
            - base_cell: integer 0-11
            - resolution_digits: vector of integers (0-6 or 7), with 7 indicating beyond resolution
    """
    # Convert hex to integer, then to binary string with full 64 bits
    value = parse(UInt64, z7_hex_str, base=16)
    binary = bitstring(value)  # Returns 64-bit binary string
    
    # Extract base cell (first 4 bits)
    base_cell = parse(Int, binary[1:4], base=2)
    
    # Extract resolution digits (20 groups of 3 bits each)
    resolution_digits = Int8[]
    for i in 0:19  # 60 remaining bits = 20 groups of 3 bits
        start = 5 + (i * 3)  # Start after the first 4 bits (Julia is 1-indexed)
        digit = parse(Int, binary[start:start+2], base=2)
        push!(resolution_digits, digit)
    end
    
    return base_cell, resolution_digits
end

function z7hex_to_z7string(z7_hex_str::String)
    """
    Get the Z7 string representation of a Z7 hexadecimal representation.

    Args:
        z7_hex_str: Z7 hexadecimal string representation of the cell index
    """
    base_cell, resolution_digits = decode_z7hex_index(z7_hex_str)
    str_rep = [lpad(string(base_cell), 2, '0')]
    for digit in resolution_digits
        status = digit != 7
        if status
            push!(str_rep, string(digit))
        end
    end
    return join(str_rep, "")
end

function z7hex_to_z7int(z7_hex_str::String)
    # From hex string to integer
    value = parse(UInt64, z7_hex_str, base=16)
    return value
end

function get_z7hex_resolution(z7_hex_str::String)
    """
    Get the resolution of a Z7 cell.

    Args:
        z7_hex_str: Z7 hexadecimal string representation of the cell index
    """
    base_cell, resolution_digits = decode_z7hex_index(z7_hex_str)
    return length(filter(x -> x >= 0 && x < 7, resolution_digits))
end

function get_z7hex_local_pos(z7_hex_str::String)
    """
    Get the local position of a cell within its parent cell.

    Args:
        z7_hex_str: Z7 hexadecimal string representation of the cell index
    """
    z7_string = z7hex_to_z7string(z7_hex_str)
    parent = z7_string[1:end-1]
    local_pos = z7_string[end:end]
    is_center = local_pos == "0"
    return (parent, local_pos, is_center)
end

function encode_z7hex_index(base_cell::Int, resolution_digits::Vector{Int8})
    """
    Encode a Z7 hexadecimal index from base cell and resolution digits.
    
    Format:
    - First 4 bits: base cell number (0-11)
    - Remaining 60 bits: 20 groups of 3 bits each for resolution digits (0-6, 7 for beyond resolution)
    
    Args:
        base_cell: Integer 0-11
        resolution_digits: Vector of integers (0-6 or 7), up to 20 digits
        
    Returns:
        Hexadecimal string representing the Z7 cell index
    """
    # Start with base cell in binary (4 bits)
    binary = string(base_cell, base=2, pad=4)
    
    # Pad resolution_digits to 20 elements if needed (using 7 for beyond resolution)
    padded_digits = vcat(resolution_digits[1:min(length(resolution_digits), 20)], 
                         fill(7, max(0, 20 - length(resolution_digits))))
    
    # Add each resolution digit as 3 bits
    for digit in padded_digits
        binary *= string(digit, base=2, pad=3)
    end
    
    # Convert binary string to integer, then to hex
    hex_value = string(parse(UInt64, binary, base=2), base=16, pad=16)
    
    return lowercase(hex_value)
end


### Z7_Int64-based

function z7int_to_z7hex(z7_int::Integer)
    # From integer back to hex string, maintaining 16 characters (64 bits)
    hex_back = string(z7_int, base=16, pad=16)
    return hex_back
end

function z7int_to_z7hex(idx::UInt64)::String
    string(idx, base=16, pad=16)
end

# Direct bit manipulation for decoding (faster than string operations)
function decode_z7int(idx::UInt64)
    base_cell = (idx >> 60) & 0x0F  # Extract top 4 bits
    resolution_digits = [(idx >> (57 - 3i)) & 0x07 for i in 0:19]
    return base_cell, resolution_digits
end

# Original optimized version
function encode_z7int(base_cell::UInt8, resolution_digits::Vector{UInt8})::UInt64
    result = UInt64(base_cell) << 60
    n = min(length(resolution_digits), 20)
    for i in 1:n
        result |= UInt64(resolution_digits[i]) << (57 - 3(i-1))
    end
    # Fill remaining with 7s
    for i in (n+1):20
        result |= UInt64(7) << (57 - 3(i-1))
    end
    return result
end

# Generic fallback with conversion
@inline function encode_z7int(base_cell::Integer, resolution_digits::AbstractVector{<:Integer})::UInt64
    encode_z7int(
        convert(UInt8, base_cell),
        convert(Vector{UInt8}, resolution_digits)
    )
end

function get_z7string_resolution(z7_string::String)
    """
    Get the resolution of a Z7 cell from its Z7_STRING representation.

    Args:
        z7_string: Z7_STRING representation of the cell index
    """
    return length(z7_string) - 2
end

function get_z7string_local_pos(z7_string::String)
    """
    Get the local position of a cell within its parent cell.

    Args:
        z7_string: Z7 string representation of the cell index
    """
    parent = z7_string[1:end-1]
    local_pos = z7_string[end:end]
    is_center = local_pos == "0"
    return (parent, local_pos, is_center)
end

## Alternative Z7Index representations for performance comparison
# readability, usability vs speed trade-offs

# Store only UInt64, extract digits via bit manipulation
struct Z7IndexUInt64
    raw::UInt64
end

@inline get_base_cell(idx::Z7IndexUInt64) = UInt8((idx.raw >> 60) & 0x0F)

# Very fast bit extraction (2-3 CPU cycles)
@inline function get_digit(idx::Z7IndexUInt64, i::Int)
    shift = 57 - 3 * (i - 1)  # i is 1-indexed
    return UInt8((idx.raw >> shift) & 0x07)
end

# For multiple digit access, decode to tuple
@inline function get_digits(idx::Z7IndexUInt64)
    ntuple(i -> get_digit(idx, i), Val(20))
end

function get_resolution(idx::Z7IndexUInt64)
    for i in 1:20
        get_digit(idx, i) == 7 && return i - 1
    end
    return 20
end

function get_parent(idx::Z7IndexUInt64, resolution::Int)
    resolution = clamp(resolution, 0, 20)
    
    # Keep base cell and first 'resolution' digits, set rest to 7
    mask = UInt64(0xF) << 60  # Base cell mask
    
    for i in 1:resolution
        shift = 57 - 3(i-1)
        mask |= UInt64(0x7) << shift
    end
    
    # Clear digits beyond resolution
    result = idx.raw & mask
    
    # Set remaining digits to 7
    for i in (resolution+1):20
        shift = 57 - 3(i-1)
        result |= UInt64(7) << shift
    end
    
    return Z7IndexUInt64(result)
end

function get_parent(idx::Z7IndexUInt64)
    res = get_resolution(idx)
    return res > 0 ? get_parent(idx, res - 1) : idx
end


# Store as UInt64, but decode once and cache the digits
struct Z7IndexComp
    raw::UInt64
    base_cell::UInt8
    digits::SVector{20, UInt8}  # StaticArrays for stack allocation
end

# Decode once on construction
function Z7IndexComp(raw::UInt64)
    base_cell = UInt8((raw >> 60) & 0x0F)
    digits = SVector{20, UInt8}(
        UInt8((raw >> (57 - 3i)) & 0x07) for i in 0:19
    )
    Z7IndexComp(raw, base_cell, digits)
end

@inline get_base_cell(idx::Z7IndexComp) = idx.base_cell

@inline get_digits(idx::Z7IndexComp) = idx.digits
    
# Fast digit access: O(1) with no computation
@inline get_digit(idx::Z7IndexComp, i::Int) = idx.digits[i]

function get_resolution(idx::Z7IndexComp)
    for i in 1:20
        idx.digits[i] == 7 && return i - 1
    end
    return 20
end

function get_parent(idx::Z7IndexComp, resolution::Int)
    resolution = clamp(resolution, 0, 20)
    
    # Create new digits array with 7s beyond resolution
    new_digits = MVector{20, UInt8}(idx.digits)
    for i in (resolution+1):20
        new_digits[i] = 0x07
    end
    
    # Reconstruct the raw UInt64
    result = UInt64(idx.base_cell) << 60
    for i in 1:20
        result |= UInt64(new_digits[i]) << (57 - 3(i-1))
    end
    
    return Z7IndexComp(result)
end

function get_parent(idx::Z7IndexComp)
    res = get_resolution(idx)
    return res > 0 ? get_parent(idx, res - 1) : idx
end

"""
Base cell adjacency for the 12 pentagonal base cells on the icosahedron vertices.
Each base cell has 5 neighbours (pentagons have 5 edges).
The neighbours are listed in space-filling curve order (the k=1 poking direction is start).

listed with 6 neighbours, where accordingly in pentagons one needs to be excluded: EXCLUDE_NEIGHBOURS

see also: cpp_source/library.h
"""
const BASE_CELL_NEIGHBOURS = [
    # Base cell 00, in CCW
    [5, 4, 4, 2, 1, 3],  
    
    # Base cell 01
    [5, 0, 0, 6, 10, 2],
    
    # Base cell 02
    [1, 0, 0, 7, 6, 3],
    
    # Base cell 03
    [2, 0, 0, 8, 7, 4],
    
    # Base cell 04
    [3, 0, 0, 9, 8, 5],
    
    # Base cell 05
    [4, 0, 0, 10, 9, 1],
    
    # Base cell 06
    [10, 2, 1, 11, 11, 7],
    
    # Base cell 07
    [6, 3, 2, 11, 11, 8],
    
    # Base cell 08
    [7, 4, 3, 11, 11, 9],
    
    # Base cell 09
    [8, 5, 4, 11, 11, 10],
    
    # Base cell 10
    [9, 1, 5, 11, 11, 6],
    
    # Base cell 11
    [9, 6, 10, 8, 8, 7]
]


"""
Pentagons have only 5 neighbours, the centre is still the "0", but the outer siblings skip one of the index numbers (hint, often, but not always the "2")

Default ZORDER centre 0, then 1, 3, 2, 6, 4, 5; where 1+6, 3+4; and 2+5; are opposites (hahaha, sum=7) 
"""
const EXCLUDE_NEIGHBOURS = @SVector UInt8[
    # Base cell 00
	2,
    # Base cell 01
    2,
    # Base cell 02
    2,
    # Base cell 03
    2,
    # Base cell 04
    2,
    # Base cell 05
    2,
    # Base cell 06
    5,
    # Base cell 07
    5,
    # Base cell 08
    5,
    # Base cell 09
    5,
    # Base cell 10
    5,
    # Base cell 11
    5
]


"""
Get the neighbouring base cells for a given base cell.
Returns a vector of base cell IDs (0-11).
Pentagons have only 5 neighbours.
"""
function get_base_cell_neighbours(base_cell::UInt8)
    base_cell > 11 && throw(ArgumentError("Base cell must be 0-11"))
	# +1 for 1-based indexing
    arr = BASE_CELL_NEIGHBOURS[base_cell + 1]
	index = EXCLUDE_NEIGHBOURS[base_cell+1]
	return [arr[1:index-1]; arr[index+1:end]]
end

"""
Get the neighbour base cell in a specific direction (0-4 for pentagons).
Returns nothing if direction is invalid (≥5 for pentagons).

We could also instead of limiting at 5 use the now filled directions
"""
function get_base_cell_neighbour(base_cell::UInt8, direction::Int)
    base_cell > 11 && throw(ArgumentError("Base cell must be 0-11"))
    
	arr = BASE_CELL_NEIGHBOURS[base_cell + 1]
	index = EXCLUDE_NEIGHBOURS[base_cell+1]
	neighbours = [arr[1:index-1]; arr[index+1:end]]
    
    if direction < 0 || direction >= 5
        return nothing  # Pentagons only have 5 neighbours (directions 0-4)
    end
    
    return UInt8(neighbours[direction + 1])  # +1 for 1-based indexing
end

function get_base_cell_neighbour(idx::Union{Z7IndexUInt64, Z7IndexComp}, direction::Int)
	base_cell = get_base_cell(idx)
    base_cell > 11 && throw(ArgumentError("Base cell must be 0-11"))
    
    arr = BASE_CELL_NEIGHBOURS[base_cell + 1]
	index = EXCLUDE_NEIGHBOURS[base_cell+1]
	neighbours = [arr[1:index-1]; arr[index+1:end]]
    
    if direction < 0 || direction >= 5
        return nothing  # Pentagons only have 5 neighbours (directions 0-4)
    end
    
    return UInt8(neighbours[direction + 1])  # +1 for 1-based indexing
end

function get_base_cell_neighbours(idx::Union{Z7IndexUInt64, Z7IndexComp})
    res = get_resolution(idx)
    res != 0 && throw(ArgumentError("This function is for base cells only (resolution 0)"))
    
    base_cell = get_base_cell(idx)
    neighbour_bases = get_base_cell_neighbours(base_cell)
    
    # return [Z7Index(UInt8(nb), UInt8[]) for nb in neighbour_bases]
	return neighbour_bases
end


### IGEO7 GBT tests

"Rotations array for each base cell (0-11)"
const ROTATIONS = @SVector UInt8[0, 5, 0, 1, 3, 4, 5, 4, 3, 1, 0, 0]

"""
Pole 0 rotations: multiply by 5 that number of times, 
based on origin and index1 of result in pole 0
6x6 matrix indexed as [origin+1, index+1] (Julia is 1-indexed)
"""
const POLE_0_ROTATIONS = @SMatrix UInt8[
    0 1 0 1 0 2;
    0 0 0 0 0 0;
    0 0 0 3 2 2;
    5 5 0 0 0 0;
    0 1 0 0 0 0;
    5 0 4 0 4 0
]

# GBT Addition Tables to get to the next neighbour in order (first element is itself)
const GBT_CW_0 = @SMatrix UInt8[
    0 1 2 3 4 5 6;
    1 4 3 6 5 2 0;
    2 3 1 4 6 0 5;
    3 6 4 5 0 1 2;
    4 5 6 0 2 3 1;
    5 2 0 1 3 6 4;
    6 0 5 2 1 4 3
]

# ╔═╡ 4f702dfa-7e70-4615-8392-4bb38c2a67d7
const GBT_CW_1 = @SMatrix UInt8[
    0 0 0 0 0 0 0;
    0 1 0 1 0 5 0;
    0 0 2 3 0 0 2;
    0 1 3 3 0 0 0;
    0 0 0 0 4 4 6;
    0 5 0 0 4 5 0;
    0 0 2 0 6 0 6
]

# ╔═╡ 46c53546-8c79-43ca-beb6-1372e10822ea
function neighbour_addition_cw(a::UInt8, b::UInt8)
    return (GBT_CW_1[a+1, b+1], GBT_CW_0[a+1, b+1])
end

# ╔═╡ ec806f4e-68b0-4078-80f6-88de21931669
const GBT_CCW_0 = @SMatrix UInt8[
    0 1 2 3 4 5 6;
    1 2 3 4 5 6 0;
    2 3 4 5 6 0 1;
    3 4 5 6 0 1 2;
    4 5 6 0 1 2 3;
    5 6 0 1 2 3 4;
    6 0 1 2 3 4 5
]


"""
This could potentially be expressed as mod 7:

Instead of 2D array, we can just use mod 7 addition. So where we had `addition_table_0[a][b]`, we can instead do `mod_7_table[a + b]`.
"""
const MOD_7_TABLE = @SVector UInt8[0, 1, 2, 3, 4, 5, 6, 0, 1, 2, 3, 4, 5, 6]

const GBT_CCW_1 = @SMatrix UInt8[
    0 0 0 0 0 0 0;
    0 1 0 3 0 1 0;
    0 0 2 2 0 0 6;
    0 3 2 3 0 0 0;
    0 0 0 0 4 5 4;
    0 1 0 0 5 5 0;
    0 0 6 0 4 0 6
]

function neighbour_addition_ccw(a::UInt8, b::UInt8)
    return (GBT_CCW_1[a+1, b+1], GBT_CCW_0[a+1, b+1])
end

# addition_table_1[a][b], mod_7_table[a + b]
function neighbour_addition_ccw_mod(a::UInt8, b::UInt8)
    return (GBT_CCW_1[a+1, b+1], MOD_7_TABLE[a + b + 1])
end

## GBT neighbour Functions

"""
Helper struct to track carry when computing neighbours across base cell boundaries.
"""
struct Z7Carry
    idx::Z7IndexUInt64
    carry::UInt8
end

"""
Compute a single neighbour in direction N (1-6) at a given resolution.
This is an optimized version for a known direction digit.

Returns a Z7Carry struct containing the neighbour index and any carry value.
If carry != 0, the neighbour crosses a base cell boundary.
"""
function get_neighbour(ref::Z7IndexUInt64, direction::UInt8, resolution::Int)
    @assert 1 <= direction <= 6 "Direction must be 1-6"
    @assert 1 <= resolution <= 20 "Resolution must be 1-20"
    
    # Start with a copy of the reference index
    result = ref.raw
    carry = UInt8(0)
    
    # Add the direction digit at the specified resolution
    v = get_digit(ref, resolution)
    is_even = (resolution % 2 == 0)
    
    r1, r0 = if is_even
        neighbour_addition_ccw(v, direction)
    else
        neighbour_addition_cw(v, direction)
    end
    
    # Set the digit at resolution
    shift = 57 - 3 * (resolution - 1)
    result = (result & ~(UInt64(0x07) << shift)) | (UInt64(r0) << shift)
    carry = r1
    
    # Propagate carry backwards through resolutions
    if carry != 0
        for i in (resolution-1):-1:1
            v = get_digit(ref, i)
            is_even = (i % 2 == 0)
            
            r1, r0 = if is_even
                neighbour_addition_ccw(v, carry)
            else
                neighbour_addition_cw(v, carry)
            end
            
            # Set the digit at position i
            shift = 57 - 3 * (i - 1)
            result = (result & ~(UInt64(0x07) << shift)) | (UInt64(r0) << shift)
            carry = r1
            
            carry == 0 && break
        end
    end
    
    return Z7Carry(Z7IndexUInt64(result), carry)
end

"""
Compute all 6 neighbours of a cell at its resolution.

Returns a vector of 6 Z7IndexUInt64 values representing the neighbours.
For pentagons, one neighbour will be marked as invalid (all bits set).
"""
function get_neighbours(ref::Z7IndexUInt64)
    resolution = get_resolution(ref)
    base_cell = get_base_cell(ref)
    exclusion = EXCLUDE_NEIGHBOURS[base_cell + 1]
    
    # Special case: base cell only (resolution 0)
    if resolution == 0
        result = Vector{Z7IndexUInt64}(undef, 6)
        neighbour_zones = BASE_CELL_NEIGHBOURS[base_cell + 1]
        
        for i in 1:6
            if i == exclusion
                # Invalid neighbour for pentagon
                result[i] = Z7IndexUInt64(typemax(UInt64))
            else
                # Create base cell neighbour
                nb = UInt8(neighbour_zones[i])
                result[i] = Z7IndexUInt64(encode_z7int(nb, UInt8[]))
            end
        end
        return result
    end
    
    # Compute neighbours with carry tracking
    neighbours_carry = [
        get_neighbour(ref, UInt8(1), resolution),
        get_neighbour(ref, UInt8(2), resolution),
        get_neighbour(ref, UInt8(3), resolution),
        get_neighbour(ref, UInt8(4), resolution),
        get_neighbour(ref, UInt8(5), resolution),
        get_neighbour(ref, UInt8(6), resolution)
    ]
    
    # Handle carries (crossing base cell boundaries)
    neighbour_zones = BASE_CELL_NEIGHBOURS[base_cell + 1]
    
    for i in 1:6
        nc = neighbours_carry[i]
        if nc.carry != 0
            # neighbour crosses to a different base cell
            new_base = UInt8(neighbour_zones[nc.carry])
            
            # Update base cell in the raw value
            raw = (nc.idx.raw & ~(UInt64(0x0F) << 60)) | (UInt64(new_base) << 60)
            neighbours_carry[i] = Z7Carry(Z7IndexUInt64(raw), nc.carry)
            
            # Handle rotations when crossing from tropical to polar zones
            if new_base == 0 || new_base == 11
                rotations = ROTATIONS[base_cell + 1]
                first_digit = get_digit(ref, 1)
                if first_digit == 6 || first_digit == 1
                    rotations += 1
                end
                
                # Apply rotations: multiply each digit by 5^rotations, mod 7
                if rotations > 0
                    multiplier = UInt8(1)
                    for _ in 1:rotations
                        multiplier = (multiplier * 5) % 7
                    end
                    
                    raw = neighbours_carry[i].idx.raw
                    for j in 1:resolution
                        d = get_digit(neighbours_carry[i].idx, j)
                        rotated = (d * multiplier) % 7
                        shift = 57 - 3 * (j - 1)
                        raw = (raw & ~(UInt64(0x07) << shift)) | (UInt64(rotated) << shift)
                    end
                    neighbours_carry[i] = Z7Carry(Z7IndexUInt64(raw), nc.carry)
                end
            end
            
            # Handle rotations from polar zones
            if base_cell == 0 || base_cell == 11
                row = get_digit(ref, 1)
                col = get_digit(neighbours_carry[i].idx, 1)
                
                if base_cell == 11
                    row = 7 - row
                    col = 7 - col
                end
                
                if row >= 1 && row <= 6 && col >= 1 && col <= 6
                    rotations = POLE_0_ROTATIONS[row, col]
                    
                    if rotations > 0
                        multiplier = UInt8(1)
                        for _ in 1:rotations
                            multiplier = (multiplier * 5) % 7
                        end
                        
                        raw = neighbours_carry[i].idx.raw
                        for j in 1:resolution
                            d = get_digit(neighbours_carry[i].idx, j)
                            rotated = (d * multiplier) % 7
                            shift = 57 - 3 * (j - 1)
                            raw = (raw & ~(UInt64(0x07) << shift)) | (UInt64(rotated) << shift)
                        end
                        neighbours_carry[i] = Z7Carry(Z7IndexUInt64(raw), nc.carry)
                    end
                end
            end
        end
    end
    
    # Extract final neighbour indices
    result = [nc.idx for nc in neighbours_carry]
    
    # Check if we're at a pentagon center (all digits are 0)
    data_only = ref.raw & ~(UInt64(0x0F) << 60)
    data_only = data_only >> (3 * (20 - resolution))
    
    if data_only == 0 && exclusion >= 1 && exclusion <= 6
        # Mark the excluded neighbour as invalid
        result[exclusion] = Z7IndexUInt64(typemax(UInt64))
        return result
    end
    
    # Handle exclusion zone rotations
    ref_first_non_zero = first_non_zero(ref)
    if ref_first_non_zero < 1
        return result
    end
    
    reference_zone = get_digit(ref, ref_first_non_zero)
    multiplier = UInt8(0)
    
    if (reference_zone * 5) % 7 == exclusion
        multiplier = 5  # Rotate counterclockwise
    elseif (reference_zone * 3) % 7 == exclusion
        multiplier = 3  # Rotate clockwise
    end
    
    if multiplier > 0
        for i in 1:6
            to_rotate = first_non_zero(result[i])
            if to_rotate >= 1 && get_digit(result[i], to_rotate) == exclusion
                # Rotate this neighbour
                raw = result[i].raw
                for j in to_rotate:resolution
                    d = get_digit(result[i], j)
                    rotated = (d * multiplier) % 7
                    shift = 57 - 3 * (j - 1)
                    raw = (raw & ~(UInt64(0x07) << shift)) | (UInt64(rotated) << shift)
                end
                result[i] = Z7IndexUInt64(raw)
            end
        end
    end
    
    return result
end

"""
Find the first non-zero digit position in a Z7 index.
Returns the 1-based position, or 0 if all digits are 7 (beyond resolution).
"""
function first_non_zero(idx::Z7IndexUInt64)
    first_digit = get_digit(idx, 1)
    first_digit == 7 && return 0
    
    # Mask out the base cell and count leading zeros
    base_mask = ~(UInt64(0x0F) << 60)
    masked = idx.raw & base_mask
    
    # Count leading zeros and convert to digit position
    lz = leading_zeros(masked)
    return div(lz - 4, 3) + 1
end

## Z7IndexComp neighbour support

"""
Compute a single neighbour in direction N (1-6) at a given resolution for Z7IndexComp.
"""
function get_neighbour(ref::Z7IndexComp, direction::UInt8, resolution::Int)
    @assert 1 <= direction <= 6 "Direction must be 1-6"
    @assert 1 <= resolution <= 20 "Resolution must be 1-20"
    
    # Start with a copy of the reference index
    result = ref.raw
    carry = UInt8(0)
    
    # Add the direction digit at the specified resolution
    v = ref.digits[resolution]
    is_even = (resolution % 2 == 0)
    
    r1, r0 = if is_even
        neighbour_addition_ccw(v, direction)
    else
        neighbour_addition_cw(v, direction)
    end
    
    # Set the digit at resolution
    shift = 57 - 3 * (resolution - 1)
    result = (result & ~(UInt64(0x07) << shift)) | (UInt64(r0) << shift)
    carry = r1
    
    # Propagate carry backwards through resolutions
    if carry != 0
        for i in (resolution-1):-1:1
            v = ref.digits[i]
            is_even = (i % 2 == 0)
            
            r1, r0 = if is_even
                neighbour_addition_ccw(v, carry)
            else
                neighbour_addition_cw(v, carry)
            end
            
            # Set the digit at position i
            shift = 57 - 3 * (i - 1)
            result = (result & ~(UInt64(0x07) << shift)) | (UInt64(r0) << shift)
            carry = r1
            
            carry == 0 && break
        end
    end
    
    return Z7Carry(Z7IndexUInt64(result), carry)
end

"""
Compute all 6 neighbours of a Z7IndexComp cell at its resolution.
"""
function get_neighbours(ref::Z7IndexComp)
    resolution = get_resolution(ref)
    base_cell = ref.base_cell
    exclusion = EXCLUDE_NEIGHBOURS[base_cell + 1]
    
    # Special case: base cell only (resolution 0)
    if resolution == 0
        result = Vector{Z7IndexComp}(undef, 6)
        neighbour_zones = BASE_CELL_NEIGHBOURS[base_cell + 1]
        
        for i in 1:6
            if i == exclusion
                # Invalid neighbour for pentagon
                result[i] = Z7IndexComp(typemax(UInt64))
            else
                # Create base cell neighbour
                nb = UInt8(neighbour_zones[i])
                result[i] = Z7IndexComp(encode_z7int(nb, UInt8[]))
            end
        end
        return result
    end
    
    # Compute neighbours with carry tracking
    neighbours_carry = [
        get_neighbour(ref, UInt8(1), resolution),
        get_neighbour(ref, UInt8(2), resolution),
        get_neighbour(ref, UInt8(3), resolution),
        get_neighbour(ref, UInt8(4), resolution),
        get_neighbour(ref, UInt8(5), resolution),
        get_neighbour(ref, UInt8(6), resolution)
    ]
    
    # Handle carries (crossing base cell boundaries)
    neighbour_zones = BASE_CELL_NEIGHBOURS[base_cell + 1]
    
    for i in 1:6
        nc = neighbours_carry[i]
        if nc.carry != 0
            # neighbour crosses to a different base cell
            new_base = UInt8(neighbour_zones[nc.carry])
            
            # Update base cell in the raw value
            raw = (nc.idx.raw & ~(UInt64(0x0F) << 60)) | (UInt64(new_base) << 60)
            neighbours_carry[i] = Z7Carry(Z7IndexUInt64(raw), nc.carry)
            
            # Handle rotations when crossing from tropical to polar zones
            if new_base == 0 || new_base == 11
                rotations = ROTATIONS[base_cell + 1]
                first_digit = ref.digits[1]
                if first_digit == 6 || first_digit == 1
                    rotations += 1
                end
                
                # Apply rotations: multiply each digit by 5^rotations, mod 7
                if rotations > 0
                    multiplier = UInt8(1)
                    for _ in 1:rotations
                        multiplier = (multiplier * 5) % 7
                    end
                    
                    raw = neighbours_carry[i].idx.raw
                    for j in 1:resolution
                        d = get_digit(neighbours_carry[i].idx, j)
                        rotated = (d * multiplier) % 7
                        shift = 57 - 3 * (j - 1)
                        raw = (raw & ~(UInt64(0x07) << shift)) | (UInt64(rotated) << shift)
                    end
                    neighbours_carry[i] = Z7Carry(Z7IndexUInt64(raw), nc.carry)
                end
            end
            
            # Handle rotations from polar zones
            if base_cell == 0 || base_cell == 11
                row = ref.digits[1]
                col = get_digit(neighbours_carry[i].idx, 1)
                
                if base_cell == 11
                    row = 7 - row
                    col = 7 - col
                end
                
                if row >= 1 && row <= 6 && col >= 1 && col <= 6
                    rotations = POLE_0_ROTATIONS[row, col]
                    
                    if rotations > 0
                        multiplier = UInt8(1)
                        for _ in 1:rotations
                            multiplier = (multiplier * 5) % 7
                        end
                        
                        raw = neighbours_carry[i].idx.raw
                        for j in 1:resolution
                            d = get_digit(neighbours_carry[i].idx, j)
                            rotated = (d * multiplier) % 7
                            shift = 57 - 3 * (j - 1)
                            raw = (raw & ~(UInt64(0x07) << shift)) | (UInt64(rotated) << shift)
                        end
                        neighbours_carry[i] = Z7Carry(Z7IndexUInt64(raw), nc.carry)
                    end
                end
            end
        end
    end
    
    # Extract final neighbour indices and convert to Z7IndexComp
    result = [Z7IndexComp(nc.idx.raw) for nc in neighbours_carry]
    
    # Check if we're at a pentagon center (all digits are 0)
    data_only = ref.raw & ~(UInt64(0x0F) << 60)
    data_only = data_only >> (3 * (20 - resolution))
    
    if data_only == 0 && exclusion >= 1 && exclusion <= 6
        # Mark the excluded neighbour as invalid
        result[exclusion] = Z7IndexComp(typemax(UInt64))
        return result
    end
    
    # Handle exclusion zone rotations
    ref_first_non_zero = first_non_zero(ref)
    if ref_first_non_zero < 1
        return result
    end
    
    reference_zone = ref.digits[ref_first_non_zero]
    multiplier = UInt8(0)
    
    if (reference_zone * 5) % 7 == exclusion
        multiplier = 5  # Rotate counterclockwise
    elseif (reference_zone * 3) % 7 == exclusion
        multiplier = 3  # Rotate clockwise
    end
    
    if multiplier > 0
        for i in 1:6
            to_rotate = first_non_zero(result[i])
            if to_rotate >= 1 && result[i].digits[to_rotate] == exclusion
                # Rotate this neighbour
                raw = result[i].raw
                for j in to_rotate:resolution
                    d = result[i].digits[j]
                    rotated = (d * multiplier) % 7
                    shift = 57 - 3 * (j - 1)
                    raw = (raw & ~(UInt64(0x07) << shift)) | (UInt64(rotated) << shift)
                end
                result[i] = Z7IndexComp(raw)
            end
        end
    end
    
    return result
end

"""
Find the first non-zero digit position in a Z7IndexComp.
"""
function first_non_zero(idx::Z7IndexComp)
    idx.digits[1] == 7 && return 0
    
    # Mask out the base cell and count leading zeros
    base_mask = ~(UInt64(0x0F) << 60)
    masked = idx.raw & base_mask
    
    # Count leading zeros and convert to digit position
    lz = leading_zeros(masked)
    return div(lz - 4, 3) + 1
end

## Helper functions for string conversion

"""
Convert a Z7 string (e.g., "0800433") to Z7IndexUInt64.
"""
function z7string_to_index(z7_string::String)
    # Parse base cell (first 2 characters)
    base_cell = parse(UInt8, z7_string[1:2])
    
    # Parse resolution digits (remaining characters)
    digits = UInt8[]
    for i in 3:length(z7_string)
        push!(digits, parse(UInt8, string(z7_string[i])))
    end
    
    return Z7IndexUInt64(encode_z7int(base_cell, digits))
end

"""
Convert a Z7IndexUInt64 to Z7 string representation.
"""
function index_to_z7string(idx::Z7IndexUInt64)
    base_cell = get_base_cell(idx)
    result = lpad(string(base_cell), 2, '0')
    
    for i in 1:20
        d = get_digit(idx, i)
        d == 7 && break
        result *= string(d)
    end
    
    return result
end

"""
Convert a Z7IndexComp to Z7 string representation.
"""
function index_to_z7string(idx::Z7IndexComp)
    result = lpad(string(idx.base_cell), 2, '0')
    
    for i in 1:20
        d = idx.digits[i]
        d == 7 && break
        result *= string(d)
    end
    
    return result
end


end
