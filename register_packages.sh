#!/bin/bash

set -e


########################################### PARSE ARGUMENTS ################################################
if [ $# -ne 1 ]; then
    echo $0: USAGE: register_packages.sh COMPILERS_INSTALL_PATH
    exit 1
fi

compilers_install_path="$1"


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
    'gcc@4.8.4'
    'clang@4.0.1'
    'intel@17.0.4'
    'pgi@17.4'
)


# for each compiler
for compiler in "${compilers[@]}"
do
    cp step2/packages.yaml $HOME/.spack/linux/packages.yaml
    sed -i "s/\[gcc@4.9.3]/\[$compiler]/g" $HOME/.spack/linux/packages.yaml

    for package in "${packages[@]}"
    do
        spack install $package %$compiler
    done
done


core_compiler='gcc@4.8.4'
compilers=(
    'gcc@7.2.0'
    'gcc@5.3.0'
    'gcc@4.9.3'
    'llvm@4.0.1'
    'intel@17.0.4'
    'pgi@17.4'
)


cp step2/packages.yaml $HOME/.spack/linux/packages.yaml
sed -i "s#COMPILERS_INSTALL_PATH#$compilers_install_path#g" $HOME/.spack/linux/packages.yaml


for compiler in "${compilers[@]}"
do
    echo "spack install $compiler %$core_compiler"
    spack install $compiler %$core_compiler
done
