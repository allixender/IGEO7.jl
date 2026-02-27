using BenchmarkTools

include("z7_julia.jl")

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

# --- utility functions raw ---

SUITE["utility functions"]["decode_z7hex_index"] = @benchmarkable decode_z7hex_index($Z7_HEX_ID)
SUITE["utility functions"]["encode_z7hex_index"] = @benchmarkable encode_z7hex_index($BASE_CELL, $RESOLUTION_DIGITS)
SUITE["utility functions"]["z7hex_to_z7string"] = @benchmarkable z7hex_to_z7string($Z7_HEX_ID)
SUITE["utility functions"]["z7hex_to_z7int"] = @benchmarkable z7hex_to_z7int($Z7_HEX_ID)
SUITE["utility functions"]["z7int_to_z7hex"] = @benchmarkable z7int_to_z7hex($Z7_INT_ID)
SUITE["utility functions"]["decode_z7int"] = @benchmarkable decode_z7int($Z7_INT_ID)
SUITE["utility functions"]["encode_z7int"] = @benchmarkable encode_z7int($BASE_CELL, $RESOLUTION_DIGITS_UINT8)
SUITE["utility functions"]["get_z7hex_resolution"] = @benchmarkable get_z7hex_resolution($Z7_HEX_ID)

## --- Z7IndexUInt64 functions ---

const idx_u64 = Z7IndexUInt64(Z7_INT_ID)

SUITE["Z7IndexUInt64 functions"]["Construction"] = @benchmarkable Z7IndexUInt64($Z7_INT_ID)
SUITE["Z7IndexUInt64 functions"]["get_base_cell"] = @benchmarkable get_base_cell($idx_u64)
SUITE["Z7IndexUInt64 functions"]["get_digits"] = @benchmarkable get_digits($idx_u64)
SUITE["Z7IndexUInt64 functions"]["get_digit"] = @benchmarkable get_digit($idx_u64, 5)
SUITE["Z7IndexUInt64 functions"]["get_resolution"] = @benchmarkable get_resolution($idx_u64)
SUITE["Z7IndexUInt64 functions"]["get_parent"] = @benchmarkable get_parent($idx_u64)

## --- Z7IndexComp functions ---

const idx_comp = Z7IndexComp(Z7_INT_ID)

SUITE["Z7IndexComp functions"]["Construction"] = @benchmarkable Z7IndexComp($Z7_INT_ID)
SUITE["Z7IndexComp functions"]["get_base_cell"] = @benchmarkable get_base_cell($idx_comp)
SUITE["Z7IndexComp functions"]["get_digits"] = @benchmarkable get_digits($idx_comp)
SUITE["Z7IndexComp functions"]["get_digit"] = @benchmarkable get_digit($idx_comp, 5)
SUITE["Z7IndexComp functions"]["get_resolution"] = @benchmarkable get_resolution($idx_comp)
SUITE["Z7IndexComp functions"]["get_parent"] = @benchmarkable get_parent($idx_comp)

### --- Base Cell Neighbours, GBT neighbours

SUITE["neighbours"]["Z7IndexComp get_neighbour"] = @benchmarkable get_neighbour($idx_comp, UInt8(1), 5)
SUITE["neighbours"]["Z7IndexComp get_neighbours"] = @benchmarkable get_neighbours($idx_comp)
SUITE["neighbours"]["Z7IndexUInt64 get_neighbour"] = @benchmarkable get_neighbour($idx_u64, UInt8(1), 5)
SUITE["neighbours"]["Z7IndexUInt64 get_neighbours"] = @benchmarkable get_neighbours($idx_u64)

# Run a quick sanity check if this is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    println("Running a sample of benchmarks...")
    
    # Run a few benchmarks
    for group in keys(SUITE)
        println("\n--- Group: $group ---")
        # Just run the first one in each group for a quick test
        name = first(keys(SUITE[group]))
        b = run(SUITE[group][name], samples=1)
        println("$name: $(BenchmarkTools.prettytime(minimum(b.times)))")
    end
end
