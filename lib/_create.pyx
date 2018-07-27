cdef Py_ssize_t START_ASCII = (<Py_ssize_t> <void*> &(<AsciiUnicodeObject*> NULL).data[0])
cdef Py_ssize_t START_COMPACT = (<Py_ssize_t> <void*> &(<CompactUnicodeObject*> NULL).data[0])
cdef Py_ssize_t START_BYTES = (<Py_ssize_t> <void*> &(<PyBytesObject*> NULL).ob_sval[0])

cdef unicode EMPTY_UNICODE = u''
cdef bytes EMPTY_BYTES = b''


ctypedef Py_ssize_t GetFn(void *ptr)
ctypedef void SetFn(void *ptr, Py_ssize_t value)


@auto_pickle(False)
cdef class InplaceBuilder:
    cdef void *memory
    cdef readonly Py_ssize_t capacity
    cdef readonly Py_ssize_t memoryviews
    cdef readonly Py_ssize_t offset
    cdef readonly Py_ssize_t itemsize
    cdef readonly char *format
    cdef GetFn *_get
    cdef SetFn *_set

    def __cinit__(InplaceBuilder self):
        self.memory = NULL
        self.capacity = 0
        self.memoryviews = 0
        self.offset = 0
        self.itemsize = 0
        self.format = NULL
        self._get = InplaceBuilder.__get
        self._set = InplaceBuilder.__set

    def __dealloc__(InplaceBuilder self):
        cdef void *memory = self.memory
        self.memory = NULL
        if memory is not NULL:
            ObjectRealloc(memory, 0)

    cpdef resize(InplaceBuilder self, Py_ssize_t amount):
        cdef void *new_ptr
        cdef Py_ssize_t alloc_n

        if self.memoryviews > 0:
            raise Exception('Cannot resize object if it has open memoryviews.')

        if amount < 0:
            amount = 0

        if amount == self.capacity:
            return

        alloc_n = amount + self.offset + self.itemsize
        if alloc_n <= amount:
            ErrNoMemory()

        new_ptr = ObjectRealloc(self.memory, alloc_n)
        if not new_ptr:
            ErrNoMemory()

        self.memory = new_ptr
        self.capacity = amount

    cpdef incr_size(InplaceBuilder self, Py_ssize_t amount):
        cdef Py_ssize_t new_amount

        if amount == 0:
            return

        new_amount = self.capacity + amount
        if (
            ((new_amount > 0) and (new_amount < self.capacity)) or
            ((new_amount < 0) and (new_amount > self.capacity))
        ):
            ErrNoMemory()

        self.resize(new_amount)

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

    def release(InplaceBuilder self):
        raise NotImplementedError

    @final
    cdef void *_index_addr(InplaceBuilder self, Py_ssize_t index) except NULL:
        if index < 0:
            index += self.capacity

        if not (0 <= index < self.capacity):
            raise IndexError

        return (<char*> self.memory) + self.offset + (index * self.itemsize)

    @staticmethod
    cdef void __set(void *ptr, Py_ssize_t value):
        (<uint8_t*> ptr)[0] = <uint8_t> value

    @staticmethod
    cdef Py_ssize_t __get(void *ptr):
        return (<uint8_t*> ptr)[0]

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

    def is_invalid(InplaceBuilder self):
        return True


@auto_pickle(False)
cdef class AsciiBuilder(InplaceBuilder):
    def __cinit__(AsciiBuilder self):
        self.offset = START_ASCII
        self.itemsize = 1
        self.format = b'B'

    def release(AsciiBuilder self):
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

    def is_invalid(AsciiBuilder self):
        cdef uint8_t *pos = (<uint8_t*> self.memory) + START_ASCII
        cdef Py_ssize_t index
        cdef uint8_t value

        for index in range(self.capacity):
            value = pos[index]
            if value >= 0x80:
                return f'self[{index}] == {value} is out of ASCII range'

        return False


@auto_pickle(False)
cdef class CompactUnicodeBuilder(InplaceBuilder):
    def __cinit__(CompactUnicodeBuilder self):
        self.offset = START_COMPACT

    cdef _release(CompactUnicodeBuilder self):
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


@auto_pickle(False)
cdef class Ucs1Builder(CompactUnicodeBuilder):
    def __cinit__(Ucs1Builder self):
        self.itemsize = 1
        self.format = b'B'

    def release(Ucs1Builder self):
        cdef object result
        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_UNICODE

        result = self._release()
        (<PyASCIIObject*> result).state.kind = PyUnicode_1BYTE_KIND

        return result

    def is_invalid(Ucs1Builder self):
        cdef Py_UCS1 *pos = <Py_UCS1*> ((<uint8_t*> self.memory) + START_ASCII)
        cdef Py_ssize_t index

        if self.capacity <= 0:
            return False

        for index in range(self.capacity):
            if pos[index] >= 0x80:
                return True

        return 'All characters are in ASCII range'


@auto_pickle(False)
cdef class Ucs2Builder(CompactUnicodeBuilder):
    def __cinit__(Ucs2Builder self):
        self.itemsize = 2
        self.format = b'H'
        self._get = Ucs2Builder.__get
        self._set = Ucs2Builder.__set

    def release(Ucs2Builder self):
        cdef object result
        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_UNICODE

        result = self._release()
        (<PyASCIIObject*> result).state.kind = PyUnicode_2BYTE_KIND

        return result

    @staticmethod
    cdef void __set(void *ptr, Py_ssize_t value):
        (<uint16_t*> ptr)[0] = <uint16_t> value

    @staticmethod
    cdef Py_ssize_t __get(void *ptr):
        return (<uint16_t*> ptr)[0]

    def is_invalid(Ucs2Builder self):
        cdef Py_UCS2 *pos = <Py_UCS2*> ((<uint8_t*> self.memory) + START_ASCII)
        cdef Py_ssize_t index

        if self.capacity <= 0:
            return False

        for index in range(self.capacity):
            if pos[index] >= 0x100:
                return True

        return False


@auto_pickle(False)
cdef class Ucs4Builder(CompactUnicodeBuilder):
    def __cinit__(Ucs4Builder self):
        self.itemsize = 4
        self.format = b'I'
        self._get = Ucs4Builder.__get
        self._set = Ucs4Builder.__set

    def release(Ucs4Builder self):
        cdef object result
        if (self.capacity == 0) or (self.memory is NULL):
            return EMPTY_UNICODE

        result = self._release()
        (<PyASCIIObject*> result).state.kind = PyUnicode_4BYTE_KIND

        return result

    @staticmethod
    cdef void __set(void *ptr, Py_ssize_t value):
        (<uint32_t*> ptr)[0] = <uint32_t> value

    @staticmethod
    cdef Py_ssize_t __get(void *ptr):
        return (<uint32_t*> ptr)[0]

    def is_invalid(Ucs4Builder self):
        cdef Py_UCS4 *pos = <Py_UCS4*> ((<uint8_t*> self.memory) + START_ASCII)
        cdef Py_ssize_t index

        if self.capacity <= 0:
            return False

        for index in range(self.capacity):
            if pos[index] >= 0x10000:
                return True

        return False


@auto_pickle(False)
cdef class BytesBuilder(InplaceBuilder):
    def __cinit__(BytesBuilder self):
        self.offset = START_BYTES
        self.itemsize = 1
        self.format = b'B'

    def release(BytesBuilder self):
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

    def is_invalid(BytesBuilder self):
        return False
