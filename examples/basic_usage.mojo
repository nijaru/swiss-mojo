#!/usr/bin/env mojo
"""Basic SwissTable usage examples.

This example demonstrates fundamental SwissTable operations
and common usage patterns.
"""

from swisstable import SwissTable, FastStringIntTable, FastIntIntTable, FastStringStringTable, MojoHashFunction


def main():
    print("=== SwissTable Basic Usage Examples ===")
    
    # 1. Basic Construction and Operations
    print("\n1. Basic Construction:")
    var table = SwissTable[String, Int](MojoHashFunction())
    print("Created empty table, size:", table.size())
    print("Initial capacity:", table.capacity())
    
    # 2. Insertion
    print("\n2. Insertions:")
    var inserted1 = table.insert("apple", 10)
    var inserted2 = table.insert("banana", 20)
    var inserted3 = table.insert("cherry", 30)
    
    print("Inserted 'apple' -> 10:", inserted1)
    print("Inserted 'banana' -> 20:", inserted2)
    print("Inserted 'cherry' -> 30:", inserted3)
    print("Table size:", table.size())
    
    # 3. Lookups
    print("\n3. Lookups:")
    var apple_result = table.lookup("apple")
    if apple_result:
        print("Found 'apple':", apple_result.value())
    
    var missing_result = table.lookup("grape")
    if missing_result:
        print("Found 'grape':", missing_result.value())
    else:
        print("'grape' not found")
    
    # 4. Enhanced API Methods
    print("\n4. Enhanced API:")
    
    # Contains check
    print("Contains 'banana':", table.contains("banana"))
    print("Contains 'grape':", table.contains("grape"))
    
    # Get with default
    var banana_value = table.get("banana", -1)
    var grape_value = table.get("grape", -1)
    print("Get 'banana' (default -1):", banana_value)
    print("Get 'grape' (default -1):", grape_value)
    
    # Length and boolean context
    print("Length:", len(table))
    print("Is non-empty:", table.__bool__())
    
    # 5. Updates
    print("\n5. Updates:")
    var updated = table.insert("apple", 15)  # Update existing key
    print("Updated 'apple' -> 15 (should be False):", updated)
    
    var apple_new = table.lookup("apple")
    if apple_new:
        print("'apple' now has value:", apple_new.value())
    
    # 6. Deletion
    print("\n6. Deletion:")
    var deleted = table.delete("banana")
    print("Deleted 'banana':", deleted)
    print("Table size after deletion:", table.size())
    
    # Pop with default
    var popped_cherry = table.pop("cherry", -1)
    var popped_missing = table.pop("missing", -1)
    print("Popped 'cherry':", popped_cherry)
    print("Popped 'missing' (default -1):", popped_missing)
    print("Table size after pop:", table.size())
    
    # 7. Capacity Management
    print("\n7. Capacity Management:")
    print("Current capacity:", table.capacity())
    
    # Reserve capacity for bulk operations
    table.reserve(1000)
    print("After reserve(1000):", table.capacity())
    
    # Bulk insertion
    for i in range(100):
        _ = table.insert("key_" + String(i), i)
    
    print("After bulk insertion (100 items):", table.size())
    print("Final capacity:", table.capacity())
    
    # 8. Clear
    print("\n8. Clear:")
    table.clear()
    print("After clear - size:", table.size())
    print("After clear - is empty:", not table.__bool__())
    
    # 9. Specialized Tables for Maximum Performance
    print("\n9. Specialized Tables:")
    
    # FastStringIntTable - 5.4% faster insertions
    print("FastStringIntTable (String->Int, 5.4% faster):")
    var fast_si_table = FastStringIntTable()
    _ = fast_si_table.insert("count", 42)
    var count_value = fast_si_table.lookup("count")
    if count_value:
        print("  count:", count_value.value())
    
    # FastIntIntTable - 11% faster insertions  
    print("FastIntIntTable (Int->Int, 11% faster):")
    var fast_ii_table = FastIntIntTable()
    _ = fast_ii_table.insert(123, 456)
    var int_value = fast_ii_table.lookup(123)
    if int_value:
        print("  123 ->", int_value.value())
    
    # FastStringStringTable - 147% faster insertions
    print("FastStringStringTable (String->String, 147% faster):")
    var fast_ss_table = FastStringStringTable()
    _ = fast_ss_table.insert("name", "SwissTable")
    _ = fast_ss_table.insert("version", "0.1.0")
    var name_value = fast_ss_table.lookup("name")
    var version_value = fast_ss_table.lookup("version")
    if name_value and version_value:
        print("  " + name_value.value() + " v" + version_value.value())
    
    print("\n=== Basic Usage Examples Complete ===")