#!/bin/bash

set -e

declare -a packages=(
    'autoconf'
    'automake'
    'bison'
    'cairo'
    'cmake'
    'curl'
    'environment-modules'
    'flex'
    'fontconfig'
    'glib'
    'hwloc'
    'libedit'
    'libjpeg'
    'libmng'
    'libtool'
    'libx11'
    'lua'
    'm4'
    'ncurses'
    'openssl'
    'pango'
    'pcre'
    'perl'
    'pkg-config'
    'readline'
    'slurm'
    'sqlite'
    'tar'
    'tcl'
    'tk'
    'xz'
)

compilers=(
    'gcc@7.2.0'
    'gcc@5.3.0'
    'gcc@4.9.3'
    'gcc@4.4.7'
    'clang@4.0.1'
    'intel@17.0.0'
    'intel@17.0.4'
    'intel@16.0.3'
    'pgi@17.4'
)

# for each compiler
for compiler in "${compilers[@]}"
do
    cp step2.packages.yaml $HOME/.spack/linux/packages.yaml
    sed -i "s/gcc@4.9.3/$compiler/g" $HOME/.spack/linux/packages.yaml

    # build each package
    for package in "${packages[@]}"
    do
        # install package
        echo " == > REGISTER PACKAGE : spack install $package %$compiler"
        spack install $package %$compiler
    done
done
