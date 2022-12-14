!! This module read the input user parameters (parameters.txt file / data / noise if true)
module mod_rw_data
  !! This module read the input user parameters (parameters.txt file / data / noise if true)
  use mod_constants
  use mod_convert
  use mod_read_parameters
  use mod_fits

  implicit none

  type(indata) :: data
  
  private
  
  public :: get_data, read_cube, read_map, read_array, save_process, data

contains

  subroutine get_data()
    implicit none
    
    real(kind=4), allocatable, dimension(:,:,:) :: array
    real(xp), allocatable, dimension(:,:,:) :: cube
    real(kind=4), allocatable, dimension(:,:) :: array_rms
    real(xp), allocatable, dimension(:,:) :: rms
    integer :: dim_cube(3)
    
    call read_fits(params%filename_p, array)
    call roll_fits(array,cube)
    call read_fits2D(params%filename_noise, array_rms)
    call roll_fits2D(array_rms, rms)
    call read_array(params%filename_coeff, coeff)
    call read_array(params%filename_init, init)
    dim_cube = shape(cube)  
    allocate(data%rms(dim_cube(2),dim_cube(3)))
    data%p = cube
    data%rms = rms    
  end subroutine get_data


  subroutine read_cube(filename, cube)
    implicit none
    integer           :: ios=0, i
    integer           :: v, y, x 
    real(xp)          :: val
    integer           :: nv, ny, nx !cube dimension
    integer           :: nl
    character(len=512), intent(in) :: filename
    real(xp), intent(inout), dimension(:,:,:), allocatable :: cube

    open(unit=11, file=filename, action="read", status="old", iostat=ios)
    if (ios /= 0) stop "opening file error"
    
    read(11,fmt=*) nv, ny, nx
    nl = nv*ny*nx

    allocate(cube(nv,ny,nx))

    do i=1,nl
       read(11,fmt=*) v, y, x, val
       cube(v+1,y+1,x+1) = val
    enddo
    
    close(11)
  end subroutine read_cube

  
  subroutine read_map(filename, map)
    implicit none

    integer           :: ios=0, i
    integer           :: y,x 
    real(xp)          :: val
    integer           :: ny,nx
    integer           :: nl
    character(len=512), intent(in) :: filename
    real(xp), intent(inout), dimension(:,:), allocatable :: map

    open(unit=11, file=filename, action="read", status="old", iostat=ios)
    if (ios /= 0) stop "opening file error"
    
    read(11,fmt=*) ny, nx
    nl = ny*nx

    allocate(map(ny,nx))

    do i=1,nl
       read(11,fmt=*) y, x, val
       map(y+1,x+1) = val
    enddo
    
    close(11)
  end subroutine read_map


  subroutine read_array(filename, array)
    implicit none
    integer           :: ios=0, i
    integer           :: nl
    real(xp)          :: val
    character(len=512), intent(in) :: filename
    real(xp), intent(inout), dimension(:), allocatable :: array

    open(unit=11, file=filename, action="read", status="old", iostat=ios)
    if (ios /= 0) stop "opening file error"
    
    read(11,fmt=*) nl

    allocate(array(nl))

    do i=1,nl
       read(11,fmt=*) val
       array(i) = val
    enddo
    
    close(11)
  end subroutine read_array

  
  subroutine save_process(nside, n_gauss, grid, dim_yx, fileout)
    implicit none

    integer, intent(in) :: n_gauss    !! number of gaussian to fit
    integer, intent(in) :: dim_yx     !! spatial dimension
    real(xp), intent(in), dimension(:,:,:), allocatable :: grid !! parameters to optimize with cube mean at each iteration
    character(len=512), intent(in) :: fileout   !! name of the output result

    integer :: nside                    !! size of the reshaped data \(2^{nside}\)
    character(len=512) :: fileout_nside   !! name of the output at level nside

    integer :: ios=0 !! ios integer
    integer :: i     !! loop index
    integer :: j     !! loop index
    integer :: k     !! loop index

    fileout_nside = trim(fileout(:len_trim(fileout)-4)) // "_nside_" // trim(str(nside)) // ".dat"

    ! Open file
    open(unit=12, file=fileout_nside, action="write", iostat=ios)
    if (ios /= 0) stop "opening file error"

    write(12,fmt=*) "# i, j, A, mean, sigma"

    do i=1, dim_yx
       do j=1, dim_yx
          do k=1, n_gauss
             write(12,fmt=*) i-1, j-1, grid(1+((k-1)*3),i,j), grid(2+((k-1)*3),i,j), grid(3+((k-1)*3),i,j)
          enddo
       end do
    end do

    close(12)
  end subroutine save_process

end Module mod_rw_data
