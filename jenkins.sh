#!/bin/bash

set -x
set -e


################################ SETUP BUILD ENVIRONMENT ################################
export WORKSPACE=/gpfs/bbp.cscs.ch/home/kumbhar/
export SPACK_DEPLOYMENT_HOME=$WORKSPACE/SOFTS_HOME
mkdir -p $SPACK_DEPLOYMENT_HOME


# spack stores cache and configs under $HOME. In order to avoid collision with
# other user's build we change $HOME to directory under current workspace
#export HOME=$SPACK_DEPLOYMENT_HOME
export SPACK_HOME=$SPACK_DEPLOYMENT_HOME/repos/spack
export COMPILERS_HOME=$SPACK_DEPLOYMENT_HOME/deployment/compilers
export SOFTWARES_HOME=$SPACK_DEPLOYMENT_HOME/deployment/softwares


################################ CLEANUP ################################
#rm -rf $SPACK_DEPLOYMENT_HOME/spack $SPACK_DEPLOYMENT_HOME/spack-deployment $SPACK_DEPLOYMENT_HOME/licenses $HOME/.spack


########################## CLONE REPOSITORIES ############################
mkdir -p $SPACK_DEPLOYMENT_HOME/repos/
cd $SPACK_DEPLOYMENT_HOME/repos/

if false; then
    git clone https://github.com/pramodskumbhar/spack.git -b bbp5
    git clone https://github.com/pramodskumbhar/spack-deployment.git -b bbp5
    git clone ssh://bbpcode.epfl.ch/user/kumbhar/spack-licenses licenses
    ########################## ADD LICENSES ############################
    cp -r licenses $SPACK_HOME/etc/spack/
fi

unset MODULEPATH
export PATH=$SPACK_HOME/bin:$PATH
source $SPACK_HOME/share/spack/setup-env.sh

# remove previous cache
#spack clean -a

######################### ARCH & DEFAULT COMPILERS ##########################
spack arch
spack compiler find


cd $SPACK_DEPLOYMENT_HOME/repos/spack-deployment

######################### INSTALL COMPILERS ##########################
./compilers.sh $SPACK_DEPLOYMENT_HOME $COMPILERS_HOME $SPACK_HOME

exit 0

######################### REGISTER PACKAGES ##########################
COMPILERS_INSTALL_PREFIX=$COMPILERS_HOME/install/`spack arch`/gcc-4.8.4
./register_packages.sh $COMPILERS_INSTALL_PREFIX

set +e
set +x

spack config get config
echo "SOFTWARES_HOME : $SOFTWARES_HOME"

cp /gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/install.sh .
bash install.sh
