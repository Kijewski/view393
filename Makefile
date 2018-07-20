all: sdist bdist_wheel docs

NAME := view393

.PHONY: all sdist bdist_wheel clean docs

FILES := Makefile MANIFEST.in ${NAME}.pyx README.rst setup.py \
         lib/native.hpp lib/VERSION lib/DESCRIPTION

${NAME}.cpp: ${NAME}.pyx $(wildcard lib/*.pyx)
	rm -f -- dist/*.so ${NAME}.cpp
	rm -f ./${NAME}.cpp
	cythonize $<

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
