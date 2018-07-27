def kind(unicode data):
    '''
    Returns the "kind" of the input string.

    Arguments
    ---------
    data : str
        String to query.

    Returns
    -------
    :class:`view393.Kind`
        E.g. ``Kind.ASCII`` if the ``all(ord(c) <= 0x7f for c in data)``.
    '''
    cdef int kind

    PyUnicode_READY(data)

    kind = PyUnicode_KIND(data)
    if kind is PyUnicode_1BYTE_KIND:
        if PyUnicode_IS_ASCII(data):
            return Kind.ASCII
        else:
            return Kind.UCS1
    elif kind is PyUnicode_2BYTE_KIND:
        return Kind.UCS2
    elif kind is PyUnicode_4BYTE_KIND:
        return Kind.UCS4
    else:
        raise SystemError  # impossible


def view(unicode data, *, boolean chars=False):
    '''
    Returns a memoryview of the input string.

    Arguments
    ---------
    data : str
        String to observe.
    chars : bool
        If the argument is truthy, then the result is casted to format ``"B"``.

    Returns
    -------
    memoryview
        A contiguous, readonly view on the string in native byte-order.
    '''
    cdef Py_buffer info
    cdef int kind
    cdef object result
    cdef Buffer *result_view

    PyUnicode_READY(data)

    kind = PyUnicode_KIND(data)

    info.buf = PyUnicode_DATA(data)
    info.internal = NULL
    info.len = PyUnicode_GET_LENGTH(data)
    info.ndim = 1
    info.readonly = True
    info.shape = &info.len
    info.strides = &info.itemsize
    info.suboffsets = NULL

    kind = PyUnicode_KIND(data)
    if kind is PyUnicode_1BYTE_KIND:
        info.itemsize = 1
        info.format = 'B'
    elif kind is PyUnicode_2BYTE_KIND:
        info.itemsize = 2
        info.format = 'H'
    elif kind is PyUnicode_4BYTE_KIND:
        info.itemsize = 4
        info.format = 'I'
    else:
        raise SystemError  # impossible

    if chars:
        info.len *= info.itemsize
        info.itemsize = 1
        info.format = 'B'

    result = PyMemoryView_FromBuffer(&info)

    result_view = <Buffer*> PyMemoryView_GET_BUFFER(result)
    result_view.obj = <PyObject*> data
    Py_INCREF(result_view.obj)

    return result


def utf8(unicode data):
    '''
    Returns a memoryview of the UTF-8 representation of the input string.

    Calling this function multiple times will return different memoryview object,
    but the observed buffer is the same, possibly reducing overhead compared to
    ``str.encode("UTF-8")`` which generates unrelated ``bytes`` objects.

    Arguments
    ---------
    data : str
        String to observe.

    Returns
    -------
    memoryview
        A contiguous, readonly view on the string encoded as UTF-8.
    '''
    cdef Py_buffer view
    cdef object result
    cdef Buffer *result_view

    view.buf = PyUnicode_AsUTF8AndSize(data, &view.len)
    view.itemsize = 1
    view.readonly = True
    view.ndim = 1
    view.format = 'B'
    view.shape = &view.len
    view.strides = &view.itemsize
    view.suboffsets = NULL
    view.internal = NULL

    result = PyMemoryView_FromBuffer(&view)

    result_view = <Buffer*> PyMemoryView_GET_BUFFER(result)
    result_view.obj = <PyObject*> data
    Py_INCREF(result_view.obj)

    return result
