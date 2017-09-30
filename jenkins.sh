#!/bin/bash

set -x
set -e


################################ SETUP BUILD ENVIRONMENT ################################
cd $WORKSPACE
mkdir -p $WORKSPACE/DEPLOYMENT


# spack stores cache and configs under $HOME. In order to avoid collision with
# other user's build we change $HOME to directory under current workspace
export HOME=$WORKSPACE/DEPLOYMENT
export SPACK_HOME=$WORKSPACE/DEPLOYMENT


################################ CLEANUP ################################
rm -rf $SPACK_HOME/* $HOME/.spack


########################## CLONE REPOSITORIES ############################
cd $SPACK_HOME
git clone https://github.com/pramodskumbhar/spack.git -b bbprh69
git clone https://github.com/pramodskumbhar/spack-deployment.git


export PATH=$SPACK_HOME/spack/bin:$PATH
source $SPACK_HOME/spack/share/spack/setup-env.sh


########################## ADD LICENSES ############################
git clone ssh://bbpcode.epfl.ch/user/kumbhar/spack-licenses licenses
cp -r licenses $SPACK_HOME/spack/etc/spack/


######################### ARCH & DEFAULT COMPILERS ##########################
spack arch
spack compiler find


################################ MIRROR DIRECTORIES ################################
export COMPILERS_HOME=/gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/JENKINS_SPACK_HOME/compilers
mkdir -p $COMPILERS_HOME/extra/mirror
spack mirror add compiler_filesystem $COMPILERS_HOME/extra/mirror


################################ MIRROR COMPILERS ################################
packages_to_mirror=(
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@7.2.0'
    'llvm@4.0.1'
    'intel-parallel-studio@professional.2017.4'
)

for package in "${packages_to_mirror[@]}"
do
    spack mirror create -d $COMPILERS_HOME/extra/mirror --dependencies $package
done


############################## PGI COMPILER TARBALL #############################
mkdir -p  $COMPILERS_HOME/extra/mirror/pgi
cp /gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/compiler_downlaods/pgilinux-2017-174-x86_64.tar.gz $COMPILERS_HOME/extra/mirror/pgi/pgi-17.4.tar.gz


################################ SET COMPILERS CONFIG ################################
mkdir -p  $SPACK_ROOT/etc/spack/defaults/linux/
cp $SPACK_HOME/spack-deployment/step1.config.yaml $SPACK_ROOT/etc/spack/defaults/linux/config.yaml
cp $SPACK_HOME/spack-deployment/step1.modules.yaml $SPACK_ROOT/etc/spack/defaults/linux/modules.yaml


################################ START COMPILERS INSTALLATION ################################
compilers=(
    'intel-parallel-studio@professional.2017.4'
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@7.2.0'
    'pgi+network+nvidia'
)

core_compiler='gcc@4'

for compiler in "${compilers[@]}"
do
    spack spec $compiler %$core_compiler
    spack install $compiler %$core_compiler
done


####################### LLVM NEEDS NEWER GCC ################################
spack compiler find `spack location --install-dir gcc@4.9.3`
spack install llvm@4.0.1 %gcc@4.9.3


####################### REGENERATE MODULES ################################
spack module refresh --yes-to-all --delete-tree --module-type tcl --yes-to-all
spack module refresh --yes-to-all --delete-tree --module-type lmod --yes-to-all

################################ PERMISSIONS ################################
setfacl -R -m u:kumbhar-adm:rwx $COMPILERS_HOME/extra/mirror
setfacl -R -m u:kumbhar:rwx $COMPILERS_HOME/extra/mirror
