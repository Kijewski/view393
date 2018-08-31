all: sdist bdist_wheel docs

NAME := view393

.PHONY: all sdist bdist_wheel clean docs

FILES := Makefile MANIFEST.in setup.py
FILES += ${NAME}.pyx ${NAME}.pxd ${NAME}/native.hpp
FILES += README.rst ${NAME}/VERSION ${NAME}/DESCRIPTION

${NAME}.cpp: ${NAME}.pyx ${NAME}.pxd $(wildcard ${NAME}/*.pyx) Makefile
	rm -f -- dist/*.so ${NAME}.cpp
	rm -f ./${NAME}.cpp
	cythonize --force $<

sdist: ${NAME}.cpp ${FILES}
	rm -f -- dist/${NAME}-*.tar.gz
	python setup.py sdist --format=gztar
	python setup.py sdist --format=xztar

bdist_wheel: ${NAME}.cpp ${FILES} | sdist
	rm -f -- dist/${NAME}-*.whl
	python setup.py bdist_wheel

docs: bdist_wheel $(wildcard docs/* docs/*/*)
	[ ! -d dist/docs/ ] || rm -r -- dist/html/
	pip install --force dist/${NAME}-*.whl
	python -m sphinx -M html docs/ dist/

clean:
	[ ! -d build/ ] || rm -r -- build/
	[ ! -d dist/ ] || rm -r -- dist/
	[ ! -d ${NAME}.egg-info/ ] || rm -r -- ${NAME}.egg-info/
	rm -f -- dist/.*.so ${NAME}.cpp
	-pip uninstall ${NAME} -y
