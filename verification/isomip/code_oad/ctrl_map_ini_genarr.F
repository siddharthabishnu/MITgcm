#include "CTRL_OPTIONS.h"
#define PREVENT_TOO_COLD_TEMP

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
C     | local version for OpenAD exp. isomip
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
CML#include "FFIELDS.h"
#include "CTRL_SIZE.h"
#include "CTRL.h"
#include "CTRL_GENARR.h"
#include "CTRL_DUMMY.h"
#include "optim.h"

C     !INPUT/OUTPUT PARAMETERS:
C     == routine arguments ==
      INTEGER myThid

C     !FUNCTIONS:
      INTEGER  ILNBLNk
      EXTERNAL ILNBLNK

C     !LOCAL VARIABLES:
C     == local variables ==
      INTEGER bi,bj
      INTEGER i,j,k
      INTEGER il
      INTEGER iarr

      LOGICAL doglobalread
      LOGICAL ladinit
      CHARACTER*(MAX_LEN_FNAM) fnamebase
      CHARACTER*(MAX_LEN_FNAM) fnamegeneric
      _RL     fac
#ifdef ALLOW_GENARR2D_CONTROL
      _RL     tmpfld2d(1-OLx:sNx+OLx,1-OLy:sNy+OLy,   nSx,nSy)
#endif
#ifdef ALLOW_GENARR3D_CONTROL
      _RL     tmpfld3d(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
#endif
CEOP

      doglobalread = .FALSE.
      ladinit      = .FALSE.
      fac = 1. _d 0

#ifdef ALLOW_GENARR2D_CONTROL
C--   An example of connecting specific fields
C--   to 3 generic 2D control arrays
cc--->>>
cc--->>> COMPILE FAILURE IS DELIBERATE
cc--->>> BE SURE WHAT YOU ARE DOING AND CUSTOMIZE <<<---
cc--->>>
C--   generic - user-defined control vars
      DO iarr = 1, maxCtrlArr2D

C     These forcing control variables are constant in time for this
C     experiment, so that we can specify them here. Once we know how to
C     make OpenAD use the gentim2d controls, these should be handled via
C     ctrl_map_gentim2d.F
       DO bj=myByLo(myThid), myByHi(myThid)
        DO bi=myBxLo(myThid), myBxHi(myThid)
         DO j = 1,sNy
          DO i = 1,sNx
           tmpfld2d(i,j,bi,bj) = 0. _d 0
          ENDDO
         ENDDO
        ENDDO
       ENDDO
       fnamebase = xx_genarr2d_file(iarr)
       il=ILNBLNK( fnamebase )
       WRITE(fnamegeneric,'(2A,I10.10)')
     &     fnamebase(1:il),'.',optimcycle
       CALL ACTIVE_READ_XY ( fnamegeneric, tmpfld2d, 1,
     &                      doglobalread, ladinit, optimcycle,
     &                      myThid, xx_genarr2d_dummy(iarr) )
       IF ( iarr .EQ. 1 ) THEN
CML        DO bj=myByLo(myThid), myByHi(myThid)
CML         DO bi=myBxLo(myThid), myBxHi(myThid)
CML          DO j = 1,sNy
CML           DO i = 1,sNx
CML            qnet(i,j,bi,bj) = qnet(i,j,bi,bj)
CML     &           + fac*tmpfld2d(i,j,bi,bj)
CML           ENDDO
CML          ENDDO
CML         ENDDO
CML        ENDDO
       ELSEIF ( iarr .EQ. 2 ) THEN
CML        DO bj=myByLo(myThid), myByHi(myThid)
CML         DO bi=myBxLo(myThid), myBxHi(myThid)
CML          DO j = 1,sNy
CML           DO i = 1,sNx
CML            empmr(i,j,bi,bj) = empmr(i,j,bi,bj)
CML     &           + fac*tmpfld2d(i,j,bi,bj)
CML           ENDDO
CML          ENDDO
CML         ENDDO
CML        ENDDO
       ELSEIF ( iarr .EQ. 3 ) THEN
CML        DO bj=myByLo(myThid), myByHi(myThid)
CML         DO bi=myBxLo(myThid), myBxHi(myThid)
CML          DO j = 1,sNy
CML           DO i = 1,sNx
CML            fu(i,j,bi,bj) = fu(i,j,bi,bj)
CML     &           + fac*tmpfld2d(i,j,bi,bj)
CML           ENDDO
CML          ENDDO
CML         ENDDO
CML        ENDDO
       ELSEIF ( iarr .EQ. 4 ) THEN
CML        DO bj=myByLo(myThid), myByHi(myThid)
CML         DO bi=myBxLo(myThid), myBxHi(myThid)
CML          DO j = 1,sNy
CML           DO i = 1,sNx
CML            fv(i,j,bi,bj) = fv(i,j,bi,bj)
CML     &           + fac*tmpfld2d(i,j,bi,bj)
CML           ENDDO
CML          ENDDO
CML         ENDDO
CML        ENDDO
       ENDIF
C--   end iarr loop
      ENDDO
CML      _EXCH_XY_RS( qnet,  myThid )
CML      _EXCH_XY_RS( empmr, myThid )
CML      CALL EXCH_UV_XY_RS(fu,fv,.TRUE.,myThid)

#endif /* ALLOW_GENARR2D_CONTROL */

#ifdef ALLOW_GENARR3D_CONTROL
C--   An example of connecting specific fields
C--   to 3 generic 3D control arrays
cc--->>>
cc--->>> COMPILE FAILURE IS DELIBERATE
cc--->>> BE SURE WHAT YOU ARE DOING AND CUSTOMIZE <<<---
cc--->>>
cc

C--   generic - user-defined control vars
      DO iarr = 1, maxCtrlArr3D

       DO bj=myByLo(myThid), myByHi(myThid)
        DO bi=myBxLo(myThid), myBxHi(myThid)
         DO k = 1,Nr
          DO j = 1,sNy
           DO i = 1,sNx
            tmpfld3d(i,j,k,bi,bj) = 0. _d 0
           ENDDO
          ENDDO
         ENDDO
        ENDDO
       ENDDO
       fnamebase = xx_genarr3d_file(iarr)
       il=ILNBLNK( fnamebase )
       WRITE(fnamegeneric,'(2A,I10.10)')
     &     fnamebase(1:il),'.',optimcycle
       CALL ACTIVE_READ_XYZ( fnamegeneric, tmpfld3d, 1,
     &                       doglobalread, ladinit, optimcycle,
     &                       myThid, xx_genarr3d_dummy(iarr) )
       IF ( iarr .EQ. 1 ) THEN
        DO bj=myByLo(myThid), myByHi(myThid)
         DO bi=myBxLo(myThid), myBxHi(myThid)
          DO k = 1,Nr
           DO j = 1,sNy
            DO i = 1,sNx
             theta(i,j,k,bi,bj) = theta(i,j,k,bi,bj)
     &         + fac*tmpfld3d(i,j,k,bi,bj)
#ifdef PREVENT_TOO_COLD_TEMP
C     necessary to reproduce old results
             IF ( theta(i,j,k,bi,bj).LT.-2.0 _d 0 )
     &            theta(i,j,k,bi,bj) = -2.0 _d 0
#endif
            ENDDO
           ENDDO
          ENDDO
         ENDDO
        ENDDO
        CALL EXCH_3D_RL( theta, Nr, myThid )
       ELSEIF ( iarr .EQ. 2 ) THEN
        DO bj=myByLo(myThid), myByHi(myThid)
         DO bi=myBxLo(myThid), myBxHi(myThid)
          DO k = 1,Nr
           DO j = 1,sNy
            DO i = 1,sNx
             salt(i,j,k,bi,bj) = salt(i,j,k,bi,bj)
     &         + fac*tmpfld3d(i,j,k,bi,bj)
            ENDDO
           ENDDO
          ENDDO
         ENDDO
        ENDDO
        CALL EXCH_3D_RL( salt, Nr, myThid )
       ELSEIF ( iarr .EQ. 3 ) THEN
        DO bj=myByLo(myThid), myByHi(myThid)
         DO bi=myBxLo(myThid), myBxHi(myThid)
          DO k = 1,Nr
           DO j = 1,sNy
            DO i = 1,sNx
             diffKr(i,j,k,bi,bj) = diffKr(i,j,k,bi,bj)
     &         + fac*tmpfld3d(i,j,k,bi,bj)
            ENDDO
           ENDDO
          ENDDO
         ENDDO
        ENDDO
        CALL EXCH_3D_RL( diffKr, Nr, myThid )
       ENDIF

C--   end iarr loop
      ENDDO

#endif /* ALLOW_GENARR3D_CONTROL */

      RETURN
      END
