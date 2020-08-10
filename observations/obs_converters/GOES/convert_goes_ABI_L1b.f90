! DART software - Copyright UCAR. This open source software is provided
! by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

program convert_goes_ABI_L1b

! Program to read GOES-R (16/17) L1b radiances

use types_mod,        only : r8, deg2rad, PI
use obs_sequence_mod, only : obs_sequence_type, write_obs_seq, &
                             static_init_obs_sequence, destroy_obs_sequence, &
                             init_obs_sequence
use goes_ABI_L1b_mod, only : goes_ABI_map_type, goes_load_ABI_map, &
                             make_obs_sequence
use    utilities_mod, only : initialize_utilities, register_module, &
                             error_handler, finalize_utilities, E_ERR, E_MSG, &
                             find_namelist_in_file, check_namelist_read, &
                             do_nml_file, do_nml_term, set_filename_list, &
                             nmlfileunit

implicit none

! ----------------------------------------------------------------------
! Declare local parameters
! ----------------------------------------------------------------------

integer                 :: filecount
type(goes_ABI_map_type) :: map
type(obs_sequence_type)     :: seq

integer :: io, iunit, index

! version controlled file description for error handling, do not edit
character(len=*), parameter :: source   = 'convert_goes_ABI_L1b.f90'
character(len=*), parameter :: revision = ''
character(len=*), parameter :: revdate  = ''

! ----------------------------------------------------------------------
! Declare namelist parameters
! ----------------------------------------------------------------------

integer, parameter :: MAXFILES = 512

character(len=256) :: l1_files(MAXFILES) = ''
character(len=256) :: l1_file_list       = ''
character(len=256) :: outputfile         = ''

real(r8) :: lon1 =   0.0_r8,  &   !  lower longitude bound
            lon2 = 360.0_r8,  &   !  upper longitude bound
            lat1 = -90.0_r8,  &   !  lower latitude bound
            lat2 =  90.0_r8       !  upper latitude bound

integer  :: x_thin = 0
integer  :: y_thin = 0
integer  :: goes_num = 16
logical  :: reject_dqf_1 = .true.

real(r8) :: obs_err               ! the fixed obs error (std dev, in radiance units)
                                  ! TODO: make this more sophisticated

integer  :: i

namelist /convert_goes_ABI_L1b_nml/ l1_files, l1_file_list, &
                                    outputfile, &
                                    lon1, lon2, lat1, lat2, &
                                    x_thin, y_thin, goes_num, &
                                    reject_dqf_1, obs_err

! ----------------------------------------------------------------------
! start of executable program code
! ----------------------------------------------------------------------

call initialize_utilities('convert_goes_ABI_L1b')
call register_module(source,revision,revdate)

! Initialize the obs_sequence module ...

call static_init_obs_sequence()

!----------------------------------------------------------------------
! Read the namelist
!----------------------------------------------------------------------

call find_namelist_in_file('input.nml', 'convert_goes_ABI_L1b_nml', iunit)
read(iunit, nml = convert_goes_ABI_L1b_nml, iostat = io)
call check_namelist_read(iunit, io, 'convert_goes_ABI_L1b_nml')

! Record the namelist values used for the run ...
if (do_nml_file()) write(nmlfileunit, nml=convert_goes_ABI_L1b_nml)
if (do_nml_term()) write(    *      , nml=convert_goes_ABI_L1b_nml)


! when this routine returns, the l1_files variable will have
! all the filenames, regardless of which way they were specified.
filecount = set_filename_list(l1_files, l1_file_list, "convert_goes_ABI_L1b")

! for each input file
do index=1, filecount
   ! read from HDF file into a derived type that holds all the information
   call goes_load_ABI_map(l1_files(index), map)

   ! convert derived type information to DART sequence
   call make_obs_sequence(seq, map, lon1, lon2, lat1, lat2, &
                          x_thin, y_thin, goes_num, reject_dqf_1, obs_err)

   ! write the sequence to a disk file
   call write_obs_seq(seq, outputfile)

   ! release the sequence memory
   call destroy_obs_sequence(seq)
enddo

call error_handler(E_MSG, source, 'Finished successfully.',source,revision,revdate)
call finalize_utilities()

end program convert_goes_ABI_L1b

