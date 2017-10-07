#!/bin/bash

set -x
set -e


################################ SETUP BUILD ENVIRONMENT ################################
export WORKSPACE=/gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/JENKINS_DEPLOYMENT
mkdir -p $WORKSPACE/SPACK_HOME


# spack stores cache and configs under $HOME. In order to avoid collision with
# other user's build we change $HOME to directory under current workspace
export HOME=$WORKSPACE/SPACK_HOME
export SPACK_HOME=$WORKSPACE/SPACK_HOME
export COMPILERS_HOME=$WORKSPACE/install/compilers
export SOFTWARES_HOME=$WORKSPACE/install/softwares


################################ CLEANUP ################################
rm -rf $SPACK_HOME/spack $SPACK_HOME/spack-deployment $SPACK_HOME/licenses $HOME/.spack


########################## CLONE REPOSITORIES ############################
cd $SPACK_HOME
git clone https://github.com/pramodskumbhar/spack.git -b bbprh69
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


cd spack-deployment

######################### INSTALL COMPILERS ##########################
./compilers.sh $SPACK_HOME $COMPILERS_HOME


######################### REGISTER PACKAGES ##########################
COMPILERS_INSTALL_PREFIX=$COMPILERS_HOME/install/`spack arch`/gcc-4.8.4
./register_packages.sh $COMPILERS_INSTALL_PREFIX

set +e
set +x

spack config get config
echo "SOFTWARES_HOME : $SOFTWARES_HOME"

cp /gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/install.sh .
bash install.sh
