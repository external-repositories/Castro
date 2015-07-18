
  subroutine ca_react_state(lo,hi, &
                            state,s_lo,s_hi,   &
                            reaction_terms,r_lo,r_hi, &
                            time,dt_react)

      use eos_module
      use network           , only : nspec, naux
      use meth_params_module, only : NVAR, URHO, UMX, UMY, UMZ, UEDEN, UEINT, UTEMP, &
                                     UFS, UFX, small_dens, small_temp, allow_negative_energy
      use burner_module
      use bl_constants_module

      implicit none

      integer          :: lo(3), hi(3)
      integer          :: s_lo(3), s_hi(3)
      integer          :: r_lo(3), r_hi(3)
      double precision :: state(s_lo(1):s_hi(1),s_lo(2):s_hi(2),s_lo(3):s_hi(3),NVAR)
      double precision :: reaction_terms(r_lo(1):r_hi(1),r_lo(2):r_hi(2),r_lo(3):r_hi(3),nspec+2)
      double precision :: time, dt_react

      integer          :: i, j, k
      double precision :: rhoInv

      type (eos_t_3D) :: state_in
      type (eos_t_3D) :: state_out

      state_in  = eos_t_3D(lo,hi)
      state_out = eos_t_3D(lo,hi)

      do k = lo(3), hi(3)
         do j = lo(2), hi(2)
            do i = lo(1), hi(1)

               rhoInv = ONE / state(i,j,k,URHO)

               state_in % rho(i,j,k)   = state(i,j,k,URHO)
               state_in % T(i,j,k)     = state(i,j,k,UTEMP)
               state_in % e(i,j,k)     = state(i,j,k,UEINT) * rhoInv
               state_in % xn(i,j,k,:)  = state(i,j,k,UFS:UFS+nspec-1) * rhoInv
               state_in % aux(i,j,k,:) = state(i,j,k,UFX:UFX+naux-1) * rhoInv

            enddo
         enddo
      enddo

      call burner(state_in, state_out, dt_react, time)

      do k = lo(3), hi(3)
         do j = lo(2), hi(2)
            do i = lo(1), hi(1)

               ! Note that we want to update the total energy by taking the difference of the old
               ! rho*e and the new rho*e rather than adding rho*e to KE because we don't necessarily
               ! want to force here that rho * E = rho * e + rho * K where K is defined in terms of
               ! the momenta. If this is desired that can always be forced through reset_internal_energy.

               state(i,j,k,UEINT)           = state(i,j,k,URHO) * state_out % e(i,j,k)
               state(i,j,k,UEDEN)           = state(i,j,k,UEDEN) + state(i,j,k,URHO) * (state_out % e(i,j,k) - state_in % e(i,j,k))
               state(i,j,k,UFS:UFS+nspec-1) = state(i,j,k,URHO) * state_out % xn(i,j,k,:)
               state(i,j,k,UFX:UFX+naux -1) = state(i,j,k,URHO) * state_out % aux(i,j,k,:)
               state(i,j,k,UTEMP)           = state_out % T(i,j,k)

               if (i.ge.r_lo(1) .and. i.le.r_hi(1) .and. j.ge.r_lo(2) .and. j.le.r_hi(2) .and. &
                   k.ge.r_lo(3) .and. k.le.r_hi(3)) then
                  reaction_terms(i,j,k,1:nspec) = reaction_terms(i,j,k,1:nspec) &
                       + (state_out % xn(i,j,k,:) - state_in % xn(i,j,k,:))
                  reaction_terms(i,j,k,nspec+1) = reaction_terms(i,j,k,nspec+1) &
                       + (state_out % e(i,j,k) - state_in % e(i,j,k))
                  reaction_terms(i,j,k,nspec+2) = reaction_terms(i,j,k,nspec+2) &
                       + state(i,j,k,URHO) * (state_out % e(i,j,k) - state_in % e(i,j,k))
               endif

            enddo
         enddo
      enddo

  end subroutine ca_react_state
