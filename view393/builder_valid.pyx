cdef Py_ssize_t builder_valid_todo = 6
cdef BuilderValid VALID, EMPTY, ALWAYS, RANGE_EXCEEDED, RANGE_UNUSED, NEVER


def _get_builder_valid(int index):
    cdef object result
    if index == 0:
        result = VALID
    elif index == 1:
        result = EMPTY
    elif index == 2:
        result = ALWAYS
    elif index == 3:
        result = RANGE_EXCEEDED
    elif index == 4:
        result = RANGE_UNUSED
    elif index == 5:
        result = NEVER
    else:
        result = None
    return result


@final
@no_gc
@auto_pickle(False)
cdef class BuilderValid:
    def __cinit__(BuilderValid self, PythonInt index, boolean truthy, str name):
        global builder_valid_todo
        if builder_valid_todo <= 0:
            raise Exception('You cannot create more BuilderValid')
        builder_valid_todo -= 1

        self.truthy = truthy
        self.name = name

        self.__reduced = _get_builder_valid, (index,)

    def __reduce__(BuilderValid self):
        return self.__reduced

    def __str__(BuilderValid self):
        return self.name

    def __repr__(BuilderValid self):
        return '<BuilderValid name=%s truthy=%s>' % (self.name, u'True' if self.truthy else u'False')

    def __nonzero__(BuilderValid self):
        return self.truthy

    VALID = BuilderValid(0, True, 'VALID')
    EMPTY  = BuilderValid(1, True, 'EMPTY')
    ALWAYS  = BuilderValid(2, True, 'ALWAYS')
    RANGE_EXCEEDED  = BuilderValid(3, False, 'RANGE_EXCEEDED')
    RANGE_UNUSED  = BuilderValid(4, False, 'RANGE_UNUSED')
    NEVER  = BuilderValid(5, False, 'NEVER')


VALID = BuilderValid.VALID
EMPTY = BuilderValid.EMPTY
ALWAYS = BuilderValid.ALWAYS
RANGE_EXCEEDED = BuilderValid.RANGE_EXCEEDED
RANGE_UNUSED = BuilderValid.RANGE_UNUSED
NEVER = BuilderValid.NEVER
