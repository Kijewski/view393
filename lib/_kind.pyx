cdef Py_ssize_t kinds_todo = 4


def _get_kind(int index):
    cdef object result
    if index == 0:
        result = Kind.ASCII
    elif index == 1:
        result = Kind.UCS1
    elif index == 2:
        result = Kind.UCS2
    elif index == 4:
        result = Kind.UCS4
    else:
        result = None
    return result


@final
@no_gc
@auto_pickle(False)
cdef class Kind:
    '''
    A enum to describe the "kind" of an ``str()``.

    Enum members:

    * **ASCII:** the string only contains US-ASCII data. (This includes the empty string.)the string only contains US-ASCII data. (This includes the empty string.)
    * **UCS1:** the string contains some characters that are not representable in ASCII, but all characters are in Latin-1.
    * **UCS2:** the string contains some characters that are not representable in Latin-1, but all characters are in the Basic Multilingual Plane.
    * **UCS4:** the string contains some characters outside the Basic Multilingual Plane.
    '''

    cdef readonly PythonInt size
    '''The itemsize of a single character. E.g. ``Kind.UCS4.size == 4``.'''

    cdef readonly str format
    '''The applicable :mod:`struct` format. E.g. ``Kind.UCS4.size == "I"``.'''

    cdef readonly str name
    '''The name of this enum value. E.g. ``Kind.UCS4.size == "UCS4"``.'''

    cdef object __reduced

    def __cinit__(Kind self, PythonInt index, PythonInt size, str format, str name):
        global kinds_todo
        if kinds_todo <= 0:
            raise Exception('You cannot create more Kinds')
        kinds_todo -= 1

        self.size = size
        self.format = format
        self.name = name

        self.__reduced = _get_kind, (index,)

    def __reduce__(Kind self):
        return self.__reduced

    def __str__(Kind self):
        return self.name

    def __repr__(Kind self):
        return '<Kind name=%s size=%d>' % (self.name, self.size)

    ASCII = Kind(0, 1, 'B', 'ASCII')
    UCS1  = Kind(1, 1, 'B', 'UCS1')
    UCS2  = Kind(2, 2, 'H', 'UCS2')
    UCS4  = Kind(4, 4, 'I', 'UCS4')
