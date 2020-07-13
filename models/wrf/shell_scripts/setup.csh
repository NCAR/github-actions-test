#!/bin/csh
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download

# This script sets up the proper directory structure for running the WRF/DART tutorial.
# It also places the required DART, WRF, and WRFDA executables and files in the proper location.
#
# >> ./setup.csh param.csh

set paramfile = `readlink -f ${1}` # Get absolute path for param.csh from command line arg
source $paramfile
set COPY = 'cp -rL'

# Create directories
foreach dir ( ${RUN_DIR} ${TEMPLATE_DIR} ${OBSPROC_DIR} ${OUTPUT_DIR} ${ICBC_DIR} \
              ${POST_STAGE_DIR} ${OBS_DIAG_DIR} ${PERTS_DIR} ${SHELL_SCRIPTS_DIR} \
              ${RUN_DIR}/WRFIN ${RUN_DIR}/WRFOUT ${RUN_DIR}/WRF_RUN )
    if ( ! -d $dir ) mkdir -p $dir
end

# Put DART executables in proper place
foreach exe ( advance_time filter pert_wrf_bc obs_diag obs_sequence_tool \
              obs_seq_to_netcdf fill_inflation_restart wrf_dart_obs_preprocess )
    ${COPY} ${DART_DIR}/models/wrf/work/$exe ${RUN_DIR}/$exe
    if ( ! -e ${RUN_DIR}/$exe ) then
       echo "ERROR: ${DART_DIR}/models/wrf/work/$exe not copied to ${RUN_DIR}"
       echo "Check DART build."
       exit 1
    endif
end

if ( -e ${DART_DIR}/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc ) then
    ${COPY} ${DART_DIR}/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc ${RUN_DIR}
    else
       echo "ERROR: ${DART_DIR}/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc does not exit"
       echo "Check DART directory."
       exit 2
    endif
endif

# Put WRF executables and supporting files in proper place
${COPY} ${WRF_DM_SRC_DIR}/run/* ${RUN_DIR}/WRF_RUN
if ( ! -e ${RUN_DIR}/WRF_RUN/wrf.exe || ! -e ${RUN_DIR}/WRF_RUN/real.exe ) then
    echo "ERROR: real.exe or wrf.exe not copied into ${RUN_DIR}/WRF_RUN"
    echo "Check WRF build"
    exit 3
endif

# WRF namelist.input gets replaced 
${REMOVE} ${RUN_DIR}/WRF_RUN/namelist.input  || exit 4

# Put WRFDA executables and supporting files in proper place
${COPY} ${VAR_SRC_DIR}/var/build/da_wrfvar.exe ${RUN_DIR}/WRF_RUN/da_wrfvar.exe
if ( ! -e ${RUN_DIR}/WRF_RUN/da_wrfvar.exe ) then
   echo "ERROR: ${VAR_SRC_DIR}/var/build/da_wrfvar.exe not copied to ${RUN_DIR}/WRF_RUN/"
   echo "Check WRFDA build."
   exit 6
endif 

${COPY} ${VAR_SRC_DIR}/var/run/be.dat.cv3 ${RUN_DIR}/WRF_RUN/be.dat
if ( ! -e ${RUN_DIR}/WRF_RUN/be.dat ) then
   echo "ERROR: ${VAR_SRC_DIR}/var/run/be.dat.cv3 not found; cannot be copied to ${RUN_DIR}/WRF_RUN/"
   echo "Check WRFDA build."
   exit 7
endif 

# Put scripts in proper place 
${COPY} ${SHELL_SCRIPTS_DIR}/add_bank_perts.ncl    ${RUN_DIR} || exit 8
${COPY} ${SHELL_SCRIPTS_DIR}/new_advance_model.csh ${RUN_DIR} || exit 9

# Edit input.nml.template so that its ens_size is set to the same value as $NUM_ENS in param.csh
sed "s/ens_size.*/ens_size                 =$NUM_ENS,/g" ${DART_DIR}/models/wrf/tutorial/template/input.nml.template > ${RUN_DIR}/input.nml || exit 10

exit 0

