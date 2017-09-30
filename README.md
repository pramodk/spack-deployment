# Deploying Spack stack on BBP RH 6.9 Cluster #

These are brief instructions to deploy entire software stack using Jenkins infrastructure with RH 6.9 node.


Spack by default stores temporary cache and config files under `$HOME`. In order to avoid collision with
other Jenkins job, we will set `$HOME` to the directory under jenkins workspace:

```
export HOME=$WORKSPACE/DEPLOYMENT
export SPACK_HOME=$WORKSPACE/DEPLOYMENT
rm -rf $HOME/.spack
```

> If you are executing these instructions manually, first set WORKSPACE:
>
>	```
>   export WORKSPACE=$HOME/TEST
>   mkdir -p $WORKSPACE
>	```


#### Clone Repositories

clone below repositories for Spack and Spack configurations:

```
cd $SPACK_HOME
git clone https://github.com/pramodskumbhar/spack.git -b bbprh69
git clone https://github.com/pramodskumbhar/spack-deployment.git
```

Add following to `.bashrc`

```
# make sure to set SPACK_HOME first

export PATH=$SPACK_HOME/spack/bin:$PATH
source $SPACK_HOME/spack/share/spack/setup-env.sh
```

> TODO: Use stable branches that we continiously test for deploying entire stack.


#### Software Licenses

Commercial softwares like `Intel`, `PGI` and `Allinea` need licenses. These are usually simple text files with license key or license server details. In Spack we can copy those licenses in `etc/spack/licenses` directory:

```
cd $SPACK_HOME
git clone ssh://bbpcode.epfl.ch/user/kumbhar/spack-licenses licenses
cp -r licenses $WORKSPACE/SPACK_HOME/spack/etc/spack/
```

> Above is BBP specific licenses. The directory looks like

```
	$ tree
	.
	├── allinea-forge
	│   └── Licence
	├── intel
	│   └── license.lic
	└── pgi
		└── license.dat
```

Note that this is required only if you are installing licensed software components.

#### Adding Mirror [Optional]

Some software tarballs are very large and often time consuming to download (e.g. Intel Parallel Studio is about ~3 GB). In order to avoid download on every new installation we can create a mirror where software tarballs could be stored. This is also helpful when we have clusters where network connection is slow or network access is not available at all (e.g. systems at BSC). You can check [spack mirror]() documentation for details and extra options. There are options to provide text file but we are simply adding softwares one-by-one:

```
export COMPILERS_HOME=$SPACK_HOME/install_home/externals

mkdir -p $COMPILERS_HOME/extra/mirror

spack mirror add local_filesystem $COMPILERS_HOME/extra/mirror

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
```

> Note :  The `intel@17.0.0.1` and `intel@16.0.0.1` has only C/C++ compilers. It's better to install `intel-parallel-studio` which has all components including fortran compilers.

Some softwares do need manual download from registered account (e.g. PGI compilers). Once you download them you can manually copy them to mirror directory as:

```
mkdir -p $COMPILERS_HOME/extra/mirror/pgi
cp /gpfs/bbp.cscs.ch/home/kumbhar-adm/pgilinux-2017-174-x86_64.tar.gz $COMPILERS_HOME/extra/mirror/pgi/pgi-17.4.tar.gz

# note that we don't have license for 17.7
#cp /gpfs/bbp.cscs.ch/apps/viz/tools/pgi/pgilinux-2017-177-x86_64.tar.gz $WORKSPACE/SPACK_HOME/install_home/mirror/pgi/pgi-17.7.tar.gz
```
> Note : For PGI compiler you can keep tarball in some local directory and invoke `spack install` from that same directory. You have to make sure to rename tarball while copying to mirror i.e. pgilinux-2017-174-x86_64.tar.gz to pgi-17.4.tar.gz

### Installing Compilers
By default Spack will find compilers available in `$PATH`. We can see available compilers using :

```
$ spack compilers
==> Available compilers
-- clang rhel6-x86_64 -------------------------------------------
clang@3.4.2

-- gcc rhel6-x86_64 ---------------------------------------------
gcc@4.4.7  gcc@3.4.6
```

These are default compilers installed on system. For software development we often need to install multiple compilers to meet requirements of different users. Also, compilers are expensive to install considering long build time. Often we don't need to reinstall compilers from scratch if there are other system/network related updates. One can delete entire software stack using `spack uninstall --all`. But in practive we want to preserve compiler installations and re-compile all other software stack. In this case it is good practice to install compilers in separate directory.

We can achieve this by using sample `config.yaml` with below settings:

```
config:
  install_tree: $COMPILERS_HOME/install
```

Instead of hardcoding path we will set environmental variable `COMPILERS_HOME`. We will copy the provided `config.yaml` for compilers installation:

```
rm -rf $HOME/.spack/linux/*
cp $SPACK_HOME/spack-configs/bbprh69/compilers.config.yaml ~/.spack/linux/config.yaml
```

We can now install all required compilers using Spack. Some compilers like `llvm` can't be compiled with old version of gcc (e.g. `llvm` required gcc version `>=4.8`). In this case we will first install newer `gcc` and then use it for `llvm` installation.

Here is sample script to achieve this:

```
compilers=(
    'intel-parallel-studio@professional.2017.4'
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@7.2.0'
    'pgi+network+nvidia'
)

core_compiler='gcc@4'

spack compiler find

for compiler in "${compilers[@]}"
do
    spack spec $compiler %$core_compiler
    spack install -v $compiler %$core_compiler
done

# tell spack the location of new compiler
spack compiler find `spack location --install-dir gcc@4.9.3`

# install llvm with newer version of gcc
spack install llvm@4.0.1 %gcc@4.9.3
```

> Note : We are not using `packages.yaml` with system installed packages here. Some compilers do need latest `autoconf`, `automake` etc. and better to install those all dependencies from scratch. (e.g. for `gmp-6.1.2` we saw errors while installing with system packages).

Once all compilers are installed we want to generate `user-friendly` modules and not default ones like below:

```
----------------------------------------- /gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/install_home/externals/tcl/linux-rhel6-x86_64 -----------------------------------------
autoconf-2.63-gcc-4.4.7-3nydg2s        gmp-6.1.2-gcc-4.4.7-qbnerqz            mpfr-3.1.5-gcc-4.4.7-qqtt2et           py-six-1.10.0-gcc-4.4.7-dviyzq5
autoconf-2.69-gcc-4.4.7-faqgymq        help2man-1.47.4-gcc-4.4.7-jrwlm4p      ncurses-6.0-gcc-4.4.7-4wkexyz          py-six-1.10.0-gcc-4.9.3-4o4hqmk
....
```

Spack automatically creates all modules but we can explicitly tell which one we want to keep. Copy below settings file and `re-generate` modules as:

```
cp $SPACK_HOME/spack-deployment/step1.modules.yaml $HOME/.spack/linux/modules.yaml
spack module refresh --yes-to-all --delete-tree --module-type tcl --yes-to-all
```

> NOTE : make sure gcc 4.9.3 is already added with spack compiler find `spack location --install-dir gcc@4.9.3`

And now Spack will generat modules for compiler only:

```
$ echo $MODULEPATH
/gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/install_home/externals/tcl/linux-rhel6-x86_64

$ module avail

----------------------------------------------- /gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/install_home/externals/tcl/linux-rhel6-x86_64 -----------------------------------------------
gcc-4.9.3      gcc-5.3.0      gcc-7.2.0      intel-16.0.0.1 intel-17.0.0.1 llvm-4.0.1     pgi-17.4
```

Alright! All our compilers are ready for next software stack installation!

> Note: For a network installation of PGI compilers, we must have to run below installation script on each system
on the network where the compilers and tools will be available for use. For example, we installed PGI compilers on bbpviz1. If we try to use PGI compiler on bbpviz2, we get :

```
$ pgcc hello.c
pgcc-Error-Please run makelocalrc to complete your installation
```
> In this case we have to run following on every node where we are going to compile the code:

```
$ module load pgi-17.4
$ which makelocalrc
~/SPACK_HOME/install_home/externals/install/linux-rhel6-x86_64/gcc-4.4.7/pgi-17.4/linux86-64/17.4/bin/makelocalrc
$ makelocalrc -x ~/SPACK_HOME/install_home/externals/install/linux-rhel6-x86_64/gcc-4.4.7/pgi-17.4/linux86-64/17.4 -net ~/SPACK_HOME/install_home/externals/install/linux-rhel6-x86_64/gcc-4.4.7/pgi-17.4/linux86-64/17.4
```

> NOTE : INTEL_ROOT is special environmental variable for Intel compilers! So don't set PACKAGE_ROOT into modules.yaml!


### Software Stack Installation

```
rm -rf $HOME/.spack/linux/*
cp $SPACK_HOME/spack-deployment/step2.config.yaml $HOME/.spack/linux/
cp $SPACK_HOME/spack-deployment/step2.packages.yaml $HOME/.spack/linux/
```

Let's add compilers. Note that we have either specify complete path or load modules as:

```
export MODULEPATH=/gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/install_home/externals/tcl/linux-rhel6-x86_64:$MODULEPATH
module load gcc-4.9.3 gcc-5.3.0 gcc-7.2.0 intel-16.0.0.1 intel-17.0.0.1 llvm-4.0.1 pgi-17.4
spack compiler find
```

We will now have following compilers:

```
$ spack compilers
==> Available compilers
-- clang rhel6-x86_64 -------------------------------------------
clang@4.0.1  clang@3.4.2

-- gcc rhel6-x86_64 ---------------------------------------------
gcc@7.2.0  gcc@5.3.0  gcc@4.9.3  gcc@4.4.7  gcc@3.4.6

-- intel rhel6-x86_64 -------------------------------------------
intel@17.0.0  intel@16.0.3
```

Note that we don't have PGI `pgfortran` license. LLVM compiler doesn't ship fortran compiler (yet). Also, if we install only `C/C++` components of Intel Parallel Studio then fortran compiler (i.e. `ifort`) is not available. Fortran compiler is required for for MPI installation. We can use `gfortran` in `compilers.yaml` as a replacement:

```
sed -i 's#.*fc: .*pgfortran#      fc: /usr/bin/gfortran#' ~/.spack/linux/compilers.yaml
sed -i 's#.*f77: .*pgfortran#      f77: /usr/bin/gfortran#' ~/.spack/linux/compilers.yaml
sed  -i 's#.*f77: null#      f77: /usr/bin/gfortran#' ~/.spack/linux/compilers.yaml
sed  -i 's#.*fc: null#      fc: /usr/bin/gfortran#' ~/.spack/linux/compilers.yaml
```

---
> NOTE: This is no longer needed for package installations:
> Intel compilers heavily depend on `LD_LIBRARY_PATH`. We have to either add module entry to `compilers.yaml` and then use `dirty` flag or have to provide configuration file (CFG) as:

```
-isystem$WORKSPACE/SPACK_HOME/install_home/externals/install/linux-rhel6-x86_64/gcc-4.4.7/intel-17.0.0.1/include #
-Xlinker -L$WORKSPACE/SPACK_HOME/install_home/externals/install/linux-rhel6-x86_64/gcc-4.4.7/intel-17.0.0.1/lib/intel64 #
-Xlinker -rpath=$WORKSPACE/SPACK_HOME/install_home/externals/install/linux-rhel6-x86_64/gcc-4.4.7/intel-17.0.0.1/lib/intel64
```

> And set following environmental variables before invoking install command:

```
export ICCCFG=$WORKSPACE/SPACK_HOME/SPACK_HOME/spack-configs/bbprh69/icl.cfg
export ICPCFG=$WORKSPACE/SPACK_HOME/SPACK_HOME/spack-configs/bbprh69/icl.cfg
```
---

#### Making Compilers Available for Users [TODO]

* Add modules entry
* Set ICCCFG, ICPCFG correctly in modules : make use of `spack location --install-dir icc@17.0.0.1` and update template file correctly
* Need to set MKL, TBB entries into icl.cfg file
