; ============================================================
; GraphX - Step 8
; 32-bit MASM + Win32 + OpenGL
;
; Current features:
;   - Native Win32 window
;   - OpenGL rendering context
;   - Cartesian coordinate system
;   - Grid
;   - X and Y axes
;   - First mathematical graph: y = x^2
;   - x87 floating-point computation
;
; Build:
;   ml /nologo /c /coff main.asm
;
; Link:
;   link /nologo /SUBSYSTEM:WINDOWS /ENTRY:start main.obj ^
;        user32.lib kernel32.lib gdi32.lib opengl32.lib ^
;        /OUT:C:\GraphX\build\GraphX.exe
; ============================================================

.686
.model flat, stdcall
option casemap:none


; ============================================================
; WIN32 API PROTOTYPES
; ============================================================

GetModuleHandleA PROTO STDCALL :DWORD
ExitProcess      PROTO STDCALL :DWORD

LoadCursorA      PROTO STDCALL :DWORD, :DWORD
RegisterClassExA PROTO STDCALL :DWORD

CreateWindowExA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD

ShowWindow       PROTO STDCALL :DWORD, :DWORD
UpdateWindow     PROTO STDCALL :DWORD

GetMessageA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

TranslateMessage PROTO STDCALL :DWORD
DispatchMessageA PROTO STDCALL :DWORD

DefWindowProcA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

PostQuitMessage PROTO STDCALL :DWORD

ValidateRect  PROTO STDCALL :DWORD, :DWORD
GetClientRect PROTO STDCALL :DWORD, :DWORD

GetDC     PROTO STDCALL :DWORD
ReleaseDC PROTO STDCALL :DWORD, :DWORD

ChoosePixelFormat PROTO STDCALL :DWORD, :DWORD
SetPixelFormat    PROTO STDCALL :DWORD, :DWORD, :DWORD

SwapBuffers PROTO STDCALL :DWORD


; ============================================================
; WGL PROTOTYPES
; ============================================================

wglCreateContext PROTO STDCALL :DWORD
wglMakeCurrent   PROTO STDCALL :DWORD, :DWORD
wglDeleteContext PROTO STDCALL :DWORD


; ============================================================
; OPENGL PROTOTYPES
; ============================================================

glClearColor PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

glClear PROTO STDCALL :DWORD

glViewport PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

glMatrixMode PROTO STDCALL :DWORD

glLoadIdentity PROTO STDCALL

glScalef PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

glColor3f PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

glBegin PROTO STDCALL :DWORD
glEnd   PROTO STDCALL

glVertex2f PROTO STDCALL \
    :DWORD, :DWORD


; ============================================================
; WIN32 CONSTANTS
; ============================================================

CS_VREDRAW EQU 0001h
CS_HREDRAW EQU 0002h
CS_OWNDC   EQU 0020h

WM_DESTROY    EQU 0002h
WM_SIZE       EQU 0005h
WM_PAINT      EQU 000Fh
WM_ERASEBKGND EQU 0014h

WS_OVERLAPPEDWINDOW EQU 00CF0000h
WS_CLIPCHILDREN     EQU 02000000h
WS_CLIPSIBLINGS     EQU 04000000h

CW_USEDEFAULT EQU 80000000h

SW_SHOWNORMAL EQU 1

IDC_ARROW EQU 32512


; ============================================================
; PIXEL FORMAT CONSTANTS
; ============================================================

PFD_DOUBLEBUFFER   EQU 00000001h
PFD_DRAW_TO_WINDOW EQU 00000004h
PFD_SUPPORT_OPENGL EQU 00000020h

PFD_TYPE_RGBA  EQU 0
PFD_MAIN_PLANE EQU 0


; ============================================================
; OPENGL CONSTANTS
; ============================================================

GL_COLOR_BUFFER_BIT EQU 00004000h

GL_LINES      EQU 0001h
GL_LINE_STRIP EQU 0003h

GL_MODELVIEW  EQU 1700h
GL_PROJECTION EQU 1701h


; ============================================================
; GRAPHX CONSTANTS
; ============================================================

GRID_COUNT    EQU 21
GRAPH_SAMPLES EQU 121


; ============================================================
; STRUCTURES
; ============================================================

WNDCLASSEX STRUCT 4

    cbSize          DWORD ?
    style           DWORD ?
    lpfnWndProc     DWORD ?
    cbClsExtra      DWORD ?
    cbWndExtra      DWORD ?

    hInstance       DWORD ?
    hIcon           DWORD ?
    hCursor         DWORD ?
    hbrBackground   DWORD ?

    lpszMenuName    DWORD ?
    lpszClassName   DWORD ?
    hIconSm         DWORD ?

WNDCLASSEX ENDS


MSG STRUCT 4

    hwnd     DWORD ?
    message  DWORD ?
    wParam   DWORD ?
    lParam   DWORD ?
    time     DWORD ?

    ptX      DWORD ?
    ptY      DWORD ?

MSG ENDS


RECT STRUCT 4

    left   DWORD ?
    top    DWORD ?
    right  DWORD ?
    bottom DWORD ?

RECT ENDS


PIXELFORMATDESCRIPTOR STRUCT 1

    nSize           WORD ?
    nVersion        WORD ?

    dwFlags         DWORD ?

    iPixelType      BYTE ?
    cColorBits      BYTE ?

    cRedBits        BYTE ?
    cRedShift       BYTE ?

    cGreenBits      BYTE ?
    cGreenShift     BYTE ?

    cBlueBits       BYTE ?
    cBlueShift      BYTE ?

    cAlphaBits      BYTE ?
    cAlphaShift     BYTE ?

    cAccumBits      BYTE ?
    cAccumRedBits   BYTE ?
    cAccumGreenBits BYTE ?
    cAccumBlueBits  BYTE ?
    cAccumAlphaBits BYTE ?

    cDepthBits      BYTE ?
    cStencilBits    BYTE ?
    cAuxBuffers     BYTE ?

    iLayerType      BYTE ?
    bReserved       BYTE ?

    dwLayerMask     DWORD ?
    dwVisibleMask   DWORD ?
    dwDamageMask    DWORD ?

PIXELFORMATDESCRIPTOR ENDS


; ============================================================
; INITIALIZED DATA
; ============================================================

.data


; ============================================================
; WINDOW INFORMATION
; ============================================================

className db "GraphXWindowClass",0

windowTitle db \
    "GraphX - First Function: y = x^2",0


; ============================================================
; BACKGROUND COLOR
; ============================================================

clearRed   REAL4 0.04
clearGreen REAL4 0.06
clearBlue  REAL4 0.10
clearAlpha REAL4 1.0


; ============================================================
; GRID COLOR
; ============================================================

gridRed   REAL4 0.18
gridGreen REAL4 0.22
gridBlue  REAL4 0.28


; ============================================================
; AXIS COLOR
; ============================================================

axisRed   REAL4 0.90
axisGreen REAL4 0.90
axisBlue  REAL4 0.90


; ============================================================
; GRAPH COLOR
; ============================================================

graphRed   REAL4 0.20
graphGreen REAL4 0.85
graphBlue  REAL4 0.35


; ============================================================
; MATHEMATICAL LIMITS
; ============================================================

mathZero REAL4 0.0

mathMin REAL4 -10.0
mathMax REAL4  10.0


; ============================================================
; PROJECTION SCALING
;
; -10 ... +10 mathematics
;
; becomes
;
; -1 ... +1 OpenGL coordinates
; ============================================================

mathScaleX REAL4 0.1
mathScaleY REAL4 0.1
mathScaleZ REAL4 1.0


; ============================================================
; GRID VALUES
; ============================================================

gridValues REAL4 \
    -10.0, \
     -9.0, \
     -8.0, \
     -7.0, \
     -6.0, \
     -5.0, \
     -4.0, \
     -3.0, \
     -2.0, \
     -1.0, \
      0.0, \
      1.0, \
      2.0, \
      3.0, \
      4.0, \
      5.0, \
      6.0, \
      7.0, \
      8.0, \
      9.0, \
     10.0


; ============================================================
; FIRST GRAPH
;
; y = x^2
;
; We graph:
;
; x = -3.0 to +3.0
;
; because:
;
; (-3)^2 = 9
; (+3)^2 = 9
;
; which fits inside our Y range -10 ... +10.
; ============================================================

graphStartX REAL4 -3.0

graphStepX REAL4 0.05


; ============================================================
; UNINITIALIZED DATA
; ============================================================

.data?


hInstance DWORD ?
hMainWnd  DWORD ?

hDC   DWORD ?
hGLRC DWORD ?

pixelFormat DWORD ?

clientW DWORD ?
clientH DWORD ?


; ============================================================
; GRAPH WORKING VALUES
; ============================================================

currentX REAL4 ?
currentY REAL4 ?


; ============================================================
; STRUCTURE INSTANCES
; ============================================================

windowClass WNDCLASSEX <>
messageData MSG <>
clientRect  RECT <>

pfd PIXELFORMATDESCRIPTOR <>


; ============================================================
; CODE
; ============================================================

.code


; ============================================================
; SETUP VIEWPORT
; ============================================================

SetupViewport PROC

    cmp clientW, 0
    je SetupViewportDone

    cmp clientH, 0
    je SetupViewportDone


    invoke glViewport, \
        0, \
        0, \
        clientW, \
        clientH


SetupViewportDone:

    ret

SetupViewport ENDP


; ============================================================
; SETUP MATHEMATICAL PROJECTION
;
; Mathematical coordinates:
;
;       -10 ... +10
;
; OpenGL normalized range:
;
;       -1 ... +1
;
; Therefore scale by:
;
;       0.1
; ============================================================

SetupProjection PROC

    invoke glMatrixMode, GL_PROJECTION

    invoke glLoadIdentity


    invoke glScalef, \
        DWORD PTR mathScaleX, \
        DWORD PTR mathScaleY, \
        DWORD PTR mathScaleZ


    invoke glMatrixMode, GL_MODELVIEW

    invoke glLoadIdentity

    ret

SetupProjection ENDP


; ============================================================
; DRAW CARTESIAN GRID
; ============================================================

DrawGrid PROC

    push esi
    push edi


    ; --------------------------------------------------------
    ; Grid color
    ; --------------------------------------------------------

    invoke glColor3f, \
        DWORD PTR gridRed, \
        DWORD PTR gridGreen, \
        DWORD PTR gridBlue


    invoke glBegin, GL_LINES


    ; --------------------------------------------------------
    ; Point ESI to our first REAL4 grid coordinate.
    ; --------------------------------------------------------

    mov esi, OFFSET gridValues

    mov edi, GRID_COUNT


GridLoop:

    ; Load current raw REAL4 value.

    mov eax, DWORD PTR [esi]


    ; --------------------------------------------------------
    ; Skip 0 because the axes are drawn separately.
    ; REAL4 +0.0 has all zero bits.
    ; --------------------------------------------------------

    test eax, eax

    jz SkipGridCoordinate


    ; ========================================================
    ; VERTICAL GRID LINE
    ;
    ; (x,-10)
    ;    |
    ;    |
    ; (x,+10)
    ; ========================================================

    invoke glVertex2f, \
        eax, \
        DWORD PTR mathMin


    mov eax, DWORD PTR [esi]


    invoke glVertex2f, \
        eax, \
        DWORD PTR mathMax


    ; ========================================================
    ; HORIZONTAL GRID LINE
    ;
    ; (-10,y) ---------------- (+10,y)
    ; ========================================================

    mov eax, DWORD PTR [esi]


    invoke glVertex2f, \
        DWORD PTR mathMin, \
        eax


    mov eax, DWORD PTR [esi]


    invoke glVertex2f, \
        DWORD PTR mathMax, \
        eax


SkipGridCoordinate:

    add esi, 4

    dec edi

    jnz GridLoop


    invoke glEnd


    pop edi
    pop esi

    ret

DrawGrid ENDP


; ============================================================
; DRAW X AND Y AXES
; ============================================================

DrawAxes PROC


    invoke glColor3f, \
        DWORD PTR axisRed, \
        DWORD PTR axisGreen, \
        DWORD PTR axisBlue


    invoke glBegin, GL_LINES


    ; ========================================================
    ; X AXIS
    ;
    ; (-10,0) ---------------- (+10,0)
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR mathMin, \
        DWORD PTR mathZero


    invoke glVertex2f, \
        DWORD PTR mathMax, \
        DWORD PTR mathZero


    ; ========================================================
    ; Y AXIS
    ;
    ; (0,-10)
    ;    |
    ;    |
    ; (0,+10)
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR mathZero, \
        DWORD PTR mathMin


    invoke glVertex2f, \
        DWORD PTR mathZero, \
        DWORD PTR mathMax


    invoke glEnd

    ret

DrawAxes ENDP


; ============================================================
; DRAW FIRST MATHEMATICAL FUNCTION
;
;             y = x^2
;
; This procedure demonstrates x87 floating-point computation.
;
; For every X:
;
;       Y = X * X
;
; then:
;
;       glVertex2f(X,Y)
;
; X begins at:
;
;       -3.0
;
; and increases by:
;
;       0.05
;
; We generate 121 points.
; ============================================================

DrawFunction PROC

    push edi


    ; ========================================================
    ; Set graph color
    ; ========================================================

    invoke glColor3f, \
        DWORD PTR graphRed, \
        DWORD PTR graphGreen, \
        DWORD PTR graphBlue


    ; ========================================================
    ; Reset X to graph starting position
    ; ========================================================

    fld DWORD PTR graphStartX

    fstp DWORD PTR currentX


    ; Number of samples.

    mov edi, GRAPH_SAMPLES


    ; ========================================================
    ; Start connected-line graph
    ; ========================================================

    invoke glBegin, GL_LINE_STRIP


GraphLoop:


    ; ========================================================
    ; Calculate:
    ;
    ;       y = x * x
    ;
    ; x87 sequence:
    ;
    ;       FLD currentX
    ;
    ; ST(0) = X
    ;
    ;       FMUL currentX
    ;
    ; ST(0) = X * X
    ;
    ;       FSTP currentY
    ; ========================================================

    fld DWORD PTR currentX

    fmul DWORD PTR currentX

    fstp DWORD PTR currentY


    ; ========================================================
    ; Send mathematical point to OpenGL:
    ;
    ;       (currentX,currentY)
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR currentX, \
        DWORD PTR currentY


    ; ========================================================
    ; Calculate next X:
    ;
    ;       x = x + 0.05
    ; ========================================================

    fld DWORD PTR currentX

    fadd DWORD PTR graphStepX

    fstp DWORD PTR currentX


    ; Next sample.

    dec edi

    jnz GraphLoop


    invoke glEnd


    pop edi

    ret

DrawFunction ENDP


; ============================================================
; MAIN OPENGL RENDERER
; ============================================================

RenderScene PROC


    ; --------------------------------------------------------
    ; OpenGL context doesn't exist?
    ; --------------------------------------------------------

    cmp hGLRC, 0

    je RenderSceneDone


    ; --------------------------------------------------------
    ; Window minimized?
    ; --------------------------------------------------------

    cmp clientW, 0

    je RenderSceneDone


    cmp clientH, 0

    je RenderSceneDone


    ; ========================================================
    ; 1. Clear previous frame
    ; ========================================================

    invoke glClear, GL_COLOR_BUFFER_BIT


    ; ========================================================
    ; 2. Prepare mathematical projection
    ; ========================================================

    invoke SetupProjection


    ; ========================================================
    ; 3. Draw grid
    ; ========================================================

    invoke DrawGrid


    ; ========================================================
    ; 4. Draw axes
    ; ========================================================

    invoke DrawAxes


    ; ========================================================
    ; 5. Draw y = x^2
    ; ========================================================

    invoke DrawFunction


    ; ========================================================
    ; 6. Display completed frame
    ; ========================================================

    invoke SwapBuffers, hDC


RenderSceneDone:

    ret

RenderScene ENDP


; ============================================================
; INITIALIZE OPENGL
;
; EAX:
;
;   1 = success
;   0 = failure
; ============================================================

InitializeOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; 1. Get Windows Device Context
    ; ========================================================

    invoke GetDC, targetWnd


    test eax, eax

    jz OpenGLInitFailed


    mov hDC, eax


    ; ========================================================
    ; 2. Pixel Format Descriptor
    ; ========================================================

    mov pfd.nSize, SIZEOF PIXELFORMATDESCRIPTOR

    mov pfd.nVersion, 1


    mov pfd.dwFlags, \
        PFD_DRAW_TO_WINDOW OR \
        PFD_SUPPORT_OPENGL OR \
        PFD_DOUBLEBUFFER


    mov pfd.iPixelType, PFD_TYPE_RGBA


    mov pfd.cColorBits, 32

    mov pfd.cDepthBits, 24


    mov pfd.iLayerType, PFD_MAIN_PLANE


    ; ========================================================
    ; 3. Choose pixel format
    ; ========================================================

    invoke ChoosePixelFormat, \
        hDC, \
        ADDR pfd


    test eax, eax

    jz OpenGLInitFailed


    mov pixelFormat, eax


    ; ========================================================
    ; 4. Set pixel format
    ; ========================================================

    invoke SetPixelFormat, \
        hDC, \
        pixelFormat, \
        ADDR pfd


    test eax, eax

    jz OpenGLInitFailed


    ; ========================================================
    ; 5. Create rendering context
    ; ========================================================

    invoke wglCreateContext, hDC


    test eax, eax

    jz OpenGLInitFailed


    mov hGLRC, eax


    ; ========================================================
    ; 6. Activate rendering context
    ; ========================================================

    invoke wglMakeCurrent, \
        hDC, \
        hGLRC


    test eax, eax

    jz OpenGLInitFailed


    ; ========================================================
    ; 7. Set background color
    ; ========================================================

    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


    ; ========================================================
    ; 8. Get initial client dimensions
    ; ========================================================

    invoke GetClientRect, \
        targetWnd, \
        ADDR clientRect


    mov eax, clientRect.right

    sub eax, clientRect.left

    mov clientW, eax


    mov eax, clientRect.bottom

    sub eax, clientRect.top

    mov clientH, eax


    ; ========================================================
    ; 9. Create OpenGL viewport
    ; ========================================================

    invoke SetupViewport


    mov eax, 1

    ret


OpenGLInitFailed:

    xor eax, eax

    ret

InitializeOpenGL ENDP


; ============================================================
; CLEAN UP OPENGL
; ============================================================

CleanupOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; Delete rendering context
    ; ========================================================

    cmp hGLRC, 0

    je SkipGLContextCleanup


    ; Detach active rendering context.

    invoke wglMakeCurrent, 0, 0


    ; Delete OpenGL context.

    invoke wglDeleteContext, hGLRC


    mov hGLRC, 0


SkipGLContextCleanup:


    ; ========================================================
    ; Release Device Context
    ; ========================================================

    cmp hDC, 0

    je CleanupOpenGLDone


    invoke ReleaseDC, \
        targetWnd, \
        hDC


    mov hDC, 0


CleanupOpenGLDone:

    ret

CleanupOpenGL ENDP


; ============================================================
; WINDOWS MESSAGE PROCEDURE
; ============================================================

WindowProc PROC STDCALL \
    hWnd:DWORD, \
    uMsg:DWORD, \
    wParam:DWORD, \
    lParam:DWORD


    ; ========================================================
    ; WM_PAINT
    ; ========================================================

    cmp uMsg, WM_PAINT

    je WindowPaint


    ; ========================================================
    ; WM_SIZE
    ; ========================================================

    cmp uMsg, WM_SIZE

    je WindowSize


    ; ========================================================
    ; WM_ERASEBKGND
    ; ========================================================

    cmp uMsg, WM_ERASEBKGND

    je BackgroundHandled


    ; ========================================================
    ; WM_DESTROY
    ; ========================================================

    cmp uMsg, WM_DESTROY

    je WindowDestroyed


    ; ========================================================
    ; Default Windows handling
    ; ========================================================

    invoke DefWindowProcA, \
        hWnd, \
        uMsg, \
        wParam, \
        lParam


    ret


; ============================================================
; WINDOW PAINT
; ============================================================

WindowPaint:

    invoke RenderScene


    invoke ValidateRect, \
        hWnd, \
        0


    xor eax, eax

    ret


; ============================================================
; WINDOW RESIZE
;
; LOWORD(lParam) = client width
; HIWORD(lParam) = client height
; ============================================================

WindowSize:


    ; ========================================================
    ; Extract width
    ; ========================================================

    mov eax, lParam

    movzx ecx, ax

    mov clientW, ecx


    ; ========================================================
    ; Extract height
    ; ========================================================

    mov eax, lParam

    shr eax, 16

    movzx ecx, ax

    mov clientH, ecx


    ; WM_SIZE may happen before OpenGL exists.

    cmp hGLRC, 0

    je WindowSizeDone


    invoke SetupViewport

    invoke RenderScene


WindowSizeDone:

    xor eax, eax

    ret


; ============================================================
; OPENGL HANDLES BACKGROUND
; ============================================================

BackgroundHandled:

    mov eax, 1

    ret


; ============================================================
; DESTROY WINDOW
; ============================================================

WindowDestroyed:

    invoke CleanupOpenGL, hWnd


    invoke PostQuitMessage, 0


    xor eax, eax

    ret


WindowProc ENDP


; ============================================================
; PROGRAM ENTRY POINT
; ============================================================

start:


    ; ========================================================
    ; Initialize x87 Floating Point Unit
    ; ========================================================

    finit


    ; ========================================================
    ; Initialize global handles
    ; ========================================================

    mov hDC, 0

    mov hGLRC, 0

    mov hMainWnd, 0


    mov clientW, 0

    mov clientH, 0


    ; ========================================================
    ; Get executable module
    ; ========================================================

    invoke GetModuleHandleA, 0


    mov hInstance, eax


    ; ========================================================
    ; Configure GraphX Window Class
    ; ========================================================

    mov windowClass.cbSize, SIZEOF WNDCLASSEX


    mov windowClass.style, \
        CS_HREDRAW OR \
        CS_VREDRAW OR \
        CS_OWNDC


    mov windowClass.lpfnWndProc, OFFSET WindowProc


    mov windowClass.cbClsExtra, 0

    mov windowClass.cbWndExtra, 0


    mov eax, hInstance

    mov windowClass.hInstance, eax


    mov windowClass.hIcon, 0

    mov windowClass.hIconSm, 0


    ; ========================================================
    ; Windows cursor
    ; ========================================================

    invoke LoadCursorA, \
        0, \
        IDC_ARROW


    mov windowClass.hCursor, eax


    ; OpenGL paints client area.

    mov windowClass.hbrBackground, 0


    ; No menu yet.

    mov windowClass.lpszMenuName, 0


    mov windowClass.lpszClassName, OFFSET className


    ; ========================================================
    ; Register GraphX Window Class
    ; ========================================================

    invoke RegisterClassExA, \
        ADDR windowClass


    test eax, eax

    jz RegistrationFailed


    ; ========================================================
    ; Create GraphX Window
    ; ========================================================

    invoke CreateWindowExA, \
        0, \
        ADDR className, \
        ADDR windowTitle, \
        WS_OVERLAPPEDWINDOW OR \
            WS_CLIPCHILDREN OR \
            WS_CLIPSIBLINGS, \
        CW_USEDEFAULT, \
        CW_USEDEFAULT, \
        1024, \
        768, \
        0, \
        0, \
        hInstance, \
        0


    test eax, eax

    jz WindowCreationFailed


    mov hMainWnd, eax


    ; ========================================================
    ; Initialize OpenGL
    ; ========================================================

    invoke InitializeOpenGL, hMainWnd


    test eax, eax

    jz OpenGLCreationFailed


    ; ========================================================
    ; Show GraphX
    ; ========================================================

    invoke ShowWindow, \
        hMainWnd, \
        SW_SHOWNORMAL


    invoke UpdateWindow, hMainWnd


    ; ========================================================
    ; Initial frame
    ; ========================================================

    invoke RenderScene


; ============================================================
; WINDOWS MESSAGE LOOP
; ============================================================

MessageLoop:


    invoke GetMessageA, \
        ADDR messageData, \
        0, \
        0, \
        0


    ; --------------------------------------------------------
    ; WM_QUIT
    ; --------------------------------------------------------

    cmp eax, 0

    je ProgramFinished


    ; --------------------------------------------------------
    ; GetMessage error
    ; --------------------------------------------------------

    cmp eax, -1

    je MessageLoopFailed


    invoke TranslateMessage, \
        ADDR messageData


    invoke DispatchMessageA, \
        ADDR messageData


    jmp MessageLoop


; ============================================================
; NORMAL EXIT
; ============================================================

ProgramFinished:

    mov eax, messageData.wParam


    invoke ExitProcess, eax


; ============================================================
; ERROR EXITS
; ============================================================

RegistrationFailed:

    invoke ExitProcess, 1


WindowCreationFailed:

    invoke ExitProcess, 2


OpenGLCreationFailed:

    invoke CleanupOpenGL, hMainWnd

    invoke ExitProcess, 3


MessageLoopFailed:

    invoke CleanupOpenGL, hMainWnd

    invoke ExitProcess, 4


END start