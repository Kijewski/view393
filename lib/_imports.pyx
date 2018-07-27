from cpython cimport Py_buffer, PyObject, int as PythonInt
from cpython.long cimport PyLong_AsUnsignedLongMask
from cython cimport final, no_gc, auto_pickle
from libcpp cimport bool as boolean


cdef extern from 'native.hpp' namespace 'View393' nogil:
    const char VERSION[]
    const char LONGDESCRIPTION[]
    enum:
        VERSION_LENGTH
        LONGDESCRIPTION_LENGTH

    ctypedef boolean AlwaysTrue


cdef extern from '<cstddef>' namespace 'std' nogil:
    ctypedef unsigned long size_t


cdef extern from '<cstdint>' namespace 'std' nogil:
    ctypedef unsigned char uint8_t
    ctypedef unsigned short uint16_t
    ctypedef unsigned long uint32_t
    ctypedef unsigned long long uint64_t

    ctypedef signed char int8_t
    ctypedef signed short int16_t
    ctypedef signed long int32_t
    ctypedef signed long long int64_t


cdef extern from 'Python.h':
    enum:
        PyUnicode_1BYTE_KIND
        PyUnicode_2BYTE_KIND
        PyUnicode_4BYTE_KIND

    enum:
        SSTATE_NOT_INTERNED
        SSTATE_INTERNED_MORTAL
        SSTATE_INTERNED_IMMORTAL

    ctypedef uint8_t Py_UCS1
    ctypedef uint16_t Py_UCS2
    ctypedef uint32_t Py_UCS4

    ctypedef signed long Py_hash
    ctypedef signed short wchar_t

    ctypedef struct Buffer 'Py_buffer':
        PyObject *obj

    ctypedef struct __ascii_object_state:
        uint8_t interned
        uint8_t kind
        boolean compact
        boolean ascii
        boolean ready

    ctypedef struct PyASCIIObject:
        Py_ssize_t length
        Py_hash hash
        wchar_t *wstr
        __ascii_object_state state

    ctypedef struct PyCompactUnicodeObject:
        Py_ssize_t utf8_length
        char *utf8
        Py_ssize_t wstr_length

    ctypedef struct PyVarObject:
        pass

    ctypedef struct PyBytesObject:
        PyVarObject ob_base
        Py_hash ob_shash
        char ob_sval[1]

    int PyUnicode_READY(object o) except -1
    Py_ssize_t PyUnicode_GET_LENGTH(object o) nogil
    int PyUnicode_KIND(object o) nogil
    boolean PyUnicode_IS_ASCII(object) nogil
    void *PyUnicode_DATA(object o) nogil
    const char *PyUnicode_AsUTF8AndSize(object obj, Py_ssize_t *size)
    object PyUnicode_FromKindAndData(int kind, const void *buf, Py_ssize_t size)
    object PyMemoryView_FromBuffer(Py_buffer *view)
    Py_buffer *PyMemoryView_GET_BUFFER(object op)
    AlwaysTrue ErrNoMemory 'PyErr_NoMemory'() except True
    void Py_INCREF(PyObject *o)
    boolean PySlice_Check(object ob)
    Py_ssize_t PySlice_AdjustIndices(Py_ssize_t length, Py_ssize_t *start, Py_ssize_t *stop, Py_ssize_t step)
    int PySlice_Unpack(object slice, Py_ssize_t *start, Py_ssize_t *stop, Py_ssize_t *step) except -1
    object PyMemoryView_FromObject(object)
    object PyObject_GetItem(object, object)
    int PyObject_SetItem(object, object, object) except -1

    void *ObjectRealloc 'PyObject_Realloc'(void *p, size_t n)
    object ObjectInit 'PyObject_INIT'(PyObject *obj, type cls)
    PyVarObject *ObjectInitVar 'PyObject_InitVar'(PyVarObject *obj, type cls, Py_ssize_t size) except NULL


ctypedef struct AsciiUnicodeObject:
    PyASCIIObject base
    char data[1]


ctypedef struct CompactUnicodeObject:
    PyCompactUnicodeObject base
    char data[1]
