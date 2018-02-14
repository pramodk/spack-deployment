#!/bin/bash

set -x
set -e

########################################### PARSE ARGUMENTS ################################################
if [ $# -ne 3 ]; then
    echo $0: USAGE: $0 SPACK_DEPLOYMENT_HOME COMPILERS_HOME SPACK_HOME
    exit 1
fi

export SPACK_DEPLOYMENT_HOME=$1
export COMPILERS_HOME=$2
export SPACK_HOME=$3


################################ MIRROR DIRECTORIES ################################
mkdir -p $SPACK_DEPLOYMENT_HOME/mirrors/compiler
spack mirror add compiler_filesystem $SPACK_DEPLOYMENT_HOME/mirrors/compiler || echo ""


################################ MIRROR COMPILERS ################################
packages_to_mirror=(
    'intel-parallel-studio@professional.2018.1+advisor+inspector+itac+vtune+clck+gdb+mpi'
    'gcc@4.9.3'
    'gcc@6.2.0'
    'gcc@7.2.0'
    'llvm@4.0.1'
    'llvm@5.0.1'
)

for package in "${packages_to_mirror[@]}"
do
    spack mirror create -d $SPACK_DEPLOYMENT_HOME/mirrors/compiler --dependencies $package
done


############################## PGI COMPILER TARBALL #############################
mkdir -p $SPACK_DEPLOYMENT_HOME/mirrors/compiler/pgi
cp /gpfs/bbp.cscs.ch/home/kumbhar/DOWNLOADS/pgilinux-2017-1710-x86_64.tar $SPACK_DEPLOYMENT_HOME/mirrors/compiler/pgi/pgi-17.10.tar.gz

################################ SET COMPILERS CONFIG ################################
mkdir -p  $SPACK_HOME/etc/spack/defaults/linux/
rm -f $SPACK_HOME/etc/spack/defaults/linux/*
cp $SPACK_DEPLOYMENT_HOME/repos/spack-deployment/step1/config.yaml $SPACK_HOME/etc/spack/defaults/linux/config.yaml
cp $SPACK_DEPLOYMENT_HOME/repos/spack-deployment/step1/modules.yaml $SPACK_HOME/etc/spack/defaults/linux/modules.yaml

source $SPACK_HOME/share/spack/setup-env.sh


################################ INSTALL OPTIONS ################################
options='--show-log-on-error'


################################ CORE COMPILER (C++11 Headers) ################################
core_compiler='gcc@4.8.5'


################################ START COMPILERS INSTALLATION ################################
compilers=(
    'intel-parallel-studio@professional.2018.1+advisor+inspector+itac+vtune+clck+gdb+mpi'
    'pgi@17.10+network+nvidia'
    'gcc@4.9.3'
    'gcc@6.2.0'
    'gcc@7.2.0'
    'llvm@4.0.1'
    'llvm@5.0.1'
)

#'intel-parallel-studio@professional.2018.1+advisor+inspector+itac+vtune'

for compiler in "${compilers[@]}"
do
    spack spec -I $compiler %$core_compiler
    spack install $options $compiler %$core_compiler
done


####################### REGENERATE MODULES ################################
spack module refresh --yes-to-all --delete-tree --module-type tcl --yes-to-all
spack module refresh --yes-to-all --delete-tree --module-type lmod --yes-to-all


####################### AVAILABLE PACKAGES & MODULES ################################
spack find
module avail


####################### PGI COMPILER CONFIGURATION ################################
spack load pgi@17.10
PGI_DIR=$(dirname $(which makelocalrc))
GCC_DIR=`spack location --install-dir gcc@4.9.3`
makelocalrc -x $PGI_DIR -gcc $GCC_DIR/bin/gcc -gpp $GCC_DIR/bin/g++ -g77 $GCC_DIR/bin/gfortran


####################### ADD NEW COMPILERS TO SPACK ################################
spack compilers
module load gcc-4.9.3 gcc-6.2.0 gcc-7.2.0 intel-parallel-studio-professional.2018.1 llvm-4.0.1 pgi-17.10 llvm-5.0.1
spack compiler find

sed -i 's#.*fc: .*pgfortran#      fc: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed -i 's#.*f77: .*pgf77#      f77: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed -i 's#.*f77: .*pgfortran#      f77: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed  -i 's#.*f77: null#      f77: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed  -i 's#.*fc: null#      fc: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml

spack compilers
spack config get compilers


################################ PERMISSIONS ################################
chmod -R g-w  $SPACK_DEPLOYMENT_HOME/*
chmod -R g+rx $COMPILERS_HOME/*
