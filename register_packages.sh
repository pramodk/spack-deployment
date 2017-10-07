#!/bin/bash

set -e


########################################### PARSE ARGUMENTS ################################################
if [ $# -ne 1 ]; then
    echo $0: USAGE: $0 COMPILERS_INSTALL_PREFIX
    exit 1
fi

compilers_install_prefix=$1

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


cp step2/config.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/
cp step2/modules.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/
cp step2/packages.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/

# for each compiler
for compiler in "${compilers[@]}"
do
    cp step2/packages.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/packages.yaml
    sed -i "s/\[gcc@4.9.3]/\[$compiler]/g" $SPACK_HOME/spack/etc/spack/defaults/linux/packages.yaml

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


cp step2/packages.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/packages.yaml
sed -i "s#COMPILERS_INSTALL_PREFIX#$compilers_install_prefix#g" $SPACK_HOME/spack/etc/spack/defaults/linux/packages.yaml

for compiler in "${compilers[@]}"
do
    spack install $compiler %$core_compiler
done

spack find -p
