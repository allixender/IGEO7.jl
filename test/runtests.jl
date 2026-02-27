using Z7
using Test


@testset "IGEO7 Resolution Statistics" begin
    @testset "get_resolution_stats" begin
        # Test valid resolutions
        stats_0 = get_resolution_stats(0)
        @test stats_0.num_cells == 12
        @test stats_0.cls_km ≈ 8199.5003701
        
        stats_10 = get_resolution_stats(10)
        @test stats_10.num_cells == 2824752492
        @test stats_10.area_m2 ≈ 180570.0
        
        # Test invalid resolution
        @test_throws ArgumentError get_resolution_stats(21)
        @test_throws ArgumentError get_resolution_stats(-1)
    end
    
    @testset "get_num_cells" begin
        @test get_num_cells(0) == 12
        @test get_num_cells(6) == 1176492
        @test get_num_cells(20) == 797922662976120012
    end
    
    @testset "get_cell_area" begin
        @test get_cell_area_m2(0) ≈ 51006562172408.9
        @test get_cell_area_km2(0) ≈ 51006562.1724089
        @test get_cell_area_m2(14) ≈ 75.2
    end
    
    @testset "get_cls" begin
        @test get_cls_m(9) ≈ 1268.6064
        @test get_cls_km(9) ≈ 1.2686064
    end
    
    @testset "find_resolution_by_value" begin
        # Find resolution with ~1000m characteristic length
        res = find_resolution_by_value(1000.0, :cls_m)
        @test res == 9
        @test get_cls_m(res) ≈ 1268.6064
        
        # Find resolution with at least 1 million cells (prefer larger)
        res = find_resolution_by_value(1_000_000, :num_cells, prefer=:larger)
        @test res == 6
        @test get_num_cells(res) >= 1_000_000
        
        # Find resolution with area closest to 100 m²
        res = find_resolution_by_value(100.0, :area_m2)
        @test res == 14
        @test get_cell_area_m2(res) ≈ 75.2
        
        # Test prefer=:smaller
        res = find_resolution_by_value(1_000_000, :num_cells, prefer=:smaller)
        @test res == 5
        @test get_num_cells(res) <= 1_000_000
        
        # Test invalid metric
        @test_throws ArgumentError find_resolution_by_value(100.0, :invalid_metric)
        
        # Test invalid prefer strategy
        @test_throws ArgumentError find_resolution_by_value(100.0, :cls_m, prefer=:invalid)
    end
    
    @testset "find_resolution_by_cls_m" begin
        res = find_resolution_by_cls_m(1000.0)
        @test res == 9
        
        res = find_resolution_by_cls_m(500.0, prefer=:larger)
        @test res == 9
        @test get_cls_m(res) >= 500.0
    end
    
    @testset "find_resolution_by_area_m2" begin
        res = find_resolution_by_area_m2(100.0)
        @test res == 14
    end
    
    @testset "find_resolution_by_num_cells" begin
        res = find_resolution_by_num_cells(1_000_000)
        @test res == 6
    end
end

@testset "Z7 Hex and Z7 String Parsing and Conversion" begin
    z7_hex_id = lowercase("004291D4C313FFFF")
    z7_string_id = "0001024435230304"
    
    @testset "decode_z7hex_index" begin
        base_cell, resolution_digits = decode_z7hex_index(z7_hex_id)
        @test base_cell == 0
        @test length(resolution_digits) == 20
        @test resolution_digits[1:14] == Int8[0, 1, 0, 2, 4, 4, 3, 5, 2, 3, 0, 3, 0, 4]
        @test all(resolution_digits[15:20] .== 7)  # Beyond resolution filled with 7
    end
    
    @testset "encode_z7hex_index" begin
        # Test encoding and round-trip
        base_cell = 0
        digits = Int8[0, 1, 0, 2, 4, 4, 3, 5, 2, 3, 0, 3, 0, 4]
        encoded = encode_z7hex_index(base_cell, digits)
        @test typeof(encoded) == String
        @test length(encoded) == 16
        
        # Decode and verify
        decoded_base, decoded_digits = decode_z7hex_index(encoded)
        @test decoded_base == base_cell
        @test decoded_digits[1:length(digits)] == digits
        
        # Test round-trip with original hex ID
        base_cell_orig, digits_orig = decode_z7hex_index(z7_hex_id)
        reconstructed = encode_z7hex_index(base_cell_orig, digits_orig)
        @test reconstructed == z7_hex_id
    end
    
    @testset "z7hex_to_z7string" begin
        z7string = z7hex_to_z7string("004291D4C313FFFF")
        @test z7string == z7_string_id
        @test typeof(z7string) == String
    end
    
    @testset "z7hex_to_z7int" begin
        z7int = z7hex_to_z7int(z7_hex_id)
        @test typeof(z7int) == UInt64
        @test z7int == 18737691454865407
    end
    
    @testset "get_z7hex_resolution" begin
        res = get_z7hex_resolution("004291D4C313FFFF")
        @test res == 14
        
        # Test with different resolutions
        @test get_z7hex_resolution(encode_z7hex_index(0, Int8[])) == 0
        @test get_z7hex_resolution(encode_z7hex_index(5, Int8[1, 2, 3])) == 3
    end
    
    @testset "get_z7hex_local_pos" begin
        parent, local_pos, is_center = get_z7hex_local_pos("004291D4C313FFFF")
        @test parent == "000102443523030"
        @test local_pos == "4"
        @test is_center == false
        
        # Test center cell
        center_hex = encode_z7hex_index(0, Int8[1, 2, 3, 0])
        parent_c, local_pos_c, is_center_c = get_z7hex_local_pos(center_hex)
        @test is_center_c == true
        @test local_pos_c == "0"
    end
    
    @testset "z7int_to_z7hex" begin
        z7int = UInt64(18737691454865407)
        hex_str = z7int_to_z7hex(z7int)
        @test hex_str == z7_hex_id
        @test length(hex_str) == 16
    end
    
    @testset "decode_z7int" begin
        z7int = UInt64(18737691454865407)
        base_cell, digits = decode_z7int(z7int)
        @test base_cell == 0
        @test length(digits) == 20
    end
    
    @testset "encode_z7int" begin
        # Test with UInt8 types
        encoded1 = encode_z7int(UInt8(5), UInt8[0, 1, 2, 3])
        @test typeof(encoded1) == UInt64
        
        # Test with mixed integer types (generic fallback)
        encoded2 = encode_z7int(5, [0, 1, 2, 3])
        @test encoded1 == encoded2
        
        encoded3 = encode_z7int(UInt64(5), UInt64[0, 1, 2, 3])
        @test encoded1 == encoded3
        
        # Test round-trip
        base_cell = UInt8(3)
        digits = UInt8[1, 2, 3, 4, 5]
        encoded = encode_z7int(base_cell, digits)
        decoded_base, decoded_digits = decode_z7int(encoded)
        @test decoded_base == base_cell
        @test decoded_digits[1:length(digits)] == digits
    end
    
    @testset "get_z7string_resolution" begin
        @test get_z7string_resolution(z7_string_id) == 14
        @test get_z7string_resolution("00") == 0
        @test get_z7string_resolution("001234") == 4
    end
    
    @testset "get_z7string_local_pos" begin
        parent, local_pos, is_center = get_z7string_local_pos(z7_string_id)
        @test parent == "000102443523030"
        @test local_pos == "4"
        @test is_center == false
        
        # Test consistency with z7hex version
        parent_hex, local_pos_hex, is_center_hex = get_z7hex_local_pos("004291D4C313FFFF")
        @test parent == parent_hex
        @test local_pos == local_pos_hex
        @test is_center == is_center_hex
    end
end


@testset "Z7IndexUInt64 and Z7IndexComp Types" begin
    test_digits = UInt8[0, 1, 0, 2, 4, 4, 3, 5, 2, 3, 0, 3, 0, 4]
    test_raw = encode_z7int(0, test_digits)
    
    @testset "Z7IndexUInt64 Construction" begin
        v = Z7IndexUInt64(test_raw)
        @test typeof(v) == Z7IndexUInt64
        @test v.raw == test_raw
    end
    
    @testset "Z7IndexUInt64 get_base_cell" begin
        v = Z7IndexUInt64(test_raw)
        @test get_base_cell(v) == 0x00
        
        # Test with different base cells
        v2 = Z7IndexUInt64(encode_z7int(5, UInt8[1, 2, 3]))
        @test get_base_cell(v2) == 0x05
    end
    
    @testset "Z7IndexUInt64 get_digit" begin
        v = Z7IndexUInt64(test_raw)
        @test get_digit(v, 1) == 0x00
        @test get_digit(v, 2) == 0x01
        @test get_digit(v, 3) == 0x00
        @test get_digit(v, 4) == 0x02
        @test get_digit(v, 5) == 0x04
    end
    
    @testset "Z7IndexUInt64 get_digits" begin
        v = Z7IndexUInt64(test_raw)
        digits = get_digits(v)
        @test length(digits) == 20
        @test digits[1:14] == tuple(test_digits...)
        @test all(digits[15:20] .== 0x07)
    end
    
    @testset "Z7IndexUInt64 get_resolution" begin
        v = Z7IndexUInt64(test_raw)
        @test get_resolution(v) == 14
        
        # Test resolution 0 (base cell only)
        v0 = Z7IndexUInt64(encode_z7int(3, UInt8[]))
        @test get_resolution(v0) == 0
        
        # Test other resolutions
        v3 = Z7IndexUInt64(encode_z7int(1, UInt8[1, 2, 3]))
        @test get_resolution(v3) == 3
    end
    
    @testset "Z7IndexUInt64 get_parent" begin
        v = Z7IndexUInt64(test_raw)
        @test get_resolution(v) == 14
        
        # Get parent (resolution 13)
        vp = get_parent(v)
        @test get_resolution(vp) == 13
        @test get_base_cell(vp) == get_base_cell(v)
        
        # Verify parent digits match first 13 digits
        parent_digits = get_digits(vp)
        original_digits = get_digits(v)
        @test parent_digits[1:13] == original_digits[1:13]
        @test all(parent_digits[14:20] .== 0x07)
        
        # Test get_parent with explicit resolution
        vp2 = get_parent(v, 10)
        @test get_resolution(vp2) == 10
    end
    
    @testset "Z7IndexComp Construction" begin
        v2 = Z7IndexComp(test_raw)
        @test typeof(v2) == Z7IndexComp
        @test v2.raw == test_raw
        @test v2.base_cell == 0x00
        @test length(v2.digits) == 20
    end
    
    @testset "Z7IndexComp get_base_cell" begin
        v2 = Z7IndexComp(test_raw)
        @test v2.base_cell == 0x00
        @test get_base_cell(v2) == 0x00
    end
    
    @testset "Z7IndexComp get_digit" begin
        v2 = Z7IndexComp(test_raw)
        @test get_digit(v2, 1) == 0x00
        @test get_digit(v2, 2) == 0x01
        @test get_digit(v2, 3) == 0x00
        @test get_digit(v2, 14) == 0x04
    end
    
    @testset "Z7IndexComp get_digits" begin
        v2 = Z7IndexComp(test_raw)
        digits = get_digits(v2)
        @test digits == v2.digits
        @test length(digits) == 20
        # SVector is returned, compare as arrays
        @test collect(digits[1:14]) == test_digits
    end
    
    @testset "Z7IndexComp get_resolution" begin
        v2 = Z7IndexComp(test_raw)
        @test get_resolution(v2) == 14
        
        # Test with base cell only
        v0 = Z7IndexComp(encode_z7int(7, UInt8[]))
        @test get_resolution(v0) == 0
    end
    
    @testset "Z7IndexComp get_parent" begin
        v2 = Z7IndexComp(test_raw)
        @test get_resolution(v2) == 14
        
        # Get parent
        vp2 = get_parent(v2)
        @test get_resolution(vp2) == 13
        @test vp2.base_cell == v2.base_cell
        
        # Verify digits
        @test vp2.digits[1:13] == v2.digits[1:13]
        @test all(vp2.digits[14:20] .== 0x07)
        
        # Test with explicit resolution
        vp3 = get_parent(v2, 5)
        @test get_resolution(vp3) == 5
    end
    
    @testset "Z7IndexUInt64 vs Z7IndexComp Consistency" begin
        # Both types should give same results
        v_uint = Z7IndexUInt64(test_raw)
        v_comp = Z7IndexComp(test_raw)
        
        @test get_base_cell(v_uint) == get_base_cell(v_comp)
        @test get_resolution(v_uint) == get_resolution(v_comp)
        @test get_digits(v_uint) == tuple(v_comp.digits...)
        
        for i in 1:14
            @test get_digit(v_uint, i) == get_digit(v_comp, i)
        end
    end
end

@testset "Base Cell Neighbours" begin
    @testset "get_base_cell_neighbours with UInt8" begin
        # Test base cell 00
        neighbours_0 = get_base_cell_neighbours(UInt8(0))
        @test length(neighbours_0) == 5  # Pentagons have 5 neighbours
        @test neighbours_0 == [5, 4, 2, 1, 3]
        
        # Test base cell 01
        neighbours_1 = get_base_cell_neighbours(UInt8(1))
        @test length(neighbours_1) == 5
        @test neighbours_1 == [5, 0, 6, 10, 2]
        
        # Test base cell 06 (different exclusion pattern)
        neighbours_6 = get_base_cell_neighbours(UInt8(6))
        @test length(neighbours_6) == 5
        @test neighbours_6 == [10, 2, 1, 11, 7]
        
        # Test base cell 11
        neighbours_11 = get_base_cell_neighbours(UInt8(11))
        @test length(neighbours_11) == 5
        @test neighbours_11 == [9, 6, 10, 8, 7]
        
        # Test invalid base cell
        @test_throws ArgumentError get_base_cell_neighbours(UInt8(12))
    end
    
    @testset "get_base_cell_neighbour with UInt8 and direction" begin
        # Test base cell 01, various directions
        @test get_base_cell_neighbour(UInt8(1), 0) == UInt8(5)
        @test get_base_cell_neighbour(UInt8(1), 1) == UInt8(0)
        @test get_base_cell_neighbour(UInt8(1), 2) == UInt8(6)
        @test get_base_cell_neighbour(UInt8(1), 3) == UInt8(10)
        @test get_base_cell_neighbour(UInt8(1), 4) == UInt8(2)
        
        # Invalid direction for pentagon (only has 5 neighbours, directions 0-4)
        @test get_base_cell_neighbour(UInt8(1), 5) === nothing
        @test get_base_cell_neighbour(UInt8(1), 6) === nothing
        @test get_base_cell_neighbour(UInt8(1), -1) === nothing
        
        # Test base cell 00
        @test get_base_cell_neighbour(UInt8(0), 0) == UInt8(5)
        @test get_base_cell_neighbour(UInt8(0), 1) == UInt8(4)
        @test get_base_cell_neighbour(UInt8(0), 4) == UInt8(3)
        
        # Test invalid base cell
        @test_throws ArgumentError get_base_cell_neighbour(UInt8(12), 0)
    end
    
    @testset "get_base_cell_neighbours with Z7IndexComp" begin
        # Test base cell 01 as Z7IndexComp
        b1 = Z7IndexComp(encode_z7int(1, UInt8[]))
        @test get_resolution(b1) == 0
        neighbours_b1 = get_base_cell_neighbours(b1)
        @test length(neighbours_b1) == 5
        @test neighbours_b1 == [5, 0, 6, 10, 2]
        
        # Test base cell 00
        b0 = Z7IndexComp(encode_z7int(0, UInt8[]))
        neighbours_b0 = get_base_cell_neighbours(b0)
        @test neighbours_b0 == [5, 4, 2, 1, 3]
        
        # Test that non-base-cell resolution throws error
        b1_res1 = Z7IndexComp(encode_z7int(1, UInt8[1]))
        @test_throws ArgumentError get_base_cell_neighbours(b1_res1)
    end
    
    @testset "get_base_cell_neighbours with Z7IndexUInt64" begin
        # Test base cell 05 as Z7IndexUInt64
        b5 = Z7IndexUInt64(encode_z7int(5, UInt8[]))
        @test get_resolution(b5) == 0
        neighbours_b5 = get_base_cell_neighbours(b5)
        @test length(neighbours_b5) == 5
        @test neighbours_b5 == [4, 0, 10, 9, 1]
        
        # Test that non-base-cell resolution throws error
        b5_res2 = Z7IndexUInt64(encode_z7int(5, UInt8[1, 2]))
        @test_throws ArgumentError get_base_cell_neighbours(b5_res2)
    end
    
    @testset "get_base_cell_neighbour with Z7Index types" begin
        # Test with Z7IndexComp
        b1 = Z7IndexComp(encode_z7int(1, UInt8[]))
        @test get_base_cell_neighbour(b1, 0) == UInt8(5)
        @test get_base_cell_neighbour(b1, 2) == UInt8(6)
        @test get_base_cell_neighbour(b1, 5) === nothing
        
        # Test with Z7IndexUInt64
        b2 = Z7IndexUInt64(encode_z7int(2, UInt8[]))
        @test get_base_cell_neighbour(b2, 0) == UInt8(1)
        @test get_base_cell_neighbour(b2, 1) == UInt8(0)
        @test get_base_cell_neighbour(b2, 6) === nothing
    end
    
    @testset "All base cells have 5 neighbours" begin
        # Verify all 12 base cells (pentagons) have exactly 5 neighbours
        for base_cell in 0:11
            neighbours = get_base_cell_neighbours(UInt8(base_cell))
            @test length(neighbours) == 5
            
            # Verify all neighbours are valid base cells (0-11)
            @test all(0 .<= neighbours .<= 11)
            
            # Verify no duplicates
            @test length(unique(neighbours)) == 5
        end
    end
end

@testset "String Conversion Helpers" begin
    @testset "z7string_to_index" begin
        # Test basic conversion
        idx = z7string_to_index("0800433")
        @test typeof(idx) == Z7IndexUInt64
        @test get_base_cell(idx) == 0x08
        @test get_resolution(idx) == 5
        @test get_digit(idx, 1) == 0x00
        @test get_digit(idx, 2) == 0x00
        @test get_digit(idx, 3) == 0x04
        @test get_digit(idx, 4) == 0x03
        @test get_digit(idx, 5) == 0x03
        
        # Test base cell only
        idx0 = z7string_to_index("00")
        @test get_base_cell(idx0) == 0x00
        @test get_resolution(idx0) == 0
        
        # Test different base cells
        idx11 = z7string_to_index("1111")
        @test get_base_cell(idx11) == 0x0B
        @test get_resolution(idx11) == 2
    end
    
    @testset "index_to_z7string for Z7IndexUInt64" begin
        # Test basic conversion
        idx = z7string_to_index("0800433")
        str = index_to_z7string(idx)
        @test str == "0800433"
        
        # Test round-trip
        idx2 = z7string_to_index("091201")
        str2 = index_to_z7string(idx2)
        @test str2 == "091201"
        
        # Test base cell only
        idx0 = z7string_to_index("05")
        str0 = index_to_z7string(idx0)
        @test str0 == "05"
    end
    
    @testset "index_to_z7string for Z7IndexComp" begin
        # Test basic conversion
        idx = Z7IndexComp(z7string_to_index("0800433").raw)
        str = index_to_z7string(idx)
        @test str == "0800433"
        
        # Test round-trip
        idx2 = Z7IndexComp(z7string_to_index("1001201").raw)
        str2 = index_to_z7string(idx2)
        @test str2 == "1001201"
    end
end

@testset "first_non_zero Function" begin
    @testset "first_non_zero with Z7IndexUInt64" begin
        # Test from C++ tests: first_non_zero("0000000"_Z7) == 6
        idx1 = z7string_to_index("0000000")
        @test first_non_zero(idx1) == 6
        
        # Test: first_non_zero("1000000"_Z7) == 6
        idx2 = z7string_to_index("1000000")
        @test first_non_zero(idx2) == 6
        
        # Test: first_non_zero("1234000"_Z7) == 1
        idx3 = z7string_to_index("1234000")
        @test first_non_zero(idx3) == 1
        
        # Test: first_non_zero("1200567"_Z7) == 3
        idx4 = z7string_to_index("1200567")
        @test first_non_zero(idx4) == 3
        
        # Test: first_non_zero("1277777"_Z7) == 0 (all digits are 7)
        idx5 = z7string_to_index("12")
        @test first_non_zero(idx5) == 0
    end
    
    @testset "first_non_zero with Z7IndexComp" begin
        # Test same cases with Z7IndexComp
        idx1 = Z7IndexComp(z7string_to_index("0000000").raw)
        @test first_non_zero(idx1) == 6
        
        idx2 = Z7IndexComp(z7string_to_index("1234000").raw)
        @test first_non_zero(idx2) == 1
        
        idx3 = Z7IndexComp(z7string_to_index("1200567").raw)
        @test first_non_zero(idx3) == 3
    end
end

@testset "GBT Neighbour Addition Functions" begin
    @testset "neighbour_addition_cw" begin
        # 0 + 0 = (0, 0)
        @test neighbour_addition_cw(UInt8(0), UInt8(0)) == (0, 0)
        # 0 + 1 = (0, 1)
        @test neighbour_addition_cw(UInt8(0), UInt8(1)) == (0, 1)
        # 1 + 1 = (1, 4)
        @test neighbour_addition_cw(UInt8(1), UInt8(1)) == (1, 4)
        # 1 + 2 = (0, 3)
        @test neighbour_addition_cw(UInt8(1), UInt8(2)) == (0, 3)
    end

    @testset "neighbour_addition_ccw" begin
        # 0 + 0 = (0, 0)
        @test neighbour_addition_ccw(UInt8(0), UInt8(0)) == (0, 0)
        # 0 + 1 = (0, 1)
        @test neighbour_addition_ccw(UInt8(0), UInt8(1)) == (0, 1)
        # 1 + 1 = (1, 2)
        @test neighbour_addition_ccw(UInt8(1), UInt8(1)) == (1, 2)
        # 1 + 2 = (0, 3)
        @test neighbour_addition_ccw(UInt8(1), UInt8(2)) == (0, 3)
    end

    @testset "neighbour_addition_ccw_mod" begin
        # 0 + 0 = (0, 0)
        @test neighbour_addition_ccw_mod(UInt8(0), UInt8(0)) == (0, 0)
        # 1 + 1 = (1, 2)
        @test neighbour_addition_ccw_mod(UInt8(1), UInt8(1)) == (1, 2)
        # 6 + 1 = (0, 0)  - mod 7(6+1) = 0
        @test neighbour_addition_ccw_mod(UInt8(6), UInt8(1)) == (0, 0)
    end
end

@testset "GBT Neighbour Calculations (Z7IndexUInt64)" begin
    function test_nbs(ref_str, expected_strs)
        idx = z7string_to_index(ref_str)
        nbs = get_neighbours(idx)
        valid_nb_strs = [index_to_z7string(n) for n in nbs if n.raw != typemax(UInt64)]
        @test Set(valid_nb_strs) == Set(expected_strs)
    end

    @testset "get_neighbours - Level 2 Reference Data" begin
        test_nbs("0000", ["0004", "0006", "0003", "0001", "0005"])
        test_nbs("0100", ["0104", "0106", "0103", "0101", "0105"])
        test_nbs("0103", ["0106", "0161", "0136", "0134", "0101", "0100"])
        test_nbs("0136", ["0161", "0163", "0132", "0130", "0134", "0103"])
        test_nbs("0132", ["0163", "0055", "0051", "0133", "0130", "0136"])
    end

    @testset "get_neighbour - Single Direction" begin
        idx = z7string_to_index("0103")
        # direction 3 for 0103 at res 2 (even -> CCW)
        # CCW(3, 3) -> (3, 6). Carry 3 added to 0 using CW -> (0, 3)
        # Result digits: 3, 6 -> 0136
        nc = get_neighbour(idx, UInt8(3), 2)
        @test index_to_z7string(nc.idx) == "0136"
        @test nc.carry == 0

        # direction 5 for 0103 at res 2
        # CCW(3, 5) -> (0, 1). No carry.
        # Result digits: 0, 1 -> 0101
        nc5 = get_neighbour(idx, UInt8(5), 2)
        @test index_to_z7string(nc5.idx) == "0101"
        @test nc5.carry == 0
    end

    @testset "get_neighbour - Multi-level Carry" begin
        # 01 66
        idx = z7string_to_index("0166")
        # direction 6 at res 2 (even -> CCW)
        # CCW(6, 6) -> (6, 6). Carry 6 added to res 1 digit 6 using CW -> (6, 6).
        # Carry 6 added to Base Cell 1 -> neighbor_zones[6] = 2.
        # So base cell becomes 02. Digits 6, 6.
        # But wait! Rotations!
        # Crossing to base cell 2 from 1. 02 is not 0 or 11. No tropical-to-polar rotation.
        # BUT wait! get_neighbour DOES NOT handle base cell crossing.
        # It only returns the carry.
        nc = get_neighbour(idx, UInt8(6), 2)
        @test nc.carry == 6
        @test get_digit(nc.idx, 1) == 3
        @test get_digit(nc.idx, 2) == 5
    end
end

@testset "GBT Neighbour Calculations (Z7IndexComp)" begin
    function test_nbs_comp(ref_str, expected_strs)
        idx = Z7IndexComp(z7string_to_index(ref_str).raw)
        nbs = get_neighbours(idx)
        valid_nb_strs = [index_to_z7string(n) for n in nbs if n.raw != typemax(UInt64)]
        @test Set(valid_nb_strs) == Set(expected_strs)
    end

    @testset "get_neighbours - Level 2 Reference Data" begin
        test_nbs_comp("0000", ["0004", "0006", "0003", "0001", "0005"])
        test_nbs_comp("0103", ["0106", "0161", "0136", "0134", "0101", "0100"])
    end

    @testset "get_neighbour - Single Direction" begin
        idx = Z7IndexComp(z7string_to_index("0103").raw)
        nc = get_neighbour(idx, UInt8(3), 2)
        @test index_to_z7string(Z7IndexUInt64(nc.idx.raw)) == "0136"
    end
end

@testset "Pentagon Center Neighbours Exclusion" begin
    # Base cell 0 is a pentagon. Exclusion is 2.
    idx = z7string_to_index("000")
    nbs = get_neighbours(idx)
    
    # Check that the 2nd neighbour is invalid (all bits set)
    # ATTENTION: one must for now manually check if the neighbour has invalid mask
    @test nbs[2].raw == typemax(UInt64)
    
    # Check that filtering gives 5 valid neighbours
    valid_nbs = [n for n in nbs if n.raw != typemax(UInt64)]
    @test length(valid_nbs) == 5
    
    expected_strs = ["001", "003", "004", "005", "006"]
    nb_strs = [index_to_z7string(n) for n in valid_nbs]
    @test Set(nb_strs) == Set(expected_strs)
    
    # Also test for Z7IndexComp
    idx_comp = Z7IndexComp(idx.raw)
    nbs_comp = get_neighbours(idx_comp)
    @test nbs_comp[2].raw == typemax(UInt64)
    valid_nbs_comp = [n for n in nbs_comp if n.raw != typemax(UInt64)]
    @test length(valid_nbs_comp) == 5
end

# regression test for invalid cases  where neighbour addition produced out-of-bounds digits
# or marked as invalid because of exclusion
