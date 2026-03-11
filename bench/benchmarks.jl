using BenchmarkTools
using IGEO7

# Define benchmark suite
const SUITE = BenchmarkGroup()

SUITE["utility functions"] = BenchmarkGroup()
SUITE["Z7IndexUInt64 functions"] = BenchmarkGroup()
SUITE["Z7IndexComp functions"] = BenchmarkGroup()
SUITE["neighbours"] = BenchmarkGroup()

const Z7_HEX_ID = lowercase("004291D4C313FFFF")
const Z7_STRING_ID = "0001024435230304"
const BASE_CELL = 0
const RESOLUTION_DIGITS = Int8[0, 1, 0, 2, 4, 4, 3, 5, 2, 3, 0, 3, 0, 4]
const RESOLUTION_DIGITS_UINT8 = UInt8[0, 1, 0, 2, 4, 4, 3, 5, 2, 3, 0, 3, 0, 4]
const Z7_INT_ID = encode_z7int(BASE_CELL, RESOLUTION_DIGITS_UINT8)

# Ref wrappers — prevent LLVM from constant-folding benchmarks on
# stack-allocated immutable values (structs, integers, UInt64).
# Strings already allocate on the heap so they are less affected,
# but we wrap them here for consistency.
const r_z7_hex_id            = Ref(Z7_HEX_ID)
const r_base_cell            = Ref(BASE_CELL)
const r_resolution_digits    = Ref(RESOLUTION_DIGITS)
const r_resolution_digits_u8 = Ref(RESOLUTION_DIGITS_UINT8)
const r_z7_int_id            = Ref(Z7_INT_ID)

# --- utility functions ---

SUITE["utility functions"]["decode_z7hex_index"] = @benchmarkable decode_z7hex_index($r_z7_hex_id[])
SUITE["utility functions"]["encode_z7hex_index"] = @benchmarkable encode_z7hex_index($r_base_cell[], $r_resolution_digits[])
SUITE["utility functions"]["z7hex_to_z7string"]  = @benchmarkable z7hex_to_z7string($r_z7_hex_id[])
SUITE["utility functions"]["z7hex_to_z7int"]     = @benchmarkable z7hex_to_z7int($r_z7_hex_id[])
SUITE["utility functions"]["z7int_to_z7hex"]     = @benchmarkable z7int_to_z7hex($r_z7_int_id[])
SUITE["utility functions"]["decode_z7int"]       = @benchmarkable decode_z7int($r_z7_int_id[])
SUITE["utility functions"]["encode_z7int"]       = @benchmarkable encode_z7int($r_base_cell[], $r_resolution_digits_u8[])
SUITE["utility functions"]["get_z7hex_resolution"] = @benchmarkable get_z7hex_resolution($r_z7_hex_id[])

# --- Z7IndexUInt64 functions ---

const idx_u64   = Z7IndexUInt64(Z7_INT_ID)
const r_idx_u64 = Ref(idx_u64)

SUITE["Z7IndexUInt64 functions"]["Construction"]   = @benchmarkable Z7IndexUInt64($r_z7_int_id[])
SUITE["Z7IndexUInt64 functions"]["get_base_cell"]  = @benchmarkable get_base_cell($r_idx_u64[])
SUITE["Z7IndexUInt64 functions"]["get_digits"]     = @benchmarkable get_digits($r_idx_u64[])
SUITE["Z7IndexUInt64 functions"]["get_digit"]      = @benchmarkable get_digit($r_idx_u64[], 5)
SUITE["Z7IndexUInt64 functions"]["get_resolution"] = @benchmarkable get_resolution($r_idx_u64[])
SUITE["Z7IndexUInt64 functions"]["get_parent"]     = @benchmarkable get_parent($r_idx_u64[])

# --- Z7IndexComp functions ---

const idx_comp   = Z7IndexComp(Z7_INT_ID)
const r_idx_comp = Ref(idx_comp)

SUITE["Z7IndexComp functions"]["Construction"]   = @benchmarkable Z7IndexComp($r_z7_int_id[])
SUITE["Z7IndexComp functions"]["get_base_cell"]  = @benchmarkable get_base_cell($r_idx_comp[])
SUITE["Z7IndexComp functions"]["get_digits"]     = @benchmarkable get_digits($r_idx_comp[])
SUITE["Z7IndexComp functions"]["get_digit"]      = @benchmarkable get_digit($r_idx_comp[], 5)
SUITE["Z7IndexComp functions"]["get_resolution"] = @benchmarkable get_resolution($r_idx_comp[])
SUITE["Z7IndexComp functions"]["get_parent"]     = @benchmarkable get_parent($r_idx_comp[])

# --- neighbours ---

SUITE["neighbours"]["Z7IndexComp get_neighbour"]   = @benchmarkable get_neighbour($r_idx_comp[], UInt8(1), 5)
SUITE["neighbours"]["Z7IndexComp get_neighbours"]  = @benchmarkable get_neighbours($r_idx_comp[])
SUITE["neighbours"]["Z7IndexUInt64 get_neighbour"] = @benchmarkable get_neighbour($r_idx_u64[], UInt8(1), 5)
SUITE["neighbours"]["Z7IndexUInt64 get_neighbours"] = @benchmarkable get_neighbours($r_idx_u64[])

# Run when executed directly: julia --project=bench bench/benchmarks.jl
if abspath(PROGRAM_FILE) == @__FILE__
    println("Running benchmarks...")
    results = run(SUITE, verbose=true)
    for (group, suite) in results
        println("\n--- $group ---")
        for (name, trial) in suite
            println("  $name: $(BenchmarkTools.prettytime(minimum(trial).time))")
        end
    end
end
