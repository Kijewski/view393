__version__ = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, VERSION, VERSION_LENGTH)
__doc__ = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, LONGDESCRIPTION, LONGDESCRIPTION_LENGTH)

__all__ = (
    'view', 'utf8', 'kind',
    'Kind', 'BuilderValid',
    'InplaceBuilder', 'BytesBuilder', 'AsciiBuilder',
    'Ucs1Builder', 'Ucs2Builder', 'Ucs4Builder',
)
