# distutils: language = c++
# cython: embedsignature = True, language_level = 3

from cpython cimport int as PythonInt
from cython cimport final, no_gc, auto_pickle, internal
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t
from libcpp cimport bool as boolean


ctypedef Py_ssize_t GetFn(void *ptr) nogil
ctypedef void SetFn(void *ptr, Py_ssize_t value) nogil


cpdef Kind kind(unicode data)
cpdef view(unicode data, boolean chars=?)
cpdef utf8(unicode data)


@final
@no_gc
@auto_pickle(False)
cdef class Kind:
    '''
    An enum to describe the "kind" of an ``str()``.

    Enum members:

    * **ASCII:** the string only contains US-ASCII data. (This includes the empty string.)the string only contains US-ASCII data. (This includes the empty string.)
    * **UCS1:** the string contains some characters that are not representable in ASCII, but all characters are in Latin-1.
    * **UCS2:** the string contains some characters that are not representable in Latin-1, but all characters are in the Basic Multilingual Plane.
    * **UCS4:** the string contains some characters outside the Basic Multilingual Plane.
    '''

    cdef readonly PythonInt size
    '''The itemsize of a single character. E.g. ``Kind.UCS4.size == 4``.'''

    cdef readonly str format
    '''The applicable :mod:`struct` format. E.g. ``Kind.UCS4.format == "I"``.'''

    cdef readonly str name
    '''The name of this enum value. E.g. ``Kind.UCS4.name == "UCS4"``.'''

    cdef object __reduced


@final
@no_gc
@auto_pickle(False)
cdef class BuilderValid:
    '''
    An enum to describe whether the current state of an :class:`InplaceBuilder` is valid.

    Enum members:

    * **VALID:** The contained string is sane. (``bool(VALID) == True``)
    * **EMPTY:** The builder is empty. That's fine. (``bool(EMPTY) == True``)
    * **ALWAYS:** The contained string cannot be not valid, only empty. (``bool(ALWAYS) == True``)
    * **RANGE_EXCEEDED:** The contained string includes characters that are outside of the valid range. (``bool(RANGE_EXCEEDED) == False``)
    * **RANGE_UNUSED:** The contained string does not contain characters that use the builder's range, e.g. there are only ASCII characters in a :class:`Ucs1Builder`. (``bool(RANGE_UNUSED) == False``)
    * **NEVER:** You instanciated a base class. That cannot work.
    '''

    cdef readonly str name
    '''The name of this enum value. E.g. ``BuilderValid.ALWAYS.name == "ALWAYS"``.'''

    cdef boolean truthy
    '''Whether the outcome is valid: ``v.thruthy == bool(v)``'''

    cdef object __reduced


@auto_pickle(False)
cdef class InplaceBuilder:
    '''Base class of all str/bytes builders.'''

    cdef void *memory

    cdef readonly Py_ssize_t capacity
    '''Size of the memory before the object needs to grow.'''

    cdef readonly Py_ssize_t offset
    '''Amount of data written to the buffer. Always <= capacity.'''

    cdef readonly Py_ssize_t memoryviews
    '''
    Number of currently open :class:`~memoryview` objects.

    Growing, shrinking or releasing the buffer won't work while there are open memoryviews!
    '''

    cdef readonly Py_ssize_t itemsize
    '''Size of a single character.'''

    cdef readonly char *format
    ''':mod:`~struct`-like format of the data.'''

    cdef GetFn *_get
    cdef SetFn *_set

    cpdef resize(InplaceBuilder self, Py_ssize_t amount)
    cpdef Py_ssize_t incr_size(InplaceBuilder self, Py_ssize_t amount)

    @final
    cdef void *_index_addr(InplaceBuilder self, Py_ssize_t index) except NULL


@final
@auto_pickle(False)
cdef class AsciiBuilder(InplaceBuilder):
    '''
    A helper class to create an :class:`~str` object that only contain ASCII data (U+0000 to U+007F).
    '''
    cpdef unicode release(AsciiBuilder self)
    cpdef BuilderValid valid(AsciiBuilder self)


@auto_pickle(False)
cdef class CompactUnicodeBuilder(InplaceBuilder):
    cdef unicode _release(CompactUnicodeBuilder self)


@final
@auto_pickle(False)
cdef class Ucs1Builder(CompactUnicodeBuilder):
    '''
    A helper class to create an :class:`~str` object that contain Latin1 data (U+0000 to U+00FF).
    '''
    cpdef unicode release(Ucs1Builder self)
    cpdef BuilderValid valid(Ucs1Builder self)


@final
@auto_pickle(False)
cdef class Ucs2Builder(CompactUnicodeBuilder):
    '''
    A helper class to create an :class:`~str` object that contain UCS2 data (U+0000 to U+FFFF).
    '''
    cpdef unicode release(Ucs2Builder self)
    cpdef BuilderValid valid(Ucs2Builder self)


@final
@auto_pickle(False)
cdef class Ucs4Builder(CompactUnicodeBuilder):
    '''
    A helper class to create an :class:`~str` object that contain UCS4 data (U+0000 to U+10FFFF).
    '''
    cpdef unicode release(Ucs4Builder self)
    cpdef BuilderValid valid(Ucs4Builder self)


@final
@auto_pickle(False)
cdef class BytesBuilder(InplaceBuilder):
    '''
    A helper class to create an :class:`~bytes` object.
    '''
    cpdef bytes release(BytesBuilder self)
    cpdef BuilderValid valid(BytesBuilder self)
