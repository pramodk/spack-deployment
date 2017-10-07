#!/bin/bash

set -x
set -e

########################################### PARSE ARGUMENTS ################################################
if [ $# -ne 2 ]; then
    echo $0: USAGE: $0 SPACK_HOME COMPILERS_HOME
    exit 1
fi

export SPACK_HOME=$1
export COMPILERS_HOME=$2


################################ MIRROR DIRECTORIES ################################
mkdir -p $SPACK_HOME/mirrors/compiler
spack mirror add compiler_filesystem $SPACK_HOME/mirrors/compiler


################################ MIRROR COMPILERS ################################
packages_to_mirror=(
    'gcc@4.8.4'
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@6.2.0'
    'gcc@7.2.0'
    'llvm@4.0.1'
    'intel-parallel-studio@professional.2017.4+advisor+inspector+itac+vtune'
)

for package in "${packages_to_mirror[@]}"
do
    spack mirror create -d $SPACK_HOME/mirrors/compiler --dependencies $package
done


############################## PGI COMPILER TARBALL #############################
mkdir -p $SPACK_HOME/mirrors/compiler/pgi
cp /gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/compiler_downlaods/pgilinux-2017-174-x86_64.tar.gz $SPACK_HOME/mirrors/compiler/pgi/pgi-17.4.tar.gz


################################ SET COMPILERS CONFIG ################################
mkdir -p  $SPACK_HOME/spack/etc/spack/defaults/linux/
rm -f $SPACK_HOME/spack/etc/spack/defaults/linux/*
cp $SPACK_HOME/spack-deployment/step1/config.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/config.yaml
cp $SPACK_HOME/spack-deployment/step1/modules.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/modules.yaml

source $SPACK_HOME/spack/share/spack/setup-env.sh


################################ INSTALL OPTIONS ################################
options='--show-log-on-error'


################################ CORE COMPILER (C++11 Headers) ################################
core_compiler='gcc@4.8.4'
spack install $options $core_compiler %gcc@4
spack compiler find `spack location --install-dir $core_compiler`


################################ START COMPILERS INSTALLATION ################################
compilers=(
    'intel-parallel-studio@professional.2017.4+advisor+inspector+itac+vtune'
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@6.2.0'
    'gcc@7.2.0'
    'pgi@17.4+network+nvidia'
    'llvm@4.0.1'
)

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
spack load pgi@17.4
PGI_DIR=$(dirname $(which makelocalrc))
GCC_DIR=`spack location --install-dir gcc@4.9.3`
makelocalrc -x $PGI_DIR -gcc $GCC_DIR/bin/gcc -gpp $GCC_DIR/bin/g++ -g77 $GCC_DIR/bin/gfortran


####################### ADD NEW COMPILERS TO SPACK ################################
spack compilers
module load gcc-4.8.4 gcc-4.9.3 gcc-5.3.0 gcc-6.2.0 gcc-7.2.0 intel-parallel-studio-professional.2017.4 llvm-4.0.1 pgi-17.4
spack compiler find

sed -i 's#.*fc: .*pgfortran#      fc: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed -i 's#.*f77: .*pgf77#      f77: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed -i 's#.*f77: .*pgfortran#      f77: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed  -i 's#.*f77: null#      f77: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml
sed  -i 's#.*fc: null#      fc: /usr/bin/gfortran#' $HOME/.spack/linux/compilers.yaml

spack compilers
spack config get compilers


################################ PERMISSIONS ################################
chmod -R g-w  $SPACK_HOME/*
chmod -R g+rx $COMPILERS_HOME/*
