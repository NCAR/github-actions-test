#!/bin/sh
# 
# updated 20 Oct 2020

echo 
echo  'These converters require either the HDF-EOS or the HDF-EOS5 libraries.'
echo  'These libraries are, in general, not compatible with each other.'
echo  'There is a compatibility library that "provides uniform access to HDF-EOS2'
echo  'and 5 files though one set of API calls." which sounds great.'
echo 
echo  'The HDF-EOS5 libraries are installed on the supercomputers, and are'
echo  'available via MacPorts (hdfeos5). The HDF-EOS libraries are older and'
echo  'are much less available. Consequently, I have used the HDF-EOS5 interfaces'
echo  'where possible.'
echo 
echo  'If the he5_hdfeos libraries are installed on your system, you are in luck.'
echo  'On our system, it has been useful to define variables like:'
echo 
echo  'setenv("NCAR_INC_HDFEOS5",    "/glade/u/apps/ch/opt/hdf-eos5/5.1.16/intel/19.0.5/include")'
echo  'setenv("NCAR_LDFLAGS_HDFEOS5","/glade/u/apps/ch/opt/hdf-eos5/5.1.16/intel/19.0.5/lib")'
echo  'setenv("NCAR_LIBS_HDFEOS5","-Wl,-Bstatic -lGctp -lhe5_hdfeos -lsz -lz -Wl,-Bdynamic")'
echo  'which we then use in mkmf_convert_airs_L2'
echo 
echo  'If you need to build the HDF-EOS and/or the HDF-EOS5 libraries, you may '
echo  'try to follow the steps outlined in this script. They will need to be '
echo  'modified for your system.'
echo 
echo  'You will have to edit this script, first, by removing the early exit ...'
echo

exit

# ------------------------------------------------------------------------------
##
## The HDF download portal is: https://portal.hdfgroup.org/display/support/Downloads
##
## https://hdfeos.org/software/library.php#HDF-EOS2
##
## Compatibility Library download location:
## https://opensource.gsfc.nasa.gov/projects/HDF-EOS2/index.php
##
## https://wiki.earthdata.nasa.gov/display/DAS/Toolkit+Downloads  has a link to hdf-eos v2.20
##
## It has been very difficult to find the download site for _any_ of the HDF-EOS5 
## versions. One dogged individual found that if you _knew_ the full URL, you could
## download it:
## https://observer.gsfc.nasa.gov/ftp/edhs/hdfeos5/latest_release/HDF-EOS5.1.16.tar.Z 
##
## All attempts to use ftp met with failure (some information has been obfuscated):
##
##    0[405] cheyenne2:~/src > ftp edhs1.gsfc.nasa.gov
##    Wrapper for lftp to simulate compatibility with lukemftp
##    Name (xxxxx): anonymous
##    Password:                                   
##    lftp anonymous@edhs1.gsfc.nasa.gov:~> cd /edhs/hdfeos/latest_release
##    ---- Connecting to edhs1.gsfc.nasa.gov (xxxx:xxx:xxx:xxx::xxx) port xx
##    **** connect(control_sock): Network is unreachable
##    cd: Fatal error: max-retries exceeded (Network is unreachable)
##    lftp anonymous@edhs1.gsfc.nasa.gov:~> mget /edhs/hdfeos/latest_release/HDF-EOS5.1.16.tar.Z 
##    ---- Connecting to edhs1.gsfc.nasa.gov (xxx.xxx.xxx.xx) port xx
##    `/edhs/hdfeos/latest_release/HDF-EOS5.1.16.tar.Z' at 0 [Connecting...]
##    **** Timeout - reconnecting                                             
##    mget: /edhs/hdfeos/latest_release/HDF-EOS5.1.16.tar.Z: Fatal error: max-retries exceeded
##
# ------------------------------------------------------------------------------

# nsc 11 mar 2013
# updated 16 jul 2018
#
# change this to 'true' to try the ftp
# to download a new version.  this may have
# moved locations - i haven't verified it recently.

if ( `false` ); then
  # get the files.  i got this by:
   
  # ftp edhs1.gsfc.nasa.gov
  # # (log in as 'anonymous' and your email as the password)
  # cd /edhs/hdfeos/latest_release
  # mget * # select a for all
  # quit
   
  # mar 2013, the dir contents:
  # 
  # jpegsrc.v9b.tar.gz
  # zlib-1.2.11.tar.gz
  # hdf-4.2.13.tar.gz
  # HDF-EOS2.20v1.00.tar.Z
  # HDF-EOS2.20v1.00_TestDriver.tar.Z
  # HDF-EOS_REF.pdf
  # HDF-EOS_UG.pdf

  # hdf5-1.8.19.tar.gz
  # hdf-eos5-5.1.16.tar.gz
  
  for i in *.tar.gz
  do
    tar -zxvf $i
  done
fi

# ------------------------------------------------------------------------------
# start with smaller libs, work up to HDF-EOS.
# ------------------------------------------------------------------------------

# set the installation location of the final libraries
H4_PREFIX=/glade/work/${USER}/hdf-eos
H5_PREFIX=/glade/work/${USER}/hdf-eos5

# make the target install dirs
mkdir -p ${H4_PREFIX}/{lib,bin,include,man,man/man1,share} 
mkdir -p ${H5_PREFIX}/{lib,bin,include,man,man/man1,share} 

CFLAGS='-fPIC'
FFLAGS='-fPIC'

# record the build script and environment
echo                         >  ${H4_PREFIX}/build_environment_log.txt
echo 'the build script'      >> ${H4_PREFIX}/build_environment_log.txt
cat    $0                    >> ${H4_PREFIX}/build_environment_log.txt
echo                         >> ${H4_PREFIX}/build_environment_log.txt
echo '=====================' >> ${H4_PREFIX}/build_environment_log.txt
echo 'the build environment' >> ${H4_PREFIX}/build_environment_log.txt
echo                         >> ${H4_PREFIX}/build_environment_log.txt
env | sort                   >> ${H4_PREFIX}/build_environment_log.txt

# start with smaller libs, work up to HDF-EOS.

echo ''
echo '======================================================================'
if [ -f ${H4_PREFIX}/lib/libz.a ]; then
   echo 'zlib already exists - no need to build.'
else

   echo 'building zlib at '`date`
   cd zlib-1.2.11 || exit 1
   ./configure --prefix=${H4_PREFIX} || exit 1
   make clean     || exit 1
   make           || exit 1
   make test      || exit 1
   make install   || exit 1
   cd ..
fi

echo ''
echo '======================================================================'
# This is peculiar - on Cheyenne:
# If I build with --libdir=H4_PREFIX, subsequent linking works.
# If I build with --libdir=H4_PREFIX/lib, subsequent linking FAILS with an 
# undefined reference to 'rpl_malloc'.
if [ -f ${H4_PREFIX}/libjpeg.a ]; then
   echo 'jpeg already exists - no need to build.'
else
   echo 'buiding jpeg at '`date`
   cd jpeg-9b        || exit 2
   ./configure --prefix=${H4_PREFIX} --libdir=${H4_PREFIX} || exit 2
   make clean        || exit 2
   make              || exit 2
   make test         || exit 2
   make install      || exit 2
   cd ..
fi
 
echo ''
echo '======================================================================'
if [ -f ${H4_PREFIX}/lib/libmfhdf.a ]; then
   echo 'hdf4 already exists - no need to build.'
else
   echo 'building hdf4 at '`date`
   # (apparently there is no 'make test')
   
   cd hdf-4.2.13 || exit 3
   ./configure --prefix=${H4_PREFIX} \
               --disable-netcdf \
               --with-zlib=${H4_PREFIX} \
               --with-jpeg=${H4_PREFIX} || exit 3
   make clean    || exit 3
   make          || exit 3
   make install  || exit 3
   cd ..
fi
 
echo ''
echo '======================================================================'
if [ -f ${H4_PREFIX}/lib/libhdfeos.a ]; then
   echo 'hdf-eos already exists - no need to build.'
else
   echo 'building hdf-eos at '`date`
   cd hdfeos    || exit 4
   # (the CC options are crucial to provide Fortran interoperability)
   ./configure CC='icc -Df2cFortran' --prefix=${H4_PREFIX} \
               --enable-install-include \
               --with-zlib=${H4_PREFIX} \
               --with-jpeg=${H4_PREFIX} \
               --with-hdf=${H4_PREFIX} || exit 4
   make clean   || exit 4
   make         || exit 4
   make install || exit 4
   cd ..
fi

#-------------------------------------------------------------------------------
# HDF-EOS5 record the build script and environment
#-------------------------------------------------------------------------------

echo                         >  ${H5_PREFIX}/build_environment_log.txt
echo 'the build script'      >> ${H5_PREFIX}/build_environment_log.txt
cat    $0                    >> ${H5_PREFIX}/build_environment_log.txt
echo                         >> ${H5_PREFIX}/build_environment_log.txt
echo '=====================' >> ${H5_PREFIX}/build_environment_log.txt
echo 'the build environment' >> ${H5_PREFIX}/build_environment_log.txt
echo                         >> ${H5_PREFIX}/build_environment_log.txt
env | sort                   >> ${H5_PREFIX}/build_environment_log.txt

echo '======================================================================'
if [ -f ${H5_PREFIX}/lib/libhdf5.a ]; then
   echo 'hdf5 already exists - no need to build.'
else
   echo 'building hdf5 at '`date`
   # (there is apparently no 'make test')
   
   cd hdf5-1.8.19 || exit 3
   ./configure --prefix=${H5_PREFIX} \
               --enable-fortran \
               --enable-fortran2003 \
               --enable-production \
               --with-zlib=${H4_PREFIX} || exit 3
   make clean          || exit 3
   make                || exit 3
   make check          || exit 3
   make install        || exit 3
   make check-install  || exit 3
   cd ..
fi

echo ''
echo '======================================================================'
if [ -f ${H5_PREFIX}/lib/libhe5_hdfeos.a ]; then
   echo 'hdf-eos5 already exists - no need to build.'
else
   echo 'building hdf-eos5 at '`date`
   cd hdf-eos5-5.1.16    || exit 4
   # (the CC options are crucial to provide Fortran interoperability)
   ./configure CC='icc -Df2cFortran' --prefix=${H5_PREFIX} \
               --enable-install-include \
               --with-zlib=${H4_PREFIX} \
               --with-hdf5=${H5_PREFIX} || exit 4
   make clean   || exit 4
   make         || exit 4
   make check   || exit 4
   make install || exit 4
   cd ..
fi

exit 0
