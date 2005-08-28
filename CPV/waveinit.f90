!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!  Last modified: Sat Dec  4 07:03:35 MET 1999
!  ----------------------------------------------
!  BEGIN manual

MODULE wave_init

!  (describe briefly what this module does...)
!  ----------------------------------------------
!  routines in this module:
!  SUBROUTINE pw_rand_init(nbeg,cm,c0)
!  SUBROUTINE pw_atomic_init(nbeg,cm,c0)
!  ----------------------------------------------
!  END manual

! ...   include modules
        USE kinds

        IMPLICIT NONE
        SAVE

        PRIVATE

        PUBLIC :: pw_atomic_init


CONTAINS


   SUBROUTINE pw_rand_init(cm, c0, wfill, ce, wempt)

!  this routine sets the initial wavefunctions at random
!  ----------------------------------------------

! ... declare modules
      USE wave_functions, ONLY: gram, wave_rand_init
      USE wave_types, ONLY: wave_descriptor
      USE mp, ONLY: mp_sum
      USE mp_wave, ONLY: splitwf
      USE mp_global, ONLY: mpime, nproc, root
      USE reciprocal_vectors, ONLY: ig_l2g, ngw, ngwt
      USE io_base, ONLY: stdout
      USE control_flags, ONLY: force_pairing, gamma_only
      USE reciprocal_space_mesh, ONLY: gkmask_l

      IMPLICIT NONE

! ... declare module-scope variables

! ... declare subroutine arguments
      COMPLEX(DP), INTENT(OUT) :: cm(:,:,:,:), c0(:,:,:,:), ce(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: wfill, wempt

      REAL(DP) :: rranf
      EXTERNAL rranf

! ... declare other variables
      INTEGER :: ig_local
      INTEGER :: ntest, i, ig, j, ib, ik, ispin, nspin
      REAL(DP) ::  rranf1, rranf2, ampre, rsum
      REAL(DP) ::  rc0rc0, anorm
      COMPLEX(DP) :: ctmp
      COMPLEX(DP), ALLOCATABLE :: pwt( : )

! ... end of declarations
!  ----------------------------------------------

!
! ... Check array dimensions
!
      IF( ( SIZE( cm, 1 ) /= SIZE( c0, 1 ) ) .OR. &
          ( SIZE( cm, 2 ) /= SIZE( c0, 2 ) ) .OR. &
          ( SIZE( cm, 3 ) /= SIZE( c0, 3 ) ) .OR. &
          ( SIZE( cm, 4 ) /= SIZE( c0, 4 ) ) ) &
        CALL errore(' pw_rand_init ', ' wrong dimensions ', 1)

      IF( .NOT. force_pairing ) THEN
        IF( ( SIZE( ce, 1 ) /= SIZE( c0, 1 ) ) .OR. &
            ( SIZE( ce, 3 ) /= SIZE( c0, 3 ) ) .OR. &
            ( SIZE( ce, 4 ) /= SIZE( c0, 4 ) ) ) &
          CALL errore(' pw_rand_init ', ' wrong dimensions ', 3)
      END IF


! ... Reset them to zero
!
      cm = 0.0d0
      c0 = 0.0d0
      ce = 0.0d0

! ... initialize the wave functions in such a way that the values
! ... of the components are independent on the number of processors
!
      nspin = SIZE( cm, 4)
      IF( force_pairing ) nspin = 1

      ampre = 0.01d0
      ALLOCATE( pwt( ngwt ) )

      DO ispin = 1, nspin
          DO ik = 1, SIZE( cm, 3)
            CALL wave_rand_init( cm( :, :, ik, ispin ) )
            IF ( .NOT. gamma_only ) THEN
! ..  .       set to zero all elements outside the cutoff sphere
              DO ib = 1, SIZE( cm, 2 )
                cm(:, ib, ik, ispin) = cm(:, ib, ik, ispin) * gkmask_l(:,ik)
              END DO
            END IF
          END DO
      END DO

      DEALLOCATE( pwt )
    
! DEBUG
!        ctmp = SUM( cm )
!        CALL mp_sum( ctmp ) 
!        WRITE( stdout,*) ' *** Wave init check ', ctmp
! DEBUG

!
! ...   orthonormalize wave functions
!
      CALL gram( cm, wfill )

      c0 = cm

! DEBUG
!        ctmp = SUM( cm )
!        CALL mp_sum( ctmp ) 
!        WRITE( stdout,*) ' *** Wave init check ', ctmp
! DEBUG

      RETURN
   END SUBROUTINE pw_rand_init



!  ----------------------------------------------



   SUBROUTINE pw_atomic_init(cm, c0, wfill, ce, wempt)

      ! ... declare modules
      USE wave_types,    ONLY: wave_descriptor
      USE control_flags, ONLY: tatomicwfc
      USE io_global,     ONLY: ionode, stdout

      IMPLICIT NONE

      ! ... declare subroutine arguments
      COMPLEX(DP), INTENT(OUT) :: cm(:,:,:,:), c0(:,:,:,:), ce(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: wfill, wempt

      ! ... declare other variables

      ! ... end of declarations

      CALL pw_rand_init(cm, c0, wfill, ce, wempt)

      IF( ionode ) THEN
        WRITE( stdout, * )
        IF( tatomicwfc ) THEN
          WRITE( stdout, fmt = &
          & '(/,3X, "Wave Initialization: atomic initial wave-functions not yet implemented" )' )
        END IF
        WRITE( stdout, fmt = '(/,3X, "Wave Initialization: random initial wave-functions" )' )
      END IF

      RETURN
   END SUBROUTINE pw_atomic_init


END MODULE wave_init
