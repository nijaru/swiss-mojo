"""Iterator support for SwissTable.

Provides keys(), values(), and items() iteration functionality
with proper Mojo iterator protocols.
"""

from collections import KeyElement
from memory import UnsafePointer
from builtin.len import Sized
from .data_structures import DictEntry
from .hash import is_full


struct SwissTableKeyIterator[K: KeyElement, V: Copyable & Movable](Sized, Copyable):
    """Iterator over SwissTable keys."""
    
    var _control_bytes: UnsafePointer[UInt8]
    var _slots: UnsafePointer[DictEntry[K, V]]
    var _capacity: Int
    var _current_index: Int
    var _size: Int
    var _items_yielded: Int
    
    fn __init__(out self, control_bytes: UnsafePointer[UInt8], 
                slots: UnsafePointer[DictEntry[K, V]], 
                capacity: Int, size: Int):
        """Initialize key iterator."""
        self._control_bytes = control_bytes
        self._slots = slots
        self._capacity = capacity
        self._current_index = 0
        self._size = size
        self._items_yielded = 0
    
    fn __copyinit__(out self, existing: Self):
        """Copy constructor."""
        self._control_bytes = existing._control_bytes
        self._slots = existing._slots
        self._capacity = existing._capacity
        self._current_index = existing._current_index
        self._size = existing._size
        self._items_yielded = existing._items_yielded
    
    fn __iter__(self) -> Self:
        """Return self as iterator."""
        return self
    
    fn __next__(mut self) raises -> K:
        """Get next key."""
        if self._items_yielded >= self._size:
            raise Error("StopIteration")
        
        # Find next occupied slot
        while self._current_index < self._capacity:
            var ctrl = self._control_bytes[self._current_index]
            if is_full(ctrl):
                var entry = self._slots[self._current_index]
                self._current_index += 1
                self._items_yielded += 1
                return entry.key
            self._current_index += 1
        
        # Should not reach here if size is correct
        raise Error("StopIteration")
    
    fn __len__(self) -> Int:
        """Return number of remaining items."""
        return self._size - self._items_yielded


struct SwissTableValueIterator[K: KeyElement, V: Copyable & Movable](Sized, Copyable):
    """Iterator over SwissTable values."""
    
    var _control_bytes: UnsafePointer[UInt8]
    var _slots: UnsafePointer[DictEntry[K, V]]
    var _capacity: Int
    var _current_index: Int
    var _size: Int
    var _items_yielded: Int
    
    fn __init__(out self, control_bytes: UnsafePointer[UInt8], 
                slots: UnsafePointer[DictEntry[K, V]], 
                capacity: Int, size: Int):
        """Initialize value iterator."""
        self._control_bytes = control_bytes
        self._slots = slots
        self._capacity = capacity
        self._current_index = 0
        self._size = size
        self._items_yielded = 0
    
    fn __copyinit__(out self, existing: Self):
        """Copy constructor."""
        self._control_bytes = existing._control_bytes
        self._slots = existing._slots
        self._capacity = existing._capacity
        self._current_index = existing._current_index
        self._size = existing._size
        self._items_yielded = existing._items_yielded
    
    fn __iter__(self) -> Self:
        """Return self as iterator."""
        return self
    
    fn __next__(mut self) raises -> V:
        """Get next value."""
        if self._items_yielded >= self._size:
            raise Error("StopIteration")
        
        # Find next occupied slot
        while self._current_index < self._capacity:
            var ctrl = self._control_bytes[self._current_index]
            if is_full(ctrl):
                var entry = self._slots[self._current_index]
                self._current_index += 1
                self._items_yielded += 1
                return entry.value
            self._current_index += 1
        
        # Should not reach here if size is correct
        raise Error("StopIteration")
    
    fn __len__(self) -> Int:
        """Return number of remaining items."""
        return self._size - self._items_yielded


struct SwissTableItemIterator[K: KeyElement, V: Copyable & Movable](Sized, Copyable):
    """Iterator over SwissTable key-value pairs."""
    
    var _control_bytes: UnsafePointer[UInt8]
    var _slots: UnsafePointer[DictEntry[K, V]]
    var _capacity: Int
    var _current_index: Int
    var _size: Int
    var _items_yielded: Int
    
    fn __init__(out self, control_bytes: UnsafePointer[UInt8], 
                slots: UnsafePointer[DictEntry[K, V]], 
                capacity: Int, size: Int):
        """Initialize item iterator."""
        self._control_bytes = control_bytes
        self._slots = slots
        self._capacity = capacity
        self._current_index = 0
        self._size = size
        self._items_yielded = 0
    
    fn __copyinit__(out self, existing: Self):
        """Copy constructor."""
        self._control_bytes = existing._control_bytes
        self._slots = existing._slots
        self._capacity = existing._capacity
        self._current_index = existing._current_index
        self._size = existing._size
        self._items_yielded = existing._items_yielded
    
    fn __iter__(self) -> Self:
        """Return self as iterator."""
        return self
    
    fn __next__(mut self) raises -> DictEntry[K, V]:
        """Get next key-value pair."""
        if self._items_yielded >= self._size:
            raise Error("StopIteration")
        
        # Find next occupied slot
        while self._current_index < self._capacity:
            var ctrl = self._control_bytes[self._current_index]
            if is_full(ctrl):
                var entry = self._slots[self._current_index]
                self._current_index += 1
                self._items_yielded += 1
                return entry
            self._current_index += 1
        
        # Should not reach here if size is correct
        raise Error("StopIteration")
    
    fn __len__(self) -> Int:
        """Return number of remaining items."""
        return self._size - self._items_yielded