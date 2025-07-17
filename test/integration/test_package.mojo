"""Test script to verify the packaged SwissTable works correctly."""

from swisstable import SwissTable, FastStringIntTable, MojoHashFunction


fn test_package_basic():
    """Test basic package functionality."""
    print("Testing packaged SwissTable...")
    
    # Test generic SwissTable
    var table = SwissTable[String, Int](MojoHashFunction())
    var success = table.insert("hello", 42)
    var result = table.lookup("hello")
    
    if result and result.value() == 42:
        print("✅ Generic SwissTable works correctly")
    else:
        print("❌ Generic SwissTable failed")
    
    # Test specialized table
    var fast_table = FastStringIntTable()
    var fast_success = fast_table.insert("world", 100)
    var fast_result = fast_table.lookup("world")
    
    if fast_result and fast_result.value() == 100:
        print("✅ Specialized FastStringIntTable works correctly")
    else:
        print("❌ Specialized FastStringIntTable failed")
    
    # Test bulk operations
    var keys = List[String]()
    var values = List[Int]()
    keys.append("bulk1")
    keys.append("bulk2")
    values.append(200)
    values.append(300)
    
    var bulk_results = table.bulk_insert(keys, values)
    if len(bulk_results) == 2:
        print("✅ Bulk operations work correctly")
    else:
        print("❌ Bulk operations failed")
    
    print("Package size:", len(table), "items")


fn main():
    """Main test function."""
    test_package_basic()
    print("🎉 Package test completed!")