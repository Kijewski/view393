#!/usr/bin/env python

from setuptools import setup, Extension
from os.path import dirname, join, abspath


def get_text(name):
    root = abspath(dirname(__file__))
    with open(join(root, name), 'rt') as f:
        return f.read().strip()


extra_compile_args = [
    '-std=c++11', '-Wall', '-Wextra', '-Werror', '-Wno-error=ignored-qualifiers',
    '-Os',  '-fomit-frame-pointer', '-fPIC', '-ggdb1', '-pipe',
    '-D_FORTIFY_SOURCE=2', '-fstack-protector-strong', '--param=ssp-buffer-size=8',
]

extra_link_args = [
    *extra_compile_args,
    '-fPIC',
    '-Wl,-zrelro,-znow,-zcombreloc,-znocommon,-znoexecstack',
]

name = 'view393'

setup(
    name=name,
    version=eval(get_text('lib/VERSION')),
    long_description=get_text('README.rst'),
    description='Some helper functions to inspect :class:`str` objects in Python 3.3 and later.',
    author='René Kijewski',
    author_email='pypi.org@k6i.de',
    maintainer='René Kijewski',
    maintainer_email='pypi.org@k6i.de',
    url='https://github.com/Kijewski/pyjson5',
    python_requires='~= 3.3',
    zip_safe=False,
    ext_modules=[Extension(
        name,
        sources=[name + '.pyx'],
        include_dirs=['lib'],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        language='c++',
    )],
    platforms=['any'],
    license='License :: OSI Approved :: MIT License',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'Programming Language :: Python :: 3 :: Only',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: Implementation :: CPython',
        'Topic :: Text Processing',
    ],
)
