#include "CTRL_OPTIONS.h"
#ifdef ALLOW_SHELFICE
# include "SHELFICE_OPTIONS.h"
#endif

CBOP
C     !ROUTINE: CTRL_MAP_INI_GENARR
C     !INTERFACE:
      SUBROUTINE CTRL_MAP_INI_GENARR( myThid )

C     !DESCRIPTION: \bv
C     *=================================================================
C     | SUBROUTINE CTRL_MAP_INI_GENARR
C     | Add the generic arrays of the
C     | control vector to the model state and update the tile halos.
C     | The control vector is defined in the header file "CTRL.h".
C     *=================================================================
C     \ev

C     !USES:
      IMPLICIT NONE

C     == global variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#include "FFIELDS.h"
#include "CTRL_SIZE.h"
#include "CTRL.h"
#include "optim.h"
#include "CTRL_DUMMY.h"
#include "CTRL_FIELDS.h"
#include "CTRL_GENARR.h"
#ifdef ALLOW_PTRACERS
# include "PTRACERS_SIZE.h"
# include "PTRACERS_PARAMS.h"
# include "PTRACERS_FIELDS.h"
#endif
#ifdef ALLOW_SHELFICE
# include "SHELFICE.h"
#endif

C     !INPUT/OUTPUT PARAMETERS:
C     == routine arguments ==
      INTEGER myThid

#if (defined (ALLOW_GENARR3D_CONTROL) && defined(ALLOW_PTRACERS))
C     !FUNCTIONS:
      INTEGER  ILNBLNK
      EXTERNAL ILNBLNK
#endif

C     !LOCAL VARIABLES:
C     == local variables ==
#if (defined (ALLOW_GENARR2D_CONTROL) || defined(ALLOW_GENARR3D_CONTROL))
      INTEGER iarr
#endif
#ifdef ALLOW_GENARR2D_CONTROL
      _RL     airTlev1(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL     airQlev1(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      INTEGER igen_etan,igen_bdrag,igen_geoth
# ifdef ALLOW_SHELFICE
      INTEGER igen_shiCoeffT, igen_shiCoeffS, igen_shiCDrag
      INTEGER i, j, bi, bj, k2
      LOGICAL dragThermoEqualMom
# else
      INTEGER i, j, bi, bj
# endif
#endif /* ALLOW_GENARR2D_CONTROL */
#ifdef ALLOW_GENARR3D_CONTROL
      INTEGER igen_theta0, igen_salt0
      INTEGER igen_kapgm, igen_kapredi, igen_diffkr
# if (defined (ALLOW_UVEL0_CONTROL) && defined (ALLOW_VVEL0_CONTROL))
      INTEGER igen_uvel0, igen_vvel0
# endif
# ifdef ALLOW_PTRACERS
      INTEGER iPtr, iLen
      INTEGER igen_ptr(PTRACERS_num)
# endif
#endif /* ALLOW_GENARR3D_CONTROL */
CEOP

#ifdef ALLOW_GENARR2D_CONTROL
C--   generic 2D control variables

      igen_etan=0
      igen_bdrag=0
      igen_geoth=0
#ifdef ALLOW_SHELFICE
      igen_shiCoeffT=0
      igen_shiCoeffS=0
      igen_shiCDrag=0
#endif
      DO iarr = 1, maxCtrlArr2D
       IF (xx_genarr2d_weight(iarr).NE.' ') THEN
        IF (xx_genarr2d_file(iarr)(1:7).EQ.'xx_etan')
     &     igen_etan=iarr
        IF (xx_genarr2d_file(iarr)(1:13).EQ.'xx_bottomdrag')
     &     igen_bdrag=iarr
        IF (xx_genarr2d_file(iarr)(1:13).EQ.'xx_geothermal')
     &     igen_geoth=iarr
#ifdef ALLOW_SHELFICE
# ifndef SHI_ALLOW_GAMMAFRICT
        IF (xx_genarr2d_file(iarr)(1:12).EQ.'xx_shicoefft')
     &     igen_shiCoeffT=iarr
        IF (xx_genarr2d_file(iarr)(1:12).EQ.'xx_shicoeffs')
     &     igen_shiCoeffS=iarr
# else
        IF (xx_genarr2d_file(iarr)(1:11).EQ.'xx_shicdrag')
     &     igen_shiCDrag=iarr
# endif
#endif
       ENDIF
      ENDDO

      IF (igen_etan.GT.0) THEN
        CALL CTRL_MAP_GENARR2D( etaN, igen_etan, myThid )
      ENDIF
#ifdef ALLOW_BOTTOMDRAG_CONTROL
      IF (igen_bdrag.GT.0)
     &  CALL CTRL_MAP_GENARR2D( bottomDragFld, igen_bdrag, myThid )
#endif
#ifdef ALLOW_GEOTHERMAL_FLUX
      IF (igen_geoth.GT.0)
     &  CALL CTRL_MAP_GENARR2D( geothermalFlux, igen_geoth, myThid )
#endif
#ifdef ALLOW_SHELFICE
# ifndef SHI_ALLOW_GAMMAFRICT
      IF (igen_shiCoeffT.GT.0)
     &  CALL CTRL_MAP_GENARR2D(shiTransCoeffT,igen_shiCoeffT,myThid)

      IF (igen_shiCoeffS.GT.0)
     &  CALL CTRL_MAP_GENARR2D(shiTransCoeffS,igen_shiCoeffS,myThid)

C--   xx_shiCoeffS not used, but shiCoeffT is adjusted by xx_shicoefft
      IF ((igen_shiCoeffS.EQ.0).AND.(igen_shiCoeffT.GT.0)) THEN
       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j = 1-OLy,sNy+OLy
          DO i = 1-OLx,sNx+OLx
           shiTransCoeffS(i,j,bi,bj) =
     &       SHELFICEsaltToHeatRatio*shiTransCoeffT(i,j,bi,bj)
          ENDDO
         ENDDO
        ENDDO
       ENDDO
C--   xx_shiCoeffT not used, but shiCoeffS is adjusted by xx_shicoeffs
      ELSEIF ((igen_shiCoeffT.EQ.0).AND.(igen_shiCoeffS.GT.0)) THEN
       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j = 1-OLy,sNy+OLy
          DO i = 1-OLx,sNx+OLx
           shiTransCoeffT(i,j,bi,bj) =
     &       shiTransCoeffS(i,j,bi,bj)/SHELFICEsaltToHeatRatio
          ENDDO
         ENDDO
        ENDDO
       ENDDO
      ENDIF
# else
      dragThermoEqualMom = .FALSE.
      IF (igen_shiCDrag.GT.0)
     &  CALL CTRL_MAP_GENARR2D(shiCDragFld,igen_shiCDrag,myThid)
C--     Set drag coefficient used in momentum equal to thermodynamic,
C--      u* drag coefficient
      DO k2 = 1, maxCtrlProc

       IF (xx_genarr2d_preproc_c(k2,igen_shiCDrag)(1:3).EQ.'mom')
     &    dragThermoEqualMom = .TRUE.
      ENDDO
      IF (dragThermoEqualMom) THEN
       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j = 1-OLy,sNy+OLy
          DO i = 1-OLx,sNx+OLx
           shiDragQuadFld(i,j,bi,bj) = shiCDragFld(i,j,bi,bj)
          ENDDO
         ENDDO
        ENDDO
       ENDDO
      ENDIF
# endif /* SHI_ALLOW_GAMMAFRICT */
#endif /* ALLOW_SHELFICE */
C--   begin customized code for experiment hs94.1x64x5
      DO bj=myByLo(myThid), myByHi(myThid)
       DO bi=myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy,sNy+OLy
         DO i = 1-OLx,sNx+OLx
          airTlev1(i,j,bi,bj) = theta(i,j,1,bi,bj)
          airQlev1(i,j,bi,bj) = salt (i,j,1,bi,bj)
         ENDDO
        ENDDO
       ENDDO
      ENDDO
      iarr = 1
      CALL CTRL_MAP_GENARR2D( airTlev1, iarr, myThid )
      iarr = 2
      CALL CTRL_MAP_GENARR2D( airQlev1, iarr, myThid )
      DO bj=myByLo(myThid), myByHi(myThid)
       DO bi=myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy,sNy+OLy
         DO i = 1-OLx,sNx+OLx
          theta(i,j,1,bi,bj) = airTlev1(i,j,bi,bj)
          salt (i,j,1,bi,bj) = airQlev1(i,j,bi,bj)
         ENDDO
        ENDDO
       ENDDO
      ENDDO
C---  end customized code

#endif /* ALLOW_GENARR2D_CONTROL */

#ifdef ALLOW_GENARR3D_CONTROL
C--   generic 3D control variables

      igen_theta0=0
      igen_salt0=0
      igen_kapgm=0
      igen_kapredi=0
      igen_diffkr=0
# if (defined (ALLOW_UVEL0_CONTROL) && defined (ALLOW_VVEL0_CONTROL))
      igen_uvel0=0
      igen_vvel0=0
# endif
# ifdef ALLOW_PTRACERS
      DO iPtr = 1, PTRACERS_num
        igen_ptr(iPtr) = 0
      ENDDO
# endif /* ALLOW_PTRACERS */
      DO iarr = 1, maxCtrlArr3D
       IF (xx_genarr3d_weight(iarr).NE.' ') THEN
        IF (xx_genarr3d_file(iarr)(1:8).EQ.'xx_theta')
     &     igen_theta0=iarr
        IF (xx_genarr3d_file(iarr)(1:7).EQ.'xx_salt')
     &     igen_salt0=iarr
        IF (xx_genarr3d_file(iarr)(1:8).EQ.'xx_kapgm')
     &     igen_kapgm=iarr
        IF (xx_genarr3d_file(iarr)(1:10).EQ.'xx_kapredi')
     &     igen_kapredi=iarr
        IF (xx_genarr3d_file(iarr)(1:9).EQ.'xx_diffkr')
     &     igen_diffkr=iarr
# if (defined (ALLOW_UVEL0_CONTROL) && defined (ALLOW_VVEL0_CONTROL))
        IF (xx_genarr3d_file(iarr)(1:7).EQ.'xx_uvel')
     &     igen_uvel0=iarr
        IF (xx_genarr3d_file(iarr)(1:7).EQ.'xx_vvel')
     &     igen_vvel0=iarr
# endif
# ifdef ALLOW_PTRACERS
        IF ( usePTRACERS ) THEN
          iLen = ILNBLNK(xx_genarr3d_file(iarr))
          IF ( iLen.EQ.7 .AND.
     &         xx_genarr3d_file(iarr)(1:6).EQ.'xx_ptr' ) THEN
            READ(xx_genarr3d_file(iarr)(7:7),*) iPtr
            IF ( iPtr.GE.1 .AND. iPtr.LE.PTRACERS_numInUse )
     &                  igen_ptr(iPtr) = iarr
          ENDIF
        ENDIF
# endif /* ALLOW_PTRACERS */
       ENDIF
      ENDDO

C--   begin customized code for experiment hs94.1x64x5
C     This is commented out to not interfer with the customized
C     for the genarr2d part. Alternatively, one could use
C     store directives to avoid additional recomputation warnings.
C     IF (igen_theta0.GT.0)
C    &  CALL CTRL_MAP_GENARR3D( theta, igen_theta0, myThid )
C     IF (igen_salt0.GT.0)
C    &  CALL CTRL_MAP_GENARR3D( salt, igen_salt0, myThid )
C---  end customized code
# ifdef ALLOW_KAPGM_CONTROL
      IF (igen_kapgm.GT.0)
     &  CALL CTRL_MAP_GENARR3D( kapGM, igen_kapgm, myThid )
# endif
# ifdef ALLOW_KAPREDI_CONTROL
      IF (igen_kapredi.GT.0)
     &  CALL CTRL_MAP_GENARR3D( kapRedi, igen_kapredi, myThid )
# endif
# if ( defined ALLOW_DIFFKR_CONTROL && defined ALLOW_3D_DIFFKR )
      IF (igen_diffkr.GT.0)
     &  CALL CTRL_MAP_GENARR3D( diffKr, igen_diffkr, myThid )
# endif

# ifdef ALLOW_PTRACERS
CADJ loop = parallel
      DO iPtr = 1, PTRACERS_num
        IF ( igen_ptr(iPtr).GT.0 ) THEN
          CALL CTRL_MAP_GENARR3D( pTracer(1-OLx,1-OLy,1,1,1,iPtr),
     &                            igen_ptr(iPtr), myThid )
        ENDIF
      ENDDO
# endif /* ALLOW_PTRACERS */

# if (defined (ALLOW_UVEL0_CONTROL) && defined (ALLOW_VVEL0_CONTROL))
      IF (igen_uvel0.GT.0 .AND. igen_vvel0.GT.0) THEN
        CALL CTRL_MAP_GENARR3D( uVel, igen_uvel0, myThid )
        CALL CTRL_MAP_GENARR3D( vVel, igen_vvel0, myThid )
        CALL EXCH_UV_XYZ_RL( uVel, vVel, .TRUE., myThid )
      ENDIF
# endif

#endif /* ALLOW_GENARR3D_CONTROL */

      RETURN
      END
