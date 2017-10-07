#!/bin/bash

set -x
set -e

################################ SETUP BUILD ENVIRONMENT ################################
export WORKSPACE=/gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/JENKINS_DEPLOYMENT/
mkdir -p $WORKSPACE/SPACK_HOME


# spack stores cache and configs under $HOME. In order to avoid collision with
# other user's build we change $HOME to directory under current workspace
export HOME=$WORKSPACE/SPACK_HOME
export SPACK_HOME=$WORKSPACE/SPACK_HOME


################################ CLEANUP ################################
rm -rf $SPACK_HOME/spack $SPACK_HOME/spack-deployment $SPACK_HOME/licenses $HOME/.spack


########################## CLONE REPOSITORIES ############################
cd $SPACK_HOME
git clone https://github.com/pramodskumbhar/spack.git -b stable
git clone https://github.com/pramodskumbhar/spack-deployment.git

unset MODULEPATH
export PATH=$SPACK_HOME/spack/bin:$PATH
source $SPACK_HOME/spack/share/spack/setup-env.sh


########################## ADD LICENSES ############################
git clone ssh://bbpcode.epfl.ch/user/kumbhar/spack-licenses licenses
cp -r licenses $SPACK_HOME/spack/etc/spack/


######################### ARCH & DEFAULT COMPILERS ##########################
spack arch
spack compiler find


################################ MIRROR DIRECTORIES ################################
export COMPILERS_HOME=$WORKSPACE/install/compilers
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
mkdir -p  $SPACK_HOME/mirrors/compiler/pgi
cp /gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/compiler_downlaods/pgilinux-2017-174-x86_64.tar.gz $SPACK_HOME/mirrors/compiler/pgi/pgi-17.4.tar.gz


################################ SET COMPILERS CONFIG ################################
mkdir -p  $SPACK_HOME/spack/etc/spack/defaults/linux/
cp $SPACK_HOME/spack-deployment/step1.config.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/config.yaml
cp $SPACK_HOME/spack-deployment/step1.modules.yaml $SPACK_HOME/spack/etc/spack/defaults/linux/modules.yaml
source $SPACK_HOME/spack/share/spack/setup-env.sh


################################ INSTALL OPTIONS ################################
options='--show-log-on-error'


################################ CORE COMPILER (C++11 Headers) ################################
core_compiler='gcc@4.8.4'
spack install $options $core_compiler %gcc@4
spack compiler find `spack location --install-dir $core_compiler`

spack uninstall -y intel-parallel-studio

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
module avail
spack find

################################ PERMISSIONS ################################
chmod -R g-w  $WORKSPACE/*
chmod -R g+rx $WORKSPACE/*
