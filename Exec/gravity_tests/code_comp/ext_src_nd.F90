subroutine ca_ext_src(lo, hi, &
     old_state, os_lo, os_hi, &
     new_state, ns_lo, ns_hi, &
     src, src_lo, src_hi, &
     problo, dx, time, dt) bind(C, name='ca_ext_src')

  use amrex_constants_module, only: ZERO, HALF, ONE, M_PI
  use meth_params_module, only : NVAR, NSRC, UEDEN, UEINT
  use probdata_module, only : heating_factor
  use amrex_fort_module, only : rt => amrex_real

  implicit none

  integer,  intent(in   ) :: lo(3), hi(3)
  integer,  intent(in   ) :: os_lo(3), os_hi(3)
  integer,  intent(in   ) :: ns_lo(3), ns_hi(3)
  integer,  intent(in   ) :: src_lo(3), src_hi(3)
  real(rt), intent(in   ) :: old_state(os_lo(1):os_hi(1),os_lo(2):os_hi(2),os_lo(3):os_hi(3),NVAR)
  real(rt), intent(in   ) :: new_state(ns_lo(1):ns_hi(1),ns_lo(2):ns_hi(2),ns_lo(3):ns_hi(3),NVAR)
  real(rt), intent(inout) :: src(src_lo(1):src_hi(1),src_lo(2):src_hi(2),src_lo(3):src_hi(3),NSRC)
  real(rt), intent(in   ) :: problo(3), dx(3)
  real(rt), intent(in   ), value :: time, dt

  integer          :: i,j, k
  real(rt)         :: y, fheat

  !$gpu

  src(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3),:) = 0.e0_rt

  do k = lo(3), hi(3)
     do j = lo(2), hi(2)
        y = problo(2) + (dble(j) + HALF) * dx(2) 

        if (y < 1.125e0_rt * 4.e8_rt) then 
            fheat = sin(8.e0_rt * M_PI * (y/ 4.e8_rt - ONE))

            do i = lo(1), hi(1)
    
               ! Source terms
               src(i,j,k,UEDEN) = heating_factor * fheat
               src(i,j,k,UEINT) = src(i,j,k,UEDEN)
    
            end do
        endif
     end do
  end do

end subroutine ca_ext_src
