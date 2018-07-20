from cpython cimport Py_buffer, PyObject, int as PythonInt
from cython cimport final, no_gc, auto_pickle
from libcpp cimport bool as boolean


cdef extern from 'native.hpp' namespace 'View393' nogil:
    const char VERSION[]
    const char LONGDESCRIPTION[]
    enum:
        VERSION_LENGTH
        LONGDESCRIPTION_LENGTH


cdef extern from 'Python.h':
    enum:
        PyUnicode_1BYTE_KIND
        PyUnicode_2BYTE_KIND
        PyUnicode_4BYTE_KIND

    int PyUnicode_READY(object o) except -1
    Py_ssize_t PyUnicode_GET_LENGTH(object o) nogil
    int PyUnicode_KIND(object o) nogil
    boolean PyUnicode_IS_ASCII(object) nogil
    void *PyUnicode_DATA(object o) nogil
    const char *PyUnicode_AsUTF8AndSize(object obj, Py_ssize_t *size)
    object PyUnicode_FromKindAndData(int kind, const void *buf, Py_ssize_t size)

    object PyMemoryView_FromBuffer(Py_buffer *view)
    Py_buffer *PyMemoryView_GET_BUFFER(object op)

    void Py_INCREF(PyObject *o)

    ctypedef struct Buffer 'Py_buffer':
        PyObject *obj
