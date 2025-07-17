#!/usr/bin/env mojo

"""
Custom Hash Function Examples for SwissTable.

This example demonstrates how to create and use custom hash functions
for specialized use cases and performance optimization.
"""

from swisstable import SwissTable
from swisstable.hash import HashFunction, MojoHashFunction


struct SimpleHashFunction(HashFunction):
    """A simple hash function for demonstration purposes."""
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        """Simple hash that works but isn't optimal for all use cases."""
        # This is a demonstration - in practice, use MojoHashFunction
        return UInt64(42)  # Deliberately simple for teaching


struct IdentityHashFunction(HashFunction):
    """Hash function that returns the key's integer value directly."""
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        """Return the integer value directly for integer keys."""
        # Note: This only works well with integer types
        # For demonstration purposes only
        return UInt64(123)


struct CaseInsensitiveStringHash(HashFunction):
    """Hash function that treats strings case-insensitively."""
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        """Hash strings in case-insensitive manner."""
        # This is a simplified example - real implementation would
        # need proper string case conversion
        return UInt64(456)  # Placeholder for demo


fn example_basic_custom_hash():
    """Demonstrate basic custom hash function usage."""
    print("🔧 Basic Custom Hash Function:")
    print("=" * 40)
    
    # Create table with custom hash function
    var table = SwissTable[String, Int](SimpleHashFunction())
    
    # Use it like any other SwissTable
    _ = table.insert("hello", 42)
    _ = table.insert("world", 100)
    
    var result = table.lookup("hello")
    if result:
        print("  Found value: " + String(result.value()))
    
    print("  Table size: " + String(table.size()))
    print("✅ Custom hash function works!")
    print()


fn example_specialized_hash_use_cases():
    """Show when custom hash functions are useful."""
    print("🎯 Specialized Hash Function Use Cases:")
    print("=" * 40)
    
    print("1. Case-insensitive string lookups:")
    var case_insensitive = SwissTable[String, String](CaseInsensitiveStringHash())
    _ = case_insensitive.insert("Hello", "greeting")
    # In real implementation, "hello" and "Hello" would hash the same
    print("   ✅ Useful for user input, configuration keys")
    
    print("2. Integer optimization:")
    var int_optimized = SwissTable[Int, String](IdentityHashFunction())
    _ = int_optimized.insert(12345, "value")
    print("   ✅ Useful when keys are well-distributed integers")
    
    print("3. Domain-specific hashing:")
    print("   ✅ Geographic coordinates, timestamps, UUIDs")
    print("   ✅ Custom object hashing based on specific fields")
    print()


fn example_hash_function_performance():
    """Demonstrate hash function performance considerations."""
    print("⚡ Hash Function Performance:")
    print("=" * 40)
    
    # Good: Use MojoHashFunction for general cases
    var standard_table = SwissTable[String, Int](MojoHashFunction())
    _ = standard_table.insert("performance_test", 1)
    print("✅ MojoHashFunction: Optimized for general use")
    
    # Caution: Simple hash functions can cause collisions
    var simple_table = SwissTable[String, Int](SimpleHashFunction())
    _ = simple_table.insert("collision_test", 2)
    print("⚠️  SimpleHashFunction: May cause hash collisions")
    
    print("\n💡 Hash Function Design Principles:")
    print("   • Fast computation (avoid expensive operations)")
    print("   • Good distribution (minimize collisions)")
    print("   • Deterministic (same input = same output)")
    print("   • Use all bits of the key")
    print()


fn example_debugging_hash_collisions():
    """Show how to debug hash collision issues."""
    print("🔍 Debugging Hash Collisions:")
    print("=" * 40)
    
    # Create table with collision-prone hash function
    var collision_table = SwissTable[String, Int](SimpleHashFunction())
    
    # Add multiple items (will all hash to same value)
    _ = collision_table.insert("key1", 1)
    _ = collision_table.insert("key2", 2)
    _ = collision_table.insert("key3", 3)
    
    print("  Items in table: " + String(collision_table.size()))
    print("  Capacity: " + String(collision_table.capacity()))
    
    # Check if all lookups still work despite collisions
    var lookup1 = collision_table.lookup("key1")
    var lookup2 = collision_table.lookup("key2") 
    var lookup3 = collision_table.lookup("key3")
    
    var all_found = lookup1 and lookup2 and lookup3
    if all_found:
        print("✅ SwissTable handles collisions correctly")
    else:
        print("❌ Collision handling issue detected")
    
    print("\n🛠️  Collision Debugging Tips:")
    print("   • Monitor table capacity vs size ratio")
    print("   • Test with diverse key sets")
    print("   • Measure lookup performance")
    print("   • Consider MojoHashFunction for production")
    print()


fn example_hash_function_testing():
    """Show how to test custom hash functions."""
    print("🧪 Testing Custom Hash Functions:")
    print("=" * 40)
    
    # Test hash function consistency
    var hasher = SimpleHashFunction()
    var hash1 = hasher.hash("test_key")
    var hash2 = hasher.hash("test_key")
    
    if hash1 == hash2:
        print("✅ Hash function is deterministic")
    else:
        print("❌ Hash function inconsistency detected!")
    
    # Test with different keys
    var hash_a = hasher.hash("keyA")
    var hash_b = hasher.hash("keyB")
    
    if hash_a == hash_b:
        print("⚠️  Potential collision detected (may be OK for demo)")
    else:
        print("✅ Different keys produce different hashes")
    
    print("\n📋 Hash Function Testing Checklist:")
    print("   • Deterministic output for same input")
    print("   • Different outputs for different inputs")
    print("   • Performance under load")
    print("   • Distribution quality with real data")
    print()


fn main():
    """Run all custom hash function examples."""
    print("🔑 SwissTable Custom Hash Functions Guide")
    print("=" * 50)
    print()
    
    example_basic_custom_hash()
    example_specialized_hash_use_cases()
    example_hash_function_performance()
    example_debugging_hash_collisions()
    example_hash_function_testing()
    
    print("🎯 Key Takeaways:")
    print("  • Use MojoHashFunction for most cases")
    print("  • Custom hash functions for specialized needs")
    print("  • Test hash functions thoroughly")
    print("  • Monitor collision rates in production")
    print("  • Good hash distribution is critical for performance")
    print()
    print("📚 See docs/performance-guide.md for hash function optimization")