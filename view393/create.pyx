cdef Py_ssize_t START_ASCII = (<Py_ssize_t> <void*> &(<AsciiUnicodeObject*> NULL).data[0])
cdef Py_ssize_t START_COMPACT = (<Py_ssize_t> <void*> &(<CompactUnicodeObject*> NULL).data[0])
cdef Py_ssize_t START_BYTES = (<Py_ssize_t> <void*> &(<PyBytesObject*> NULL).ob_sval[0])

cdef unicode EMPTY_UNICODE = u''
cdef bytes EMPTY_BYTES = b''


cdef void _set1(void *ptr, Py_ssize_t value) nogil:
    (<uint8_t*> ptr)[0] = <uint8_t> value


cdef Py_ssize_t _get1(void *ptr) nogil:
    return (<uint8_t*> ptr)[0]


cdef void _set2(void *ptr, Py_ssize_t value) nogil:
    (<uint16_t*> ptr)[0] = <uint16_t> value


cdef Py_ssize_t _get2(void *ptr) nogil:
    return (<uint16_t*> ptr)[0]


cdef void _set4(void *ptr, Py_ssize_t value) nogil:
    (<uint32_t*> ptr)[0] = <uint32_t> value


cdef Py_ssize_t _get4(void *ptr) nogil:
    return (<uint32_t*> ptr)[0]


@auto_pickle(False)
cdef class InplaceBuilder:
    def __cinit__(InplaceBuilder self):
        self.memory = NULL
        self.capacity = 0
        self.memoryviews = 0
        self.offset = 0
        self.itemsize = 0
        self.format = NULL
        self._get = _get1
        self._set = _set1

    def __dealloc__(InplaceBuilder self):
        cdef void *memory = self.memory
        self.memory = NULL
        if memory is not NULL:
            ObjectRealloc(memory, 0)

    cpdef resize(InplaceBuilder self, Py_ssize_t amount):
        '''
        Resize the buffer to ``amount`` characters.

        Arguments
        ---------
        amount : int
            New size of the buffer. Clear buffer if <=0.
        '''
        cdef void *new_ptr
        cdef Py_ssize_t alloc_n

        if self.memoryviews > 0:
            raise Exception('Cannot resize object if it has open memoryviews.')

        if amount < 0:
            amount = 0

        if amount == self.capacity:
            return

        alloc_n = self.offset + amount * self.itemsize
        if alloc_n <= amount:
            ErrNoMemory()

        new_ptr = ObjectRealloc(self.memory, alloc_n)
        if not new_ptr:
            ErrNoMemory()

        self.memory = new_ptr
        self.capacity = amount

    cpdef Py_ssize_t incr_size(InplaceBuilder self, Py_ssize_t amount):
        '''
        Resize the buffer by ``amount`` characters.

        Arguments
        ---------
        amount : int
            Amount of charactes to grow or shrink the buffer

        Returns
        -------
        int
            New size of the buffer in characters.
        '''
        cdef Py_ssize_t new_amount = self.capacity + amount

        if amount != 0:
            if (
                ((new_amount > 0) and (new_amount < self.capacity)) or
                ((new_amount < 0) and (new_amount > self.capacity))
            ):
                ErrNoMemory()

            self.resize(new_amount)

        return new_amount

    def __getbuffer__(InplaceBuilder self, Py_buffer *info, int flags):
        info.buf = (<char*> self.memory) + self.offset
        info.format = self.format
        info.internal = NULL
        info.itemsize = self.itemsize
        info.len = self.capacity
        info.ndim = 1
        info.obj = self
        info.readonly = 0
        info.shape = &info.len
        info.strides = &info.itemsize
        info.suboffsets = NULL

        self.memoryviews += 1

    def __releasebuffer__(InplaceBuilder self, Py_buffer *info):
        self.memoryviews -= 1

    @final
    cdef void *_index_addr(InplaceBuilder self, Py_ssize_t index) except NULL:
        if index < 0:
            index += self.capacity

        if not (0 <= index < self.capacity):
            raise IndexError

        return (<char*> self.memory) + self.offset + (index * self.itemsize)

    def __getitem__(InplaceBuilder self, index):
        if not PySlice_Check(index):
            return self._get(self._index_addr(index))
        else:
            return PyObject_GetItem(PyMemoryView_FromObject(self), index)

    def __setitem__(InplaceBuilder self, index, value):
        cdef Py_ssize_t int_value
        if not PySlice_Check(index):
            if isinstance(value, (unicode, bytes)):
                int_value = ord(value)
            else:
                int_value = PyLong_AsUnsignedLongMask(value)
            self._set(self._index_addr(index), int_value)
        else:
            PyObject_SetItem(PyMemoryView_FromObject(self), index, value)


@final
@auto_pickle(False)
cdef class AsciiBuilder(InplaceBuilder):
    def __cinit__(AsciiBuilder self):
        self.offset = START_ASCII
        self.itemsize = 1
        self.format = b'B'

    cpdef unicode release(AsciiBuilder self):
        '''
        Finish the string creation and return the :class:`~str`.

        Warning
        -------
            This function does not check the validility of the buffer.
            If the buffer is not valid, then there may be errors in functions using this string.

            Test :func:`~AsciiBuilder.valid()` if you want to make sure that the data is sane.

        Returns
        -------
        str
            The created ASCII string
        '''
        cdef object result
        cdef Py_ssize_t length
        cdef PyASCIIObject *ascii

        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_UNICODE

        (<char*> self.memory)[START_ASCII + self.capacity] = 0

        length = self.capacity
        result = ObjectInit(<PyObject*> self.memory, unicode)
        ascii = <PyASCIIObject*> result
        self.memory = NULL
        self.capacity = 0

        ascii.length = length
        ascii.hash = -1
        ascii.wstr = NULL
        ascii.state.interned = SSTATE_NOT_INTERNED
        ascii.state.kind = PyUnicode_1BYTE_KIND
        ascii.state.compact = True
        ascii.state.ready = True
        ascii.state.ascii = True

        return result

    cpdef BuilderValid valid(AsciiBuilder self):
        '''
        A :class:`~AsciiBuilder` buffer is valid if it is empty or no data is `>0x7F`.
        '''
        cdef uint8_t *pos = (<uint8_t*> self.memory) + START_ASCII
        cdef Py_ssize_t index
        cdef uint8_t value

        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY

        for index in range(self.capacity):
            value = pos[index]
            if value >= 0x80:
                return RANGE_EXCEEDED

        return VALID


@auto_pickle(False)
cdef class CompactUnicodeBuilder(InplaceBuilder):
    def __cinit__(CompactUnicodeBuilder self):
        self.offset = START_COMPACT

    cdef unicode _release(CompactUnicodeBuilder self):
        cdef object result
        cdef Py_ssize_t length = self.capacity

        self._set((<char*> self.memory) + self.offset + length, 0)

        result = ObjectInit(<PyObject*> self.memory, unicode)

        self.memory = NULL
        self.capacity = 0

        (<PyASCIIObject*> result).length = length
        (<PyASCIIObject*> result).hash = -1
        (<PyASCIIObject*> result).wstr = NULL
        (<PyASCIIObject*> result).state.interned = SSTATE_NOT_INTERNED
        (<PyASCIIObject*> result).state.kind = 0
        (<PyASCIIObject*> result).state.compact = True
        (<PyASCIIObject*> result).state.ready = True
        (<PyASCIIObject*> result).state.ascii = False

        (<PyCompactUnicodeObject*> result).utf8_length = 0
        (<PyCompactUnicodeObject*> result).utf8 = NULL
        (<PyCompactUnicodeObject*> result).wstr_length = 0

        return result


@final
@auto_pickle(False)
cdef class Ucs1Builder(CompactUnicodeBuilder):
    def __cinit__(Ucs1Builder self):
        self.itemsize = 1
        self.format = b'B'

    cpdef unicode release(Ucs1Builder self):
        '''
        Finish the string creation and return the :class:`~str` object.

        Warning
        -------
            This function does not check the validility of the buffer.
            If the buffer is not valid, then there may be errors in functions using this string.

            Test :func:`~Ucs1Builder.valid()` if you want to make sure that the data is sane.

        Returns
        -------
        str
            The created Latin-1 string
        '''
        cdef object result
        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_UNICODE

        result = self._release()
        (<PyASCIIObject*> result).state.kind = PyUnicode_1BYTE_KIND

        return result

    cpdef BuilderValid valid(Ucs1Builder self):
        '''
        A :class:`~Ucs1Builder` buffer is valid if it is empty or some data is `>0x7F`.
        '''
        cdef Py_UCS1 *pos = <Py_UCS1*> ((<uint8_t*> self.memory) + START_ASCII)
        cdef Py_ssize_t index

        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY

        for index in range(self.capacity):
            if pos[index] >= 0x80:
                return VALID

        return RANGE_UNUSED


@final
@auto_pickle(False)
cdef class Ucs2Builder(CompactUnicodeBuilder):
    def __cinit__(Ucs2Builder self):
        self.itemsize = 2
        self.format = b'H'
        self._get = _get2
        self._set = _set2

    cpdef unicode release(Ucs2Builder self):
        '''
        Finish the string creation and return the :class:`~str` object.

        Warning
        -------
            This function does not check the validility of the buffer.
            If the buffer is not valid, then there may be errors in functions using this string.

            Test :func:`~Ucs2Builder.valid()` if you want to make sure that the data is sane.

        Returns
        -------
        str
            The created UCS-2 string
        '''
        cdef object result
        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_UNICODE

        result = self._release()
        (<PyASCIIObject*> result).state.kind = PyUnicode_2BYTE_KIND

        return result

    cpdef BuilderValid valid(Ucs2Builder self):
        '''
        A :class:`~Ucs2Builder` buffer is valid if it is empty or some data is `>0xFF`.
        '''
        cdef Py_UCS2 *pos = <Py_UCS2*> ((<uint8_t*> self.memory) + START_ASCII)
        cdef Py_ssize_t index

        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY

        for index in range(self.capacity):
            if pos[index] >= 0x100:
                return VALID

        return RANGE_UNUSED


@final
@auto_pickle(False)
cdef class Ucs4Builder(CompactUnicodeBuilder):
    def __cinit__(Ucs4Builder self):
        self.itemsize = 4
        self.format = b'I'
        self._get = _get4
        self._set = _set4

    cpdef unicode release(Ucs4Builder self):
        '''
        Finish the string creation and return the :class:`~str` object.

        Warning
        -------
            This function does not check the validility of the buffer.
            If the buffer is not valid, then there may be errors in functions using this string.

            Test :func:`~Ucs4Builder.valid()` if you want to make sure that the data is sane.

        Returns
        -------
        str
            The created UCS-4 string
        '''
        cdef object result
        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_UNICODE

        result = self._release()
        (<PyASCIIObject*> result).state.kind = PyUnicode_4BYTE_KIND

        return result

    cpdef BuilderValid valid(Ucs4Builder self):
        '''
        A :class:`~Ucs4Builder` buffer is valid if it is empty or no data is `>0x10_FFFF` and some data is `>0xFFFF`.
        '''
        cdef Py_UCS4 *pos = <Py_UCS4*> ((<uint8_t*> self.memory) + START_ASCII)
        cdef Py_ssize_t index

        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY

        for index in range(self.capacity):
            if pos[index] >= 0x1_0000:
                break
        else:
            return RANGE_UNUSED

        for index in range(index, self.capacity):
            if pos[index] >= 0x11_0000:
                return RANGE_EXCEEDED
        else:
            return VALID


@final
@auto_pickle(False)
cdef class BytesBuilder(InplaceBuilder):
    def __cinit__(BytesBuilder self):
        self.offset = START_BYTES
        self.itemsize = 1
        self.format = b'B'

    cpdef bytes release(BytesBuilder self):
        '''
        Finish the bytes creation and return the :class:`~bytes` object.

        Returns
        -------
        bytes
            The created string.
        '''
        cdef object result
        cdef Py_ssize_t length = self.capacity

        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_BYTES

        (<char*> self.memory)[START_BYTES + self.capacity] = 0

        result = <object> <PyObject*> ObjectInitVar(<PyVarObject *> self.memory, bytes, length)

        self.memory = NULL
        self.capacity = 0

        (<PyBytesObject*> result).ob_shash = -1

        return result

    cpdef BuilderValid valid(BytesBuilder self):
        '''
        There is no need to test if a :class:`~BytesBuilder` buffer is valid. It is always valid.
        '''
        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY
        else:
            return ALWAYS
