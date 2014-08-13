! ###############################################################
! #                                                             #
! #                    THE VECTOR LIDORT MODEL                  #
! #                                                             #
! #  (Vector LInearized Discrete Ordinate Radiative Transfer)   #
! #   -      --         -        -        -         -           #
! #                                                             #
! ###############################################################

! ###############################################################
! #                                                             #
! #  Author :      Robert. J. D. Spurr                          #
! #                                                             #
! #  Address :     RT Solutions, inc.                           #
! #                9 Channing Street                            #
! #                Cambridge, MA 02138, USA                     #
! #                Tel: (617) 492 1183                          #
! #                                                             #
! #  Email :       rtsolutions@verizon.net                      #
! #                                                             #
! #  Versions     :   2.0, 2.2, 2.3, 2.4, 2.4R, 2.4RT, 2.4RTC,  #
! #                   2.5, 2.6                                  #
! #  Release Date :   December 2005  (2.0)                      #
! #  Release Date :   March 2007     (2.2)                      #
! #  Release Date :   October 2007   (2.3)                      #
! #  Release Date :   December 2008  (2.4)                      #
! #  Release Date :   April 2009     (2.4R)                     #
! #  Release Date :   July 2009      (2.4RT)                    #
! #  Release Date :   October 2010   (2.4RTC)                   #
! #  Release Date :   March 2011     (2.5)                      #
! #  Release Date :   May 2012       (2.6)                      #
! #                                                             #
! #       NEW: TOTAL COLUMN JACOBIANS         (2.4)             #
! #       NEW: BPDF Land-surface KERNELS      (2.4R)            #
! #       NEW: Thermal Emission Treatment     (2.4RT)           #
! #       Consolidated BRDF treatment         (2.4RTC)          #
! #       f77/f90 Release                     (2.5)             #
! #       External SS / New I/O Structures    (2.6)             #
! #                                                             #
! ###############################################################

!    #####################################################
!    #                                                   #
!    #   This Version of VLIDORT comes with a GNU-style  #
!    #   license. Please read the license carefully.     #
!    #                                                   #
!    #####################################################

! ###############################################################
! #                                                             #
! # Subroutines in this Module                                  #
! #                                                             #
! #              HMULT_MASTER (master)                          #
! #                WHOLELAYER_HMULT                             #
! #                PARTLAYER_HMULT_UP                           #
! #                PARTLAYER_HMULT_DN                           #
! #                                                             #
! #              EMULT_MASTER (master)                          #
! #              EMULT_MASTER_OBSGEO (master)                   #
! #                                                             #
! ###############################################################


      MODULE vlidort_multipliers

      PRIVATE
      PUBLIC :: HMULT_MASTER, &
                EMULT_MASTER, &
                EMULT_MASTER_OBSGEO

      CONTAINS

      SUBROUTINE HMULT_MASTER ( &
        DO_UPWELLING, DO_DNWELLING, &
        N_USER_LEVELS, &
        PARTLAYERS_OUTFLAG, PARTLAYERS_OUTINDEX, &
        PARTLAYERS_LAYERIDX, NLAYERS, &
        N_USER_STREAMS, LOCAL_UM_START, &
        USER_SECANTS, &
        STERM_LAYERMASK_UP, STERM_LAYERMASK_DN, &
        DELTAU_VERT, T_DELT_EIGEN, &
        T_DELT_USERM, &
        K_REAL, K_COMPLEX, &
        HSINGO, ZETA_M, ZETA_P, &
        PARTAU_VERT, &
        T_UTUP_EIGEN, T_UTDN_EIGEN, &
        T_UTUP_USERM, T_UTDN_USERM, &
        HMULT_1, HMULT_2, &
        UT_HMULT_UU, UT_HMULT_UD, &
        UT_HMULT_DU, UT_HMULT_DD )

      USE VLIDORT_PARS

      IMPLICIT NONE

      LOGICAL, INTENT (IN) ::           DO_UPWELLING
      LOGICAL, INTENT (IN) ::           DO_DNWELLING
      INTEGER, INTENT (IN) ::           N_USER_LEVELS
      LOGICAL, INTENT (IN) ::           PARTLAYERS_OUTFLAG  ( MAX_USER_LEVELS )
      INTEGER, INTENT (IN) ::           PARTLAYERS_OUTINDEX ( MAX_USER_LEVELS )
      INTEGER, INTENT (IN) ::           PARTLAYERS_LAYERIDX ( MAX_PARTLAYERS )
      INTEGER, INTENT (IN) ::           NLAYERS
      INTEGER, INTENT (IN) ::           N_USER_STREAMS
      INTEGER, INTENT (IN) ::           LOCAL_UM_START
      DOUBLE PRECISION, INTENT (IN) ::  USER_SECANTS  ( MAX_USER_STREAMS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_UP ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_DN ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  DELTAU_VERT ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_EIGEN ( MAXEVALUES, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_USERM &
          ( MAXLAYERS, MAX_USER_STREAMS )
      INTEGER, INTENT (IN) ::           K_REAL ( MAXLAYERS )
      INTEGER, INTENT (IN) ::           K_COMPLEX ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           HSINGO &
          (MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_M &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_P &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  PARTAU_VERT ( MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTUP_EIGEN &
          ( MAXEVALUES, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_EIGEN &
          ( MAXEVALUES, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTUP_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )

      DOUBLE PRECISION, INTENT (OUT) :: HMULT_1 &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (OUT) :: HMULT_2 &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_HMULT_UU &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_HMULT_UD &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_HMULT_DU &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_HMULT_DD &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )

!  Local variables
!  ---------------

      INTEGER          :: N, UT, UTA

!  whole layer multipliers

      CALL WHOLELAYER_HMULT ( &
        NLAYERS, &
        N_USER_STREAMS, LOCAL_UM_START, &
        USER_SECANTS, &
        STERM_LAYERMASK_UP, STERM_LAYERMASK_DN, &
        DELTAU_VERT, T_DELT_EIGEN, &
        T_DELT_USERM, &
        K_REAL, K_COMPLEX, &
        HSINGO, ZETA_M, &
        ZETA_P, HMULT_1, &
        HMULT_2 )

!  partial layer multipliers

      DO UTA = 1, N_USER_LEVELS
        IF ( PARTLAYERS_OUTFLAG(UTA) ) THEN
          UT = PARTLAYERS_OUTINDEX(UTA)
          N  = PARTLAYERS_LAYERIDX(UT)
          IF ( DO_UPWELLING ) THEN
            CALL PARTLAYER_HMULT_UP ( &
              N, UT, &
              N_USER_STREAMS, LOCAL_UM_START, &
              USER_SECANTS, &
              DELTAU_VERT, PARTAU_VERT, &
              T_DELT_EIGEN, T_UTUP_EIGEN, &
              T_UTDN_EIGEN, T_UTUP_USERM, &
              K_REAL, K_COMPLEX, &
              HSINGO, ZETA_M, &
              ZETA_P, UT_HMULT_UU, &
              UT_HMULT_UD )
          END IF

          IF ( DO_DNWELLING ) THEN
            CALL PARTLAYER_HMULT_DN ( &
              N, UT, &
              N_USER_STREAMS, LOCAL_UM_START, &
              USER_SECANTS, &
              DELTAU_VERT, PARTAU_VERT, &
              T_DELT_EIGEN, T_UTUP_EIGEN, &
              T_UTDN_EIGEN, T_UTDN_USERM, &
              K_REAL, K_COMPLEX, &
              HSINGO, ZETA_M, &
              ZETA_P, UT_HMULT_DU, &
              UT_HMULT_DD )
          END IF
        ENDIF
      ENDDO

!  Finish

      RETURN
      END SUBROUTINE HMULT_MASTER

!

      SUBROUTINE WHOLELAYER_HMULT ( &
        NLAYERS, &
        N_USER_STREAMS, LOCAL_UM_START, &
        USER_SECANTS, &
        STERM_LAYERMASK_UP, STERM_LAYERMASK_DN, &
        DELTAU_VERT, T_DELT_EIGEN, &
        T_DELT_USERM, &
        K_REAL, K_COMPLEX, &
        HSINGO, ZETA_M, &
        ZETA_P, HMULT_1, &
        HMULT_2 )

      USE VLIDORT_PARS

      IMPLICIT NONE

      INTEGER, INTENT (IN) ::           NLAYERS
      INTEGER, INTENT (IN) ::           N_USER_STREAMS
      INTEGER, INTENT (IN) ::           LOCAL_UM_START
      DOUBLE PRECISION, INTENT (IN) ::  USER_SECANTS  ( MAX_USER_STREAMS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_UP ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_DN ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  DELTAU_VERT ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_EIGEN ( MAXEVALUES, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_USERM &
          ( MAXLAYERS, MAX_USER_STREAMS )
      INTEGER, INTENT (IN) ::           K_REAL ( MAXLAYERS )
      INTEGER, INTENT (IN) ::           K_COMPLEX ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           HSINGO &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_M &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_P &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )

      DOUBLE PRECISION, INTENT (OUT) :: HMULT_1 &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (OUT) :: HMULT_2 &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )

!  Local variables
!  ---------------

      INTEGER          :: UM, K, N, KO1, K0, K1, K2
      DOUBLE PRECISION :: UDEL, SM
      DOUBLE PRECISION :: ZDEL_R, ZUDEL_R, THETA_1_R, THETA_2_R
      DOUBLE PRECISION :: ZDEL_CR,    ZDEL_CI
      DOUBLE PRECISION :: THETA_1_CR, THETA_1_CI
      DOUBLE PRECISION :: THETA_2_CR, THETA_2_CI

!  Start loops over layers and user-streams
!   Only done if layers are flagged

!  Small numbers analysis, added 30 October 2007

      DO N = 1, NLAYERS

        IF ( STERM_LAYERMASK_UP(N).OR.STERM_LAYERMASK_DN(N) ) THEN
          DO UM = LOCAL_UM_START, N_USER_STREAMS

!  setup

            UDEL = T_DELT_USERM(N,UM)
            SM = USER_SECANTS(UM)

!  Get the real multipliers

            DO K = 1, K_REAL(N)
              ZDEL_R    = T_DELT_EIGEN(K,N)
              ZUDEL_R   = ZDEL_R * UDEL
              THETA_2_R = ONE    - ZUDEL_R
              THETA_1_R = ZDEL_R - UDEL
              IF ( HSINGO(K,UM,N) )THEN
                HMULT_1(K,UM,N) = SM * UDEL * DELTAU_VERT(N)
              ELSE
                HMULT_1(K,UM,N) = SM * THETA_1_R * ZETA_M(K,UM,N)
              ENDIF
              HMULT_2(K,UM,N) = SM * THETA_2_R * ZETA_P(K,UM,N)
            ENDDO

!  Get the complex multipliers

            KO1 = K_REAL(N) + 1
            DO K = 1, K_COMPLEX(N)
              K0 = 2*K - 2
              K1 = KO1 + K0
              K2 = K1  + 1
              ZDEL_CR    = T_DELT_EIGEN(K1,N)
              ZDEL_CI    = T_DELT_EIGEN(K2,N)
              THETA_2_CR = ONE - ZDEL_CR * UDEL
              THETA_2_CI =     - ZDEL_CI * UDEL
              THETA_1_CR = ZDEL_CR - UDEL
              THETA_1_CI = ZDEL_CI
              IF ( HSINGO(K1,UM,N) )THEN
                HMULT_1(K1,UM,N) = SM * UDEL * DELTAU_VERT(N)
                HMULT_1(K2,UM,N) = ZERO
              ELSE
                HMULT_1(K1,UM,N) = SM * &
                   ( THETA_1_CR * ZETA_M(K1,UM,N) - &
                     THETA_1_CI * ZETA_M(K2,UM,N) )
                HMULT_1(K2,UM,N) = SM * &
                   ( THETA_1_CR * ZETA_M(K2,UM,N) + &
                     THETA_1_CI * ZETA_M(K1,UM,N) )
              ENDIF
              HMULT_2(K1,UM,N) = SM * &
                   ( THETA_2_CR * ZETA_P(K1,UM,N) - &
                     THETA_2_CI * ZETA_P(K2,UM,N) )
              HMULT_2(K2,UM,N) = SM * &
                   ( THETA_2_CR * ZETA_P(K2,UM,N) + &
                     THETA_2_CI * ZETA_P(K1,UM,N) )
           ENDDO

!  Start loops over layers and user-streams

          ENDDO
        ENDIF
      ENDDO

!  Finish

      RETURN
      END SUBROUTINE WHOLELAYER_HMULT

!

      SUBROUTINE PARTLAYER_HMULT_UP ( &
        N, UT, &
        N_USER_STREAMS, LOCAL_UM_START, &
        USER_SECANTS, &
        DELTAU_VERT, PARTAU_VERT, &
        T_DELT_EIGEN, T_UTUP_EIGEN, &
        T_UTDN_EIGEN, T_UTUP_USERM, &
        K_REAL, K_COMPLEX, &
        HSINGO, ZETA_M, &
        ZETA_P, UT_HMULT_UU, &
        UT_HMULT_UD )

!  Partial layer INTEGRATED homogeneous solution MULTIPLIERS (Upwelling)

      USE VLIDORT_PARS

      IMPLICIT NONE

      INTEGER, INTENT (IN) ::           N, UT
      INTEGER, INTENT (IN) ::           N_USER_STREAMS
      INTEGER, INTENT (IN) ::           LOCAL_UM_START
      DOUBLE PRECISION, INTENT (IN) ::  USER_SECANTS  ( MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  DELTAU_VERT ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  PARTAU_VERT ( MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_EIGEN ( MAXEVALUES, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTUP_EIGEN &
          ( MAXEVALUES, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_EIGEN &
          ( MAXEVALUES, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTUP_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )
      INTEGER, INTENT (IN) ::           K_REAL ( MAXLAYERS )
      INTEGER, INTENT (IN) ::           K_COMPLEX ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           HSINGO &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_M &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_P &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )

      DOUBLE PRECISION, INTENT (INOUT) :: UT_HMULT_UU &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (INOUT) :: UT_HMULT_UD &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )

!  Local variables
!  ---------------

      INTEGER          :: UM, K, KO1, K0, K1, K2
      DOUBLE PRECISION :: UX_UP, SM, DX

!  real multipliers

      DOUBLE PRECISION :: ZDEL_R, ZX_UP_R, ZX_DN_R
      DOUBLE PRECISION :: THETA_DN_R, THETA_UP_R

!  complex multipliers

      DOUBLE PRECISION :: THETA_DN_CR, THETA_UP_CR
      DOUBLE PRECISION :: THETA_DN_CI, THETA_UP_CI
      DOUBLE PRECISION :: ZDEL_CR, ZX_UP_CR, ZX_DN_CR
      DOUBLE PRECISION :: ZDEL_CI, ZX_UP_CI, ZX_DN_CI

!  Partial layer multipliers

      DO UM = LOCAL_UM_START, N_USER_STREAMS

!  set-up

        UX_UP = T_UTUP_USERM(UT,UM)
        SM    = USER_SECANTS(UM)

!  real multipliers

        DO K = 1, K_REAL(N)
          ZDEL_R     = T_DELT_EIGEN(K,N)
          ZX_UP_R    = T_UTUP_EIGEN(K,UT)
          ZX_DN_R    = T_UTDN_EIGEN(K,UT)
          THETA_DN_R = ZX_DN_R - ZDEL_R * UX_UP
          THETA_UP_R = ZX_UP_R - UX_UP
          UT_HMULT_UD(K,UM,UT) = SM * THETA_DN_R * ZETA_P(K,UM,N)
          IF ( HSINGO(K,UM,N) )THEN
            DX = DELTAU_VERT(N) - PARTAU_VERT(UT)
            UT_HMULT_UU(K,UM,UT) = SM * UX_UP * DX
          ELSE
            UT_HMULT_UU(K,UM,UT) = SM * THETA_UP_R * ZETA_M(K,UM,N)
          ENDIF
        ENDDO

!  Complex multipliers

        KO1 = K_REAL(N) + 1

        DO K = 1, K_COMPLEX(N)

          K0 = 2*K - 2
          K1 = KO1 + K0
          K2 = K1  + 1

          ZDEL_CR     = T_DELT_EIGEN(K1,N)
          ZDEL_CI     = T_DELT_EIGEN(K2,N)
          ZX_UP_CR    = T_UTUP_EIGEN(K1,UT)
          ZX_UP_CI    = T_UTUP_EIGEN(K2,UT)
          ZX_DN_CR    = T_UTDN_EIGEN(K1,UT)
          ZX_DN_CI    = T_UTDN_EIGEN(K2,UT)

          THETA_DN_CR = ZX_DN_CR - ZDEL_CR * UX_UP
          THETA_DN_CI = ZX_DN_CI - ZDEL_CI * UX_UP
          THETA_UP_CR = ZX_UP_CR - UX_UP
          THETA_UP_CI = ZX_UP_CI

          UT_HMULT_UD(K1,UM,UT) = SM * &
                   ( THETA_DN_CR * ZETA_P(K1,UM,N) - &
                     THETA_DN_CI * ZETA_P(K2,UM,N) )
          UT_HMULT_UD(K2,UM,UT) = SM * &
                   ( THETA_DN_CR * ZETA_P(K2,UM,N) + &
                     THETA_DN_CI * ZETA_P(K1,UM,N) )
          IF ( HSINGO(K1,UM,N) )THEN
            DX = DELTAU_VERT(N) - PARTAU_VERT(UT)
            UT_HMULT_UU(K1,UM,UT) = SM * UX_UP * DX
            UT_HMULT_UU(K2,UM,UT) = ZERO
          ELSE
            UT_HMULT_UU(K1,UM,UT) = SM * &
                   ( THETA_UP_CR * ZETA_M(K1,UM,N) - &
                     THETA_UP_CI * ZETA_M(K2,UM,N) )
            UT_HMULT_UU(K2,UM,UT) = SM * &
                   ( THETA_UP_CR * ZETA_M(K2,UM,N) + &
                     THETA_UP_CI * ZETA_M(K1,UM,N) )
          ENDIF

        ENDDO
      ENDDO

!  Finish

      RETURN
      END SUBROUTINE PARTLAYER_HMULT_UP

!

      SUBROUTINE PARTLAYER_HMULT_DN ( &
        N, UT, &
        N_USER_STREAMS, LOCAL_UM_START, &
        USER_SECANTS, &
        DELTAU_VERT, PARTAU_VERT, &
        T_DELT_EIGEN, T_UTUP_EIGEN, &
        T_UTDN_EIGEN, T_UTDN_USERM, &
        K_REAL, K_COMPLEX, &
        HSINGO, ZETA_M, &
        ZETA_P, UT_HMULT_DU, &
        UT_HMULT_DD )

!  Partial layer INTEGRATED homogeneous solution MULTIPLIERS (Downwellin

      USE VLIDORT_PARS

      IMPLICIT NONE

      INTEGER, INTENT (IN) ::           N, UT
      INTEGER, INTENT (IN) ::           N_USER_STREAMS
      INTEGER, INTENT (IN) ::           LOCAL_UM_START
      DOUBLE PRECISION, INTENT (IN) ::  USER_SECANTS  ( MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  DELTAU_VERT ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  PARTAU_VERT ( MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_EIGEN ( MAXEVALUES, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTUP_EIGEN &
          ( MAXEVALUES, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_EIGEN &
          ( MAXEVALUES, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )
      INTEGER, INTENT (IN) ::           K_REAL ( MAXLAYERS )
      INTEGER, INTENT (IN) ::           K_COMPLEX ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           HSINGO &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_M &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  ZETA_P &
          ( MAXEVALUES, MAX_USER_STREAMS, MAXLAYERS )

      DOUBLE PRECISION, INTENT (INOUT) :: UT_HMULT_DU &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (INOUT) :: UT_HMULT_DD &
          ( MAXEVALUES, MAX_USER_STREAMS, MAX_PARTLAYERS )

!  Local variables
!  ---------------

      INTEGER          :: UM, K, KO1, K0, K1, K2
      DOUBLE PRECISION :: UX_DN, SM, DX

!  real multipliers

      DOUBLE PRECISION :: ZDEL_R, ZX_UP_R, ZX_DN_R
      DOUBLE PRECISION :: THETA_DN_R, THETA_UP_R

!  complex multipliers

      DOUBLE PRECISION :: THETA_DN_CR, THETA_UP_CR
      DOUBLE PRECISION :: THETA_DN_CI, THETA_UP_CI
      DOUBLE PRECISION :: ZDEL_CR, ZX_UP_CR, ZX_DN_CR
      DOUBLE PRECISION :: ZDEL_CI, ZX_UP_CI, ZX_DN_CI

!  Partial layer multipliers

      DO UM = LOCAL_UM_START, N_USER_STREAMS

!  set-up

        UX_DN = T_UTDN_USERM(UT,UM)
        SM    = USER_SECANTS(UM)

!  real multipliers

        DO K = 1, K_REAL(N)
          ZDEL_R     = T_DELT_EIGEN(K,N)
          ZX_UP_R    = T_UTUP_EIGEN(K,UT)
          ZX_DN_R    = T_UTDN_EIGEN(K,UT)
          THETA_DN_R = ZX_DN_R - UX_DN
          THETA_UP_R = ZX_UP_R - ZDEL_R * UX_DN
          IF ( HSINGO(K,UM,N) ) THEN
            DX = DELTAU_VERT(N) - PARTAU_VERT(UT)
            UT_HMULT_DD(K,UM,UT) = SM * UX_DN * DX
          ELSE
            UT_HMULT_DD(K,UM,UT) = SM * THETA_DN_R * ZETA_M(K,UM,N)
          ENDIF
          UT_HMULT_DU(K,UM,UT) = SM * THETA_UP_R * ZETA_P(K,UM,N)
        ENDDO

!  Complex multipliers

        KO1 = K_REAL(N) + 1

        DO K = 1, K_COMPLEX(N)

          K0 = 2*K - 2
          K1 = KO1 + K0
          K2 = K1  + 1

          ZDEL_CR     = T_DELT_EIGEN(K1,N)
          ZDEL_CI     = T_DELT_EIGEN(K2,N)
          ZX_UP_CR    = T_UTUP_EIGEN(K1,UT)
          ZX_UP_CI    = T_UTUP_EIGEN(K2,UT)
          ZX_DN_CR    = T_UTDN_EIGEN(K1,UT)
          ZX_DN_CI    = T_UTDN_EIGEN(K2,UT)

          THETA_DN_CR = ZX_DN_CR - UX_DN
          THETA_DN_CI = ZX_DN_CI
          THETA_UP_CR = ZX_UP_CR - ZDEL_CR * UX_DN
          THETA_UP_CI = ZX_UP_CI - ZDEL_CI * UX_DN

          IF ( HSINGO(K1,UM,N) )THEN
            DX = DELTAU_VERT(N) - PARTAU_VERT(UT)
            UT_HMULT_DD(K1,UM,UT) = SM * UX_DN * DX
            UT_HMULT_DD(K2,UM,UT) = ZERO
          ELSE
            UT_HMULT_DD(K1,UM,UT) = SM * &
                   ( THETA_DN_CR * ZETA_M(K1,UM,N) - &
                     THETA_DN_CI * ZETA_M(K2,UM,N) )
            UT_HMULT_DD(K2,UM,UT) = SM * &
                   ( THETA_DN_CR * ZETA_M(K2,UM,N) + &
                     THETA_DN_CI * ZETA_M(K1,UM,N) )
          ENDIF
          UT_HMULT_DU(K1,UM,UT) = SM * &
                   ( THETA_UP_CR * ZETA_P(K1,UM,N) - &
                     THETA_UP_CI * ZETA_P(K2,UM,N) )
          UT_HMULT_DU(K2,UM,UT) = SM * &
                   ( THETA_UP_CR * ZETA_P(K2,UM,N) + &
                     THETA_UP_CI * ZETA_P(K1,UM,N) )

        ENDDO
      ENDDO

!  Finish

      RETURN
      END SUBROUTINE PARTLAYER_HMULT_DN

!

      SUBROUTINE EMULT_MASTER ( &
        DO_UPWELLING, DO_DNWELLING, &
        NLAYERS, &
        LAYER_PIS_CUTOFF, NBEAMS, &
        N_USER_STREAMS, &
        USER_SECANTS, N_PARTLAYERS, &
        PARTLAYERS_LAYERIDX, STERM_LAYERMASK_UP, &
        STERM_LAYERMASK_DN, &
        DELTAU_VERT, PARTAU_VERT, &
        T_DELT_MUBAR, T_UTDN_MUBAR, &
        T_DELT_USERM, T_UTDN_USERM, &
        T_UTUP_USERM, ITRANS_USERM, &
        AVERAGE_SECANT, &
        EMULT_HOPRULE, &
        SIGMA_M, SIGMA_P, &
        EMULT_UP, EMULT_DN, &
        UT_EMULT_UP, UT_EMULT_DN )

!  Prepare multipliers for the Beam source terms

      USE VLIDORT_PARS

      IMPLICIT NONE

      LOGICAL, INTENT (IN) ::           DO_UPWELLING
      LOGICAL, INTENT (IN) ::           DO_DNWELLING
      INTEGER, INTENT (IN) ::           NLAYERS
      INTEGER, INTENT (IN) ::           LAYER_PIS_CUTOFF ( MAXBEAMS )
      INTEGER, INTENT (IN) ::           NBEAMS
      INTEGER, INTENT (IN) ::           N_USER_STREAMS
      DOUBLE PRECISION, INTENT (IN) ::  USER_SECANTS  ( MAX_USER_STREAMS )
      INTEGER, INTENT (IN) ::           N_PARTLAYERS
      INTEGER, INTENT (IN) ::           PARTLAYERS_LAYERIDX ( MAX_PARTLAYERS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_UP ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_DN ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  DELTAU_VERT ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  PARTAU_VERT ( MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_MUBAR ( MAXLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_MUBAR &
          ( MAX_PARTLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_USERM &
          ( MAXLAYERS, MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTUP_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  ITRANS_USERM &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (IN) ::  AVERAGE_SECANT ( MAXLAYERS, MAXBEAMS )

      LOGICAL, INTENT (OUT) ::          EMULT_HOPRULE &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: SIGMA_M &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: SIGMA_P &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: EMULT_UP &
          ( MAX_USER_STREAMS, MAXLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: EMULT_DN &
          ( MAX_USER_STREAMS, MAXLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_EMULT_UP &
          ( MAX_USER_STREAMS, MAX_PARTLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_EMULT_DN &
          ( MAX_USER_STREAMS, MAX_PARTLAYERS, MAXBEAMS )

!  local variables
!  ---------------

      INTEGER          :: N, UT, UM, IB
      DOUBLE PRECISION :: WDEL, WX, WUDEL, UDEL
      DOUBLE PRECISION :: DIFF, SB, SECMUM, SU, SD
      DOUBLE PRECISION :: UX_DN, UX_UP, WDEL_UXUP

!  L'Hopital's Rule flags for Downwelling EMULT
!  --------------------------------------------

      IF ( DO_DNWELLING ) THEN
       DO N = 1, NLAYERS
        IF ( STERM_LAYERMASK_DN(N) ) THEN
         DO IB = 1, NBEAMS
          SB = AVERAGE_SECANT(N,IB)
          DO UM = 1, N_USER_STREAMS
            DIFF = DABS ( USER_SECANTS(UM) - SB )
            IF ( DIFF .LT. HOPITAL_TOLERANCE ) THEN
              EMULT_HOPRULE(N,UM,IB) = .TRUE.
            ELSE
              EMULT_HOPRULE(N,UM,IB) = .FALSE.
            ENDIF
          ENDDO
         ENDDO
        ENDIF
       ENDDO
      ENDIF

!  sigma functions (all layers)
!  ----------------------------

      DO N = 1, NLAYERS
       DO IB = 1, NBEAMS
        SB = AVERAGE_SECANT(N,IB)
        DO UM = 1, N_USER_STREAMS
          SECMUM = USER_SECANTS(UM)
          SIGMA_P(N,UM,IB) = SB + SECMUM
          SIGMA_M(N,UM,IB) = SB - SECMUM
        ENDDO
       ENDDO
      ENDDO

!  upwelling External source function multipliers
!  ----------------------------------------------

      IF ( DO_UPWELLING ) THEN

!  whole layer

        DO N = 1, NLAYERS
         IF ( STERM_LAYERMASK_UP(N) ) THEN
          DO IB = 1, NBEAMS
            IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
              DO UM = 1, N_USER_STREAMS
                EMULT_UP(UM,N,IB) = ZERO
              ENDDO
            ELSE
              WDEL = T_DELT_MUBAR(N,IB)
              DO UM = 1, N_USER_STREAMS
                WUDEL = WDEL * T_DELT_USERM(N,UM)
                SU = ( ONE - WUDEL ) / SIGMA_P(N,UM,IB)
                EMULT_UP(UM,N,IB) = ITRANS_USERM(N,UM,IB) * SU
              ENDDO
            ENDIF
          ENDDO
         ENDIF
        ENDDO

!  Partial layer

        DO UT = 1, N_PARTLAYERS
         N  = PARTLAYERS_LAYERIDX(UT)
         DO IB = 1, NBEAMS
          IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
            DO UM = 1, N_USER_STREAMS
              UT_EMULT_UP(UM,UT,IB) = ZERO
            ENDDO
          ELSE
            WX   = T_UTDN_MUBAR(UT,IB)
            WDEL = T_DELT_MUBAR(N,IB)
            DO UM = 1, N_USER_STREAMS
              UX_UP = T_UTUP_USERM(UT,UM)
              WDEL_UXUP = UX_UP * WDEL
              SU = ( WX - WDEL_UXUP ) / SIGMA_P(N,UM,IB)
              UT_EMULT_UP(UM,UT,IB) = ITRANS_USERM(N,UM,IB) * SU
            ENDDO
          ENDIF
         ENDDO
        ENDDO

      ENDIF

!  downwelling External source function multipliers
!  ------------------------------------------------

!    .. Note use of L'Hopitals Rule
!       Retaining only the first order term

      IF ( DO_DNWELLING ) THEN

!  whole layer

        DO N = 1, NLAYERS
         IF ( STERM_LAYERMASK_DN(N) ) THEN
          DO IB = 1, NBEAMS
            IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
              DO UM = 1, N_USER_STREAMS
                EMULT_DN(UM,N,IB) = ZERO
              ENDDO
            ELSE
              WDEL = T_DELT_MUBAR(N,IB)
              DO UM = 1, N_USER_STREAMS
                UDEL = T_DELT_USERM(N,UM)
                IF ( EMULT_HOPRULE(N,UM,IB) ) THEN
                  SD = DELTAU_VERT(N) * UDEL             ! First order
! Second order    SD = SD*(ONE-HALF*DELTAU_VERT(N)*SIGMA_M(N,UM,IB))
                ELSE
                  SD = ( UDEL - WDEL ) / SIGMA_M(N,UM,IB)
                ENDIF
                EMULT_DN(UM,N,IB) = ITRANS_USERM(N,UM,IB) * SD
              ENDDO
            ENDIF
          ENDDO
         ENDIF
        ENDDO

!  Partial layer

        DO UT = 1, N_PARTLAYERS
         N  = PARTLAYERS_LAYERIDX(UT)
         DO IB = 1, NBEAMS
          IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
            DO UM = 1, N_USER_STREAMS
              UT_EMULT_DN(UM,UT,IB) = ZERO
            ENDDO
          ELSE
            WX   = T_UTDN_MUBAR(UT,IB)
            DO UM = 1, N_USER_STREAMS
              UX_DN = T_UTDN_USERM(UT,UM)
              IF ( EMULT_HOPRULE(N,UM,IB) ) THEN
                SD = PARTAU_VERT(UT) * UX_DN
              ELSE
                SD = ( UX_DN - WX ) / SIGMA_M(N,UM,IB)
              ENDIF
              UT_EMULT_DN(UM,UT,IB) = ITRANS_USERM(N,UM,IB) * SD
            ENDDO
          ENDIF
         ENDDO
        ENDDO

      ENDIF

!  Finish

      RETURN
      END SUBROUTINE EMULT_MASTER

!

      SUBROUTINE EMULT_MASTER_OBSGEO ( &
        DO_UPWELLING, DO_DNWELLING, &
        NLAYERS, &
        LAYER_PIS_CUTOFF, NBEAMS, &
        USER_SECANTS, N_PARTLAYERS, &
        PARTLAYERS_LAYERIDX, STERM_LAYERMASK_UP, &
        STERM_LAYERMASK_DN, &
        DELTAU_VERT, PARTAU_VERT, &
        T_DELT_MUBAR, T_UTDN_MUBAR, &
        T_DELT_USERM, T_UTDN_USERM, &
        T_UTUP_USERM, ITRANS_USERM, &
        AVERAGE_SECANT, &
        EMULT_HOPRULE, &
        SIGMA_M, SIGMA_P, &
        EMULT_UP, EMULT_DN, &
        UT_EMULT_UP, UT_EMULT_DN )

!  Prepare multipliers for the Beam source terms

      USE VLIDORT_PARS

      IMPLICIT NONE

      LOGICAL, INTENT (IN) ::           DO_UPWELLING
      LOGICAL, INTENT (IN) ::           DO_DNWELLING
      INTEGER, INTENT (IN) ::           NLAYERS
      INTEGER, INTENT (IN) ::           LAYER_PIS_CUTOFF ( MAXBEAMS )
      INTEGER, INTENT (IN) ::           NBEAMS
      DOUBLE PRECISION, INTENT (IN) ::  USER_SECANTS  ( MAX_USER_STREAMS )
      INTEGER, INTENT (IN) ::           N_PARTLAYERS
      INTEGER, INTENT (IN) ::           PARTLAYERS_LAYERIDX ( MAX_PARTLAYERS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_UP ( MAXLAYERS )
      LOGICAL, INTENT (IN) ::           STERM_LAYERMASK_DN ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  DELTAU_VERT ( MAXLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  PARTAU_VERT ( MAX_PARTLAYERS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_MUBAR ( MAXLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_MUBAR &
          ( MAX_PARTLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_DELT_USERM &
          ( MAXLAYERS, MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTDN_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  T_UTUP_USERM &
          ( MAX_PARTLAYERS, MAX_USER_STREAMS )
      DOUBLE PRECISION, INTENT (IN) ::  ITRANS_USERM &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (IN) ::  AVERAGE_SECANT ( MAXLAYERS, MAXBEAMS )

      LOGICAL, INTENT (OUT) ::          EMULT_HOPRULE &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: SIGMA_M &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: SIGMA_P &
          ( MAXLAYERS, MAX_USER_STREAMS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: EMULT_UP &
          ( MAX_USER_STREAMS, MAXLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: EMULT_DN &
          ( MAX_USER_STREAMS, MAXLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_EMULT_UP &
          ( MAX_USER_STREAMS, MAX_PARTLAYERS, MAXBEAMS )
      DOUBLE PRECISION, INTENT (OUT) :: UT_EMULT_DN &
          ( MAX_USER_STREAMS, MAX_PARTLAYERS, MAXBEAMS )

!  local variables
!  ---------------

      INTEGER          :: N, UT, UM, IB, LUM
      DOUBLE PRECISION :: WDEL, WX, WUDEL, UDEL
      DOUBLE PRECISION :: DIFF, SB, SECMUM, SU, SD
      DOUBLE PRECISION :: UX_DN, UX_UP, WDEL_UXUP

!  Local user index

      LUM = 1

!  L'Hopital's Rule flags for Downwelling EMULT
!  --------------------------------------------

      IF ( DO_DNWELLING ) THEN
       DO N = 1, NLAYERS
        IF ( STERM_LAYERMASK_DN(N) ) THEN
         DO IB = 1, NBEAMS
           SB = AVERAGE_SECANT(N,IB)
           DIFF = DABS ( USER_SECANTS(IB) - SB )
           IF ( DIFF .LT. HOPITAL_TOLERANCE ) THEN
             EMULT_HOPRULE(N,LUM,IB) = .TRUE.
           ELSE
             EMULT_HOPRULE(N,LUM,IB) = .FALSE.
           ENDIF
         ENDDO
        ENDIF
       ENDDO
      ENDIF

!  sigma functions (all layers)
!  ----------------------------

      DO N = 1, NLAYERS
       DO IB = 1, NBEAMS
         SB = AVERAGE_SECANT(N,IB)
         SECMUM = USER_SECANTS(IB)
         SIGMA_P(N,LUM,IB) = SB + SECMUM
         SIGMA_M(N,LUM,IB) = SB - SECMUM
       ENDDO
      ENDDO

!  upwelling External source function multipliers
!  ----------------------------------------------

      IF ( DO_UPWELLING ) THEN

!  whole layer

        DO N = 1, NLAYERS
         IF ( STERM_LAYERMASK_UP(N) ) THEN
          DO IB = 1, NBEAMS
            IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
              EMULT_UP(LUM,N,IB) = ZERO
            ELSE
              WDEL = T_DELT_MUBAR(N,IB)
              WUDEL = WDEL * T_DELT_USERM(N,IB)
              SU = ( ONE - WUDEL ) / SIGMA_P(N,LUM,IB)
              EMULT_UP(LUM,N,IB) = ITRANS_USERM(N,LUM,IB) * SU
            ENDIF
          ENDDO
         ENDIF
        ENDDO

!  Partial layer

        DO UT = 1, N_PARTLAYERS
         N  = PARTLAYERS_LAYERIDX(UT)
         DO IB = 1, NBEAMS
          IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
            UT_EMULT_UP(LUM,UT,IB) = ZERO
          ELSE
            WX   = T_UTDN_MUBAR(UT,IB)
            WDEL = T_DELT_MUBAR(N,IB)
            UX_UP = T_UTUP_USERM(UT,IB)
            WDEL_UXUP = UX_UP * WDEL
            SU = ( WX - WDEL_UXUP ) / SIGMA_P(N,LUM,IB)
            UT_EMULT_UP(LUM,UT,IB) = ITRANS_USERM(N,LUM,IB) * SU
          ENDIF
         ENDDO
        ENDDO

      ENDIF

!  downwelling External source function multipliers
!  ------------------------------------------------

!    .. Note use of L'Hopitals Rule
!       Retaining only the first order term

      IF ( DO_DNWELLING ) THEN

!  whole layer

        DO N = 1, NLAYERS
         IF ( STERM_LAYERMASK_DN(N) ) THEN
          DO IB = 1, NBEAMS
            IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
              EMULT_DN(LUM,N,IB) = ZERO
            ELSE
              WDEL = T_DELT_MUBAR(N,IB)
              UDEL = T_DELT_USERM(N,IB)
              IF ( EMULT_HOPRULE(N,LUM,IB) ) THEN
                SD = DELTAU_VERT(N) * UDEL ! First order
!               SD = SD*(ONE-HALF*DELTAU_VERT(N)*SIGMA_M(N,LUM,IB)) !Second order
              ELSE
                SD = ( UDEL - WDEL ) / SIGMA_M(N,LUM,IB)
              ENDIF
              EMULT_DN(LUM,N,IB) = ITRANS_USERM(N,LUM,IB) * SD
            ENDIF
          ENDDO
         ENDIF
        ENDDO

!  Partial layer

        DO UT = 1, N_PARTLAYERS
         N  = PARTLAYERS_LAYERIDX(UT)
         DO IB = 1, NBEAMS
          IF ( N .GT. LAYER_PIS_CUTOFF(IB) ) THEN
            UT_EMULT_DN(LUM,UT,IB) = ZERO
          ELSE
            WX    = T_UTDN_MUBAR(UT,IB)
            UX_DN = T_UTDN_USERM(UT,IB)
            IF ( EMULT_HOPRULE(N,LUM,IB) ) THEN
              SD = PARTAU_VERT(UT) * UX_DN
            ELSE
              SD = ( UX_DN - WX ) / SIGMA_M(N,LUM,IB)
            ENDIF
            UT_EMULT_DN(LUM,UT,IB) = ITRANS_USERM(N,LUM,IB) * SD
          ENDIF
         ENDDO
        ENDDO

      ENDIF

!  Finish

      RETURN
      END SUBROUTINE EMULT_MASTER_OBSGEO

      END MODULE vlidort_multipliers