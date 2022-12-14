!! This module contains optimization subroutine and parametric model
module mod_minimize
  !! This module contains optimization subroutine and parametric model
  use mod_constants
  use mod_array
  use mod_optimize
  use mod_read_parameters

  implicit none
  
  private

  public :: minimize_spec, minimize
  
contains

  subroutine minimize_spec(n, m, x, lb, ub, line, dim_v, maxiter, iprint, n_rmsf)
    !! Minimize algorithn for a specturm
    implicit none      

    integer, intent(in) :: n
    integer, intent(in) :: n_rmsf
    integer, intent(in) :: m
    integer, intent(in) :: dim_v
    integer, intent(in) :: maxiter
    integer, intent(in) :: iprint

    real(xp), intent(in), dimension(:), allocatable :: lb, ub
    type(indata_s), intent(in) :: line

    real(xp), intent(in), dimension(:), allocatable :: x
    
    real(xp), parameter    :: factr  = 1.0d+7, pgtol  = 1.0d-5
    
    character(len=60)      :: task, csave
    logical                :: lsave(4)
    integer                :: isave(44)
    real(xp)               :: f
    real(xp)               :: dsave(29)
    integer,  dimension(:), allocatable  :: nbd, iwa
    real(xp), dimension(:), allocatable  :: g, wa

    real(xp), dimension(:), allocatable :: residual
    
    !     Allocate dynamic arrays
    allocate(nbd(n), g(n))
    allocate(iwa(3*n))
    allocate(wa(2*m*n + 5*n + 11*m*m + 8*m))

    allocate(residual(dim_v))
    residual = 0._xp

    ! Init nbd
    nbd = 2
    
    !     We now define the starting point.
    !     We start the iteration by initializing task.
    task = 'START'
    
    !     The beginning of the loop
    do while(task(1:2).eq.'FG'.or. task.eq.'NEW_X' .or. task.eq.'START') 
       
       !     This is the call to the L-BFGS-B code.
       call setulb (n, m, x, lb, ub, nbd, f, g, factr, pgtol, wa, iwa, task, iprint, csave, lsave, isave, dsave)
       
       if (task(1:2) .eq. 'FG') then          
          !     Compute function f and gradient g for the sample problem.
    
          call myresidual(x, line%p, residual, dim_v, n_rmsf)
          f = myfunc_spec(residual)          
          call mygrad_spec(n_rmsf, g, residual, x, dim_v)
          
       elseif (task(1:5) .eq. 'NEW_X') then
          !        1) Terminate if the total number of f and g evaluations
          !             exceeds maxiter.
          if (isave(34) .ge. maxiter) &
               task='STOP: TOTAL NO. of f AND g EVALUATIONS EXCEEDS LIMIT'
          
          !        2) Terminate if  |proj g|/(1+|f|) < 1.0d-10.            
          if (dsave(13) .le. 1.d-10*(1.0d0 + abs(f))) &
               task='STOP: THE PROJECTED GRADIENT IS SUFFICIENTLY SMALL'
       endif
    !     end of loop do while       
    end do

    deallocate(nbd, g)
    deallocate(iwa)
    deallocate(wa)
    deallocate(residual)
  end subroutine minimize_spec

  ! Minimize algorithn for a cube with regularization
  subroutine minimize(n, m, x, lb, ub, cube, dim_v, dim_y, dim_x, std_map, kernel, iprint, maxiter)
    implicit none      

    integer, intent(in) :: n
    integer, intent(in) :: m
    integer, intent(in) :: dim_v, dim_y, dim_x
    integer, intent(in) :: iprint
    integer, intent(in) :: maxiter
    
    type(indata), intent(in) :: cube
    real(xp), intent(in), dimension(:), allocatable :: lb, ub
    real(xp), intent(in), dimension(:,:), allocatable :: kernel
    real(xp), intent(in), dimension(:,:), allocatable :: std_map

    real(xp), intent(in), dimension(:), allocatable :: x
    
    real(xp), parameter    :: factr  = 1.0d+7, pgtol  = 1.0d-5
    
    character(len=60)      :: task, csave
    logical                :: lsave(4)
    integer                :: isave(44)
    real(xp)               :: f
    real(xp)               :: dsave(29)
    integer,  dimension(:), allocatable  :: nbd, iwa
    real(xp), dimension(:), allocatable  :: g, wa
    
    !     Allocate dynamic arrays
    allocate(nbd(n), g(n))
    allocate(iwa(3*n))
    allocate(wa(2*m*n + 5*n + 11*m*m + 8*m))

    f = 0._xp
    g = 0._xp

    ! Init nbd
    nbd = 2
    
    !     We now define the starting point.
    !     We start the iteration by initializing task.
    task = 'START'
    
    !     The beginning of the loop
    do while(task(1:2).eq.'FG'.or. task.eq.'NEW_X' .or. task.eq.'START') 
       
       !     This is the call to the L-BFGS-B code.
       call setulb (n, m, x, lb, ub, nbd, f, g, factr, pgtol, wa, iwa, task, iprint, csave, lsave, isave, dsave)
       
       if (task(1:2) .eq. 'FG') then          
          !     Compute function f and gradient g for the sample problem.
          call f_g_cube_fast_nopow(f, g, cube%p, x, dim_v, dim_y, dim_x, kernel, std_map)
          
       elseif (task(1:5) .eq. 'NEW_X') then
          !        1) Terminate if the total number of f and g evaluations
          !             exceeds maxiter.
          if (isave(34) .ge. maxiter) &
               task='STOP: TOTAL NO. of f AND g EVALUATIONS EXCEEDS LIMIT'
          
          !        2) Terminate if  |proj g|/(1+|f|) < 1.0d-10.            
          if (dsave(13) .le. 1.d-10*(1.0d0 + abs(f))) &
               task='STOP: THE PROJECTED GRADIENT IS SUFFICIENTLY SMALL'
       endif
    !     end of loop do while       
    end do

    deallocate(nbd, g)
    deallocate(iwa)
    deallocate(wa)
  end subroutine minimize

end module mod_minimize

  ! subroutine minimize_rmsf(n, m, x, lb, ub, line, dim_v, maxiter, iprint)
  !   !! Minimize algorithn for a specturm
  !   implicit none      

  !   integer, intent(in) :: n
  !   integer, intent(in) :: m
  !   integer, intent(in) :: dim_v
  !   integer, intent(in) :: maxiter
  !   integer, intent(in) :: iprint

  !   real(xp), intent(in), dimension(:), allocatable :: lb, ub
  !   real(xp), intent(in), dimension(:), allocatable :: line

  !   real(xp), intent(in), dimension(:), allocatable :: x
    
  !   real(xp), parameter    :: factr  = 1.0d+7, pgtol  = 1.0d-5
    
  !   character(len=60)      :: task, csave
  !   logical                :: lsave(4)
  !   integer                :: isave(44)
  !   real(xp)               :: f
  !   real(xp)               :: dsave(29)
  !   integer,  dimension(:), allocatable  :: nbd, iwa
  !   real(xp), dimension(:), allocatable  :: g, wa

  !   real(xp), dimension(:), allocatable :: residual
    
  !   !     Allocate dynamic arrays
  !   allocate(nbd(n), g(n))
  !   allocate(iwa(3*n))
  !   allocate(wa(2*m*n + 5*n + 11*m*m + 8*m))

  !   allocate(residual(dim_v))
  !   residual = 0._xp

  !   ! Init nbd
  !   nbd = 2
    
  !   !     We now define the starting point.
  !   !     We start the iteration by initializing task.
  !   task = 'START'
    
  !   !     The beginning of the loop
  !   do while(task(1:2).eq.'FG'.or. task.eq.'NEW_X' .or. task.eq.'START') 
       
  !      !     This is the call to the L-BFGS-B code.
  !      call setulb (n, m, x, lb, ub, nbd, f, g, factr, pgtol, wa, iwa, task, params%iprint, csave, lsave, isave, dsave)
       
  !      if (task(1:2) .eq. 'FG') then          
  !         !     Compute function f and gradient g for the sample problem.
    
  !         call myresidual_rmsf(x, line, residual, dim_v)
  !         f = myfunc_spec(residual)          
  !         call mygrad_rmsf(g, residual, x, dim_v)
  !         print*, x

  !      elseif (task(1:5) .eq. 'NEW_X') then
  !         !        1) Terminate if the total number of f and g evaluations
  !         !             exceeds maxiter.
  !         if (isave(34) .ge. maxiter) &
  !              task='STOP: TOTAL NO. of f AND g EVALUATIONS EXCEEDS LIMIT'
          
  !         !        2) Terminate if  |proj g|/(1+|f|) < 1.0d-10.            
  !         if (dsave(13) .le. 1.d-10*(1.0d0 + abs(f))) &
  !              task='STOP: THE PROJECTED GRADIENT IS SUFFICIENTLY SMALL'
  !      endif
  !   !     end of loop do while       
  !   end do

  !   deallocate(nbd, g)
  !   deallocate(iwa)
  !   deallocate(wa)
  !   deallocate(residual)
  ! end subroutine minimize_rmsf
