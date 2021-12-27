! Author: Zachary Haskins
! Date: 12/26/2021

! VECTOR ARRAY
! DOUBLES THE LENGTH OF THE ARRAY WHEN .EQ. CURRENT NUMBER OF ELEMENTS
! MAX NUMBER OF ELEMENTS (WITHOUT MAKEPRECISE()):      8GB RAM: 536870912, 16GB RAM: 1073741824
!
!
! OVERVIEW
!   INIT()          - ALLOCATES 4 BYTES OF SPACE
!   DESTROY()       - DEALLOCATES ARRAY
!   APPEND()        - ADDS AN ELEMENT IN THE POSITION AFTER THE LAST NUMBER, NOT THE END OF THE ARRAY
!   PREPEND()       - ADDS AN ELEMENT AT THE BEGINNING OF THE ARRAY. SHIFTS OVER ALL OTHER ELEMENTS TO THE RIGHT
!   PRINT()         - PRINT ALL NUMBERS PUT INTO THE ARRAY
!   GETSIZE()       - GET THE CURRENT NUMBER OF ELEMENTS ADDED
!   HAS()           - CHECK IF A VALUE IS IN THE ARRAY
!   GET()           - GET THE ELEMENT AT AN INDEX, RETURNS -999 IF NOT A VALID INDEX
!   GETMAXSIZE()    - GET THE MAX SIZE THE ARRAY CAN HOLD BEFORE DOUBLING IT'S SPACE
!   PRECISE()       - INSTEAD OF DOUBLING THE CURRENT MAXSIZE OF THE ARRAY WHEN THE LIMIT IS REACHED, IT ADDS 1 TO THE CURRENT SIZE, NOT WASTING ANY EXTRA MEMORY
!   MUTE()          - MUTES ALL PRINTS
!   SORT()          - SORTS THE VECTOR

MODULE I_VECTORMOD
    IMPLICIT NONE
    PRIVATE

    PUBLIC VECTOR

    TYPE::VECTOR
        INTEGER, ALLOCATABLE, DIMENSION(:)::ARR
        INTEGER::                           CURRENTSIZE = 0, MAXSIZE = 1, INDEX = 1, PANIC = -999
        LOGICAL, PRIVATE::                  PRECISE = .FALSE., M = .FALSE., CREATED = .FALSE.
    CONTAINS
        PROCEDURE::INIT, DESTROY, APPEND, PRINT, GETSIZE, HAS, PREPEND, GET, GETMAXSIZE, MAKEPRECISE
        PROCEDURE::HELP, MUTE, UNMUTE, READ, REPLACE, SORT
        PROCEDURE, PRIVATE::RESIZE
    END TYPE VECTOR

CONTAINS

    ! SUBROUTINES
    SUBROUTINE HELP(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(OUT)::SELF
        SELF%PANIC = -999 ! UNUSED
        PRINT*, 'INIT()         - ALLOCATES 4 BYTES OF SPACE (REQUIRED)'
        PRINT*, 'DESTROY()      - DEALLOCATES VECTOR'
        PRINT*, 'APPEND()       - ADDS AN ELEMENT IN THE POSITION AFTER THE LAST NUMBER, NOT THE END OF THE VECTOR'
        PRINT*, 'PREPEND()      - ADDS AN ELEMENT AT THE BEGINNING OF THE VECTOR. SHIFTS OVER ALL OTHER ELEMENTS TO THE RIGHT'
        PRINT*, 'PRINT()        - PRINT ALL NUMBERS PUT INTO THE VECTOR'
        PRINT*, 'GETSIZE()      - GET THE CURRENT NUMBER OF ELEMENTS ADDED'
        PRINT*, 'HAS()          - CHECK IF A VALUE IS IN THE VECTOR'
        PRINT*, 'GET()          - GET THE ELEMENT AT AN INDEX, RETURNS -999 IF NOT A VALID INDEX'
        PRINT*, 'GETMAXSIZE()   - GET THE MAX SIZE THE VECTOR CAN HOLD BEFORE DOUBLING ITS SPACE'
        PRINT*, 'MUTE()         - MUTES ALL PRINTS EXCEPT FOR CALLS'
        PRINT*, 'SORT()         - SORTS THE VECTOR'
        PRINT*, 'MAKE PRECISE() - INSTEAD OF DOUBLING THE CURRENT MAXSIZE OF THE VECTOR WHEN THE LIMIT IS REACHED,'
        PRINT*, '                 IT ADDS 1 TO THE CURRENT SIZE. THIS SAVES MEMORY BUT GREATLY REDUCES SPEED'
    END SUBROUTINE HELP

    SUBROUTINE INIT(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        ALLOCATE(SELF%ARR(1))
        IF(SELF%M .EQV. .FALSE.) THEN
            PRINT*, 'VECTOR CREATED'
            PRINT*, '---CALL HELP() TO VIEW DESCRIPTIONS OF FUNCTIONS---'
        END IF
        SELF%CREATED = .TRUE.
    END SUBROUTINE INIT

    SUBROUTINE DESTROY(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        IF(SELF%CREATED .EQV. .FALSE.) THEN
            IF(SELF%M .EQV. .FALSE.) PRINT*, '***CANNOT DESTROY VECTOR, NO MEMORY ALLOCATED***'
            RETURN
        END IF
        DEALLOCATE(SELF%ARR)
        IF(SELF%M .EQV. .FALSE.) THEN
            PRINT*,''
            PRINT*, '---ENDING INFORMATION---'
            PRINT*, 'ELEMENTS IN VECTOR:', SELF%CURRENTSIZE
            PRINT*, 'MAXSIZE:           ', SELF%MAXSIZE
            PRINT*, 'VECTOR DESTROYED'
        END IF
    END SUBROUTINE DESTROY

    SUBROUTINE SORT(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        INTEGER::I, J, TEMP
        DO I = 1, SELF%GETSIZE() - 1
            DO J = 1, SELF%GETSIZE() - i
                IF(SELF%ARR(J) .GT. SELF%ARR(J + 1)) THEN
                    PRINT*, 'SWAPPING: ', SELF%ARR(J), 'WITH: ', SELF%ARR(J + 1)
                    TEMP = SELF%ARR(J)
                    SELF%ARR(J) = SELF%ARR(J + 1)
                    SELF%ARR(J + 1) = TEMP
                END IF
            END DO
        END DO
    END SUBROUTINE SORT

    SUBROUTINE REPLACE(SELF, INDEX, VALUE)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        INTEGER::INDEX, VALUE
        IF(SELF%CREATED .EQV. .FALSE.) THEN
            IF(SELF%M .EQV. .FALSE.) PRINT*, '***CANNOT REPLACE ELEMENT, NO MEMORY ALLOCATED***'
            RETURN
        END IF
        IF(SELF%M .EQV. .FALSE.) PRINT*, 'REPLACING: ', SELF%ARR(INDEX), '           ->', VALUE
        SELF%ARR(INDEX) = VALUE
    END SUBROUTINE REPLACE

    SUBROUTINE READ(SELF, FILE)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        CHARACTER(LEN=*), INTENT(IN)::FILE
        INTEGER::DATA
        IF(SELF%CREATED .EQV. .FALSE.) THEN
            PRINT*, '***CANNOT READ FROM FILE, VECTOR NOT INITIALIZED***'
            RETURN
        END IF
        OPEN(10, FILE = FILE)
        DO WHILE(.TRUE.)
            READ(10, *, end = 999) DATA
            CALL SELF%APPEND(DATA)
        END DO
        999 CONTINUE
    END SUBROUTINE READ

    SUBROUTINE MUTE(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        SELF%M = .TRUE.
    END SUBROUTINE MUTE

    SUBROUTINE UNMUTE(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        SELF%M = .FALSE.
    END SUBROUTINE UNMUTE

    SUBROUTINE MAKEPRECISE(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        IF(SELF%M .EQV. .FALSE.) PRINT*, 'WARNING: MAKEPRECISE() WILL GREATLY SLOW DOWN THE VECTOR'
        SELF%PRECISE = .TRUE.
    END SUBROUTINE MAKEPRECISE

    SUBROUTINE APPEND(SELF, N)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        INTEGER::N
        IF(SELF%CREATED .EQV. .FALSE.) THEN
            IF(SELF%M .EQV. .FALSE.) PRINT*, '***MUST CALL INIT() BEFORE INSERTING ELEMENTS***'
            RETURN
        END IF
        IF(SELF%INDEX .GT. SELF%MAXSIZE) THEN
            CALL SELF%RESIZE()
        END IF
        SELF%ARR(SELF%INDEX) = N
        SELF%INDEX = SELF%INDEX + 1
        SELF%CURRENTSIZE = SELF%CURRENTSIZE + 1
        IF(SELF%M .EQV. .FALSE.) PRINT*, 'APPENDED:', N
    END SUBROUTINE APPEND

    SUBROUTINE PREPEND(SELF, N)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        INTEGER::I, N, TEMP1, TEMP
        PRINT*, 'PREPEND IS CURRENTLY BROKEN'
        RETURN
        TEMP = N
        IF(SELF%CREATED .EQV. .FALSE.) THEN
            IF(SELF%M .EQV. .FALSE.) PRINT*, '***MUST CALL INIT() BEFORE INSERTING ELEMENTS***'
            RETURN
        END IF
        IF(SELF%INDEX .GT. SELF%MAXSIZE) THEN
            CALL SELF%RESIZE()
        END IF
        DO I = 1, SELF%GETSIZE() + 1
            TEMP1 = SELF%ARR(I)
            SELF%ARR(I) = TEMP
            TEMP = TEMP1
        END DO
        SELF%CURRENTSIZE = SELF%CURRENTSIZE + 1
        IF(SELF%M .EQV. .FALSE.) PRINT*, 'PREPENDED: ', N
    END SUBROUTINE PREPEND

    SUBROUTINE PRINT(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(IN)::SELF
        INTEGER::I
        PRINT*,''
        PRINT*, '   ---PRINTING---'
        DO I = 1, SELF%CURRENTSIZE
            PRINT*, SELF%ARR(I)
        END DO
        PRINT*, ' ---END PRINTING---'
        PRINT*,''
    END SUBROUTINE PRINT

    SUBROUTINE RESIZE(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(INOUT)::SELF
        INTEGER::I, MULTIPLE
        INTEGER, DIMENSION(SELF%CURRENTSIZE)::NEWARR
        IF(SELF%PRECISE .EQV. .TRUE.) THEN
            ! MULTIPLE = MULTIPLE + (SELF%MAXSIZE + 1)
            MULTIPLE = SELF%CURRENTSIZE + 1
        ELSE
            MULTIPLE = SELF%MAXSIZE * 2
        END IF
        IF(SELF%M .EQV. .FALSE.) PRINT*, 'RESIZING'
        SELF%MAXSIZE = MULTIPLE
        DO I = 1, SELF%CURRENTSIZE
            NEWARR(I) = SELF%ARR(I)
        END DO
        DEALLOCATE(SELF%ARR)
        ALLOCATE(SELF%ARR(MULTIPLE))
        DO I = 1, SELF%CURRENTSIZE
            SELF%ARR(I) = NEWARR(I)
        END DO
    END SUBROUTINE RESIZE

    ! FUNCTIONS

    INTEGER FUNCTION GET(SELF, N)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(IN)::SELF
        INTEGER::N
        GET = SELF%PANIC
        IF(N .LE. SELF%MAXSIZE) THEN
            GET = SELF%ARR(N)
        END IF
    END FUNCTION GET

    INTEGER FUNCTION GETMAXSIZE(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(IN)::SELF
        GETMAXSIZE = SELF%MAXSIZE
    END FUNCTION

    INTEGER FUNCTION GETSIZE(SELF)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(IN)::SELF
        GETSIZE = SELF%CURRENTSIZE
    END FUNCTION GETSIZE

    LOGICAL FUNCTION HAS(SELF, N)
        IMPLICIT NONE
        CLASS(VECTOR), INTENT(IN)::SELF
        INTEGER::I, N
        HAS = .FALSE.
        DO I = 1, SELF%GETSIZE()
            IF(SELF%ARR(I) .EQ. N) THEN
                HAS = .TRUE.
                EXIT
            END IF
        END DO
    END FUNCTION HAS

END MODULE I_VECTORMOD
