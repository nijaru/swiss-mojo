"""Data structures for Swiss table implementation.

Common structures used by SwissTable implementation.
"""

from collections import KeyElement


struct DictEntry[K: KeyElement, V: Copyable & Movable](Movable, Copyable):
    """Key-value entry for Swiss table storage."""
    var key: K
    var value: V

    fn __init__(out self, owned key: K, owned value: V):
        self.key = key^
        self.value = value^

    fn __copyinit__(out self, existing: Self):
        self.key = existing.key
        self.value = existing.value