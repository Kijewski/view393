cdef Py_ssize_t kinds_todo = 4
cdef Kind ASCII, UCS1, UCS2, UCS4


def _get_kind(int index):
    cdef object result
    if index == 0:
        result = ASCII
    elif index == 1:
        result = UCS1
    elif index == 2:
        result = UCS2
    elif index == 4:
        result = UCS4
    else:
        result = None
    return result


@final
@no_gc
@auto_pickle(False)
cdef class Kind:
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


ASCII = Kind.ASCII
UCS1 = Kind.UCS1
UCS2 = Kind.UCS2
UCS4 = Kind.UCS4
