; ============================================================
; GraphX - Step 9
; 32-bit MASM + Win32 + OpenGL
;
; Features:
;   - Win32 application
;   - OpenGL rendering context
;   - Cartesian grid
;   - X / Y axes
;   - y = x^2
;   - x87 floating-point calculations
;   - Aspect-ratio-correct mathematical viewport
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

ShowWindow PROTO STDCALL :DWORD, :DWORD
UpdateWindow PROTO STDCALL :DWORD

GetMessageA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

TranslateMessage PROTO STDCALL :DWORD
DispatchMessageA PROTO STDCALL :DWORD

DefWindowProcA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

PostQuitMessage PROTO STDCALL :DWORD

ValidateRect PROTO STDCALL :DWORD, :DWORD
GetClientRect PROTO STDCALL :DWORD, :DWORD

GetDC PROTO STDCALL :DWORD

ReleaseDC PROTO STDCALL \
    :DWORD, :DWORD

ChoosePixelFormat PROTO STDCALL \
    :DWORD, :DWORD

SetPixelFormat PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

SwapBuffers PROTO STDCALL :DWORD


; ============================================================
; WGL PROTOTYPES
; ============================================================

wglCreateContext PROTO STDCALL :DWORD

wglMakeCurrent PROTO STDCALL \
    :DWORD, :DWORD

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

glEnd PROTO STDCALL

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

GRAPH_SAMPLES EQU 121

GRID_MIN EQU -30
GRID_MAX EQU 30


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
; WINDOW
; ============================================================

className db "GraphXWindowClass",0

windowTitle db \
    "GraphX - Aspect Correct Mathematical Viewport",0


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

axisRed   REAL4 0.92
axisGreen REAL4 0.92
axisBlue  REAL4 0.92


; ============================================================
; FUNCTION COLOR
; ============================================================

graphRed   REAL4 0.20
graphGreen REAL4 0.85
graphBlue  REAL4 0.35


; ============================================================
; MATHEMATICAL CONSTANTS
; ============================================================

floatZero REAL4 0.0
floatOne  REAL4 1.0

baseHalfRange REAL4 10.0


; ============================================================
; VIEWPORT
;
; The default mathematical view is based on:
;
;     center = (0,0)
;     half-range = 10
;
; Depending on the window aspect ratio, either X or Y expands.
; ============================================================

viewHalfX REAL4 10.0
viewHalfY REAL4 10.0

viewLeft   REAL4 -10.0
viewRight  REAL4  10.0
viewBottom REAL4 -10.0
viewTop    REAL4  10.0


; ============================================================
; OPENGL PROJECTION SCALE
;
; OpenGL normalized coordinates are -1..+1.
;
; scaleX = 1 / viewHalfX
; scaleY = 1 / viewHalfY
; ============================================================

viewScaleX REAL4 0.1
viewScaleY REAL4 0.1
viewScaleZ REAL4 1.0


; ============================================================
; GRAPH y = x^2
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
; GRAPH CALCULATION
; ============================================================

currentX REAL4 ?
currentY REAL4 ?


; ============================================================
; GRID CALCULATION
; ============================================================

gridIndex DWORD ?
gridCoord REAL4 ?


; ============================================================
; STRUCTURES
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
; UPDATE VIEW FOR ASPECT RATIO
;
; Purpose:
;
; Prevent mathematical graphs from stretching.
;
; Example:
;
; Square window:
;
;       X = -10 ... +10
;       Y = -10 ... +10
;
; Wide window:
;
;       X might become -14 ... +14
;       Y remains      -10 ... +10
;
; Tall window:
;
;       X remains      -10 ... +10
;       Y might become -14 ... +14
;
; This means:
;
;       1 X unit = 1 Y unit visually
;
; ============================================================

UpdateViewForAspect PROC


    ; --------------------------------------------------------
    ; Invalid/minimized dimensions?
    ; --------------------------------------------------------

    cmp clientW, 0
    je UpdateViewDone

    cmp clientH, 0
    je UpdateViewDone


    ; --------------------------------------------------------
    ; Determine which side needs expansion.
    ; --------------------------------------------------------

    mov eax, clientW

    cmp eax, clientH

    jae WindowIsWide


; ============================================================
; TALL WINDOW
;
; Keep:
;
;       X half range = 10
;
; Expand Y:
;
;       halfY = 10 * height / width
; ============================================================

WindowIsTall:


    ; viewHalfX = 10.0

    fld DWORD PTR baseHalfRange
    fstp DWORD PTR viewHalfX


    ; viewHalfY =
    ;
    ; 10.0 * clientH / clientW

    fld DWORD PTR baseHalfRange

    fimul DWORD PTR clientH

    fidiv DWORD PTR clientW

    fstp DWORD PTR viewHalfY


    jmp CalculateViewBounds


; ============================================================
; WIDE OR SQUARE WINDOW
;
; Keep:
;
;       Y half range = 10
;
; Expand X:
;
;       halfX = 10 * width / height
; ============================================================

WindowIsWide:


    ; viewHalfY = 10.0

    fld DWORD PTR baseHalfRange
    fstp DWORD PTR viewHalfY


    ; viewHalfX =
    ;
    ; 10.0 * clientW / clientH

    fld DWORD PTR baseHalfRange

    fimul DWORD PTR clientW

    fidiv DWORD PTR clientH

    fstp DWORD PTR viewHalfX


; ============================================================
; Calculate visible mathematical boundaries
; ============================================================

CalculateViewBounds:


    ; --------------------------------------------------------
    ; viewRight = +viewHalfX
    ; --------------------------------------------------------

    fld DWORD PTR viewHalfX

    fstp DWORD PTR viewRight


    ; --------------------------------------------------------
    ; viewLeft = -viewHalfX
    ; --------------------------------------------------------

    fld DWORD PTR viewHalfX

    fchs

    fstp DWORD PTR viewLeft


    ; --------------------------------------------------------
    ; viewTop = +viewHalfY
    ; --------------------------------------------------------

    fld DWORD PTR viewHalfY

    fstp DWORD PTR viewTop


    ; --------------------------------------------------------
    ; viewBottom = -viewHalfY
    ; --------------------------------------------------------

    fld DWORD PTR viewHalfY

    fchs

    fstp DWORD PTR viewBottom


; ============================================================
; Calculate projection scales
;
; scaleX = 1 / halfX
; scaleY = 1 / halfY
; ============================================================


    fld DWORD PTR floatOne

    fdiv DWORD PTR viewHalfX

    fstp DWORD PTR viewScaleX


    fld DWORD PTR floatOne

    fdiv DWORD PTR viewHalfY

    fstp DWORD PTR viewScaleY


UpdateViewDone:

    ret

UpdateViewForAspect ENDP


; ============================================================
; SETUP OPENGL VIEWPORT
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
; OpenGL default coordinates:
;
;       -1 ... +1
;
; GraphX coordinates:
;
;       -viewHalfX ... +viewHalfX
;       -viewHalfY ... +viewHalfY
;
; We scale mathematical coordinates into OpenGL space.
; ============================================================

SetupProjection PROC


    ; --------------------------------------------------------
    ; Projection matrix
    ; --------------------------------------------------------

    invoke glMatrixMode, GL_PROJECTION


    invoke glLoadIdentity


    ; --------------------------------------------------------
    ; Apply aspect-ratio-correct mathematical scaling.
    ; --------------------------------------------------------

    invoke glScalef, \
        DWORD PTR viewScaleX, \
        DWORD PTR viewScaleY, \
        DWORD PTR viewScaleZ


    ; --------------------------------------------------------
    ; Model-view matrix
    ; --------------------------------------------------------

    invoke glMatrixMode, GL_MODELVIEW


    invoke glLoadIdentity


    ret

SetupProjection ENDP


; ============================================================
; DRAW GRID
;
; Generate grid coordinates using an integer MASM loop.
;
; We currently support integer grid locations:
;
;       -30 ... +30
;
; Only the visible portion appears because OpenGL clips
; everything outside the viewport.
; ============================================================

DrawGrid PROC


    ; --------------------------------------------------------
    ; Set grid color.
    ; --------------------------------------------------------

    invoke glColor3f, \
        DWORD PTR gridRed, \
        DWORD PTR gridGreen, \
        DWORD PTR gridBlue


    invoke glBegin, GL_LINES


    ; --------------------------------------------------------
    ; Begin at -30.
    ; --------------------------------------------------------

    mov gridIndex, GRID_MIN


GridLoop:


    ; --------------------------------------------------------
    ; Don't draw the zero grid line.
    ;
    ; X and Y axes will be drawn brighter.
    ; --------------------------------------------------------

    cmp gridIndex, 0

    je GridNext


    ; --------------------------------------------------------
    ; Convert integer grid position to REAL4 using x87.
    ;
    ; gridCoord = float(gridIndex)
    ; --------------------------------------------------------

    fild DWORD PTR gridIndex

    fstp DWORD PTR gridCoord


    ; ========================================================
    ; VERTICAL GRID LINE
    ;
    ; (x, bottom)
    ;      |
    ;      |
    ; (x, top)
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewBottom


    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewTop


    ; ========================================================
    ; HORIZONTAL GRID LINE
    ;
    ; (left,y) ---------------- (right,y)
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR gridCoord


    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR gridCoord


GridNext:


    inc gridIndex


    cmp gridIndex, GRID_MAX

    jle GridLoop


    invoke glEnd


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
    ; (viewLeft,0) ----------- (viewRight,0)
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR floatZero


    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR floatZero


    ; ========================================================
    ; Y AXIS
    ;
    ; (0,viewBottom)
    ;        |
    ;        |
    ; (0,viewTop)
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR floatZero, \
        DWORD PTR viewBottom


    invoke glVertex2f, \
        DWORD PTR floatZero, \
        DWORD PTR viewTop


    invoke glEnd


    ret

DrawAxes ENDP


; ============================================================
; DRAW FUNCTION
;
;                 y = x^2
;
; Generated using the x87 floating-point unit.
; ============================================================

DrawFunction PROC


    push edi


    ; --------------------------------------------------------
    ; Function color.
    ; --------------------------------------------------------

    invoke glColor3f, \
        DWORD PTR graphRed, \
        DWORD PTR graphGreen, \
        DWORD PTR graphBlue


    ; --------------------------------------------------------
    ; currentX = -3.0
    ; --------------------------------------------------------

    fld DWORD PTR graphStartX

    fstp DWORD PTR currentX


    ; --------------------------------------------------------
    ; 121 samples
    ; --------------------------------------------------------

    mov edi, GRAPH_SAMPLES


    ; --------------------------------------------------------
    ; Connect every generated point.
    ; --------------------------------------------------------

    invoke glBegin, GL_LINE_STRIP


FunctionLoop:


    ; ========================================================
    ; Calculate:
    ;
    ;       y = x^2
    ;
    ; x87:
    ;
    ;       FLD  X
    ;       FMUL X
    ;       FSTP Y
    ; ========================================================

    fld DWORD PTR currentX

    fmul DWORD PTR currentX

    fstp DWORD PTR currentY


    ; --------------------------------------------------------
    ; Send (X,Y) to OpenGL.
    ; --------------------------------------------------------

    invoke glVertex2f, \
        DWORD PTR currentX, \
        DWORD PTR currentY


    ; ========================================================
    ; x = x + 0.05
    ; ========================================================

    fld DWORD PTR currentX

    fadd DWORD PTR graphStepX

    fstp DWORD PTR currentX


    dec edi

    jnz FunctionLoop


    invoke glEnd


    pop edi


    ret

DrawFunction ENDP


; ============================================================
; MAIN RENDERING PROCEDURE
; ============================================================

RenderScene PROC


    ; --------------------------------------------------------
    ; No OpenGL context?
    ; --------------------------------------------------------

    cmp hGLRC, 0

    je RenderDone


    ; --------------------------------------------------------
    ; Minimized?
    ; --------------------------------------------------------

    cmp clientW, 0

    je RenderDone


    cmp clientH, 0

    je RenderDone


    ; ========================================================
    ; 1. Clear frame
    ; ========================================================

    invoke glClear, GL_COLOR_BUFFER_BIT


    ; ========================================================
    ; 2. Configure projection
    ; ========================================================

    invoke SetupProjection


    ; ========================================================
    ; 3. Draw Cartesian grid
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
    ; 6. Present completed back buffer
    ; ========================================================

    invoke SwapBuffers, hDC


RenderDone:

    ret

RenderScene ENDP


; ============================================================
; INITIALIZE OPENGL
;
; EAX = 1 success
; EAX = 0 failure
; ============================================================

InitializeOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; Obtain Device Context
    ; ========================================================

    invoke GetDC, targetWnd


    test eax, eax

    jz OpenGLInitFailed


    mov hDC, eax


    ; ========================================================
    ; Configure Pixel Format Descriptor
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
    ; Choose pixel format
    ; ========================================================

    invoke ChoosePixelFormat, \
        hDC, \
        ADDR pfd


    test eax, eax

    jz OpenGLInitFailed


    mov pixelFormat, eax


    ; ========================================================
    ; Set pixel format
    ; ========================================================

    invoke SetPixelFormat, \
        hDC, \
        pixelFormat, \
        ADDR pfd


    test eax, eax

    jz OpenGLInitFailed


    ; ========================================================
    ; Create WGL rendering context
    ; ========================================================

    invoke wglCreateContext, hDC


    test eax, eax

    jz OpenGLInitFailed


    mov hGLRC, eax


    ; ========================================================
    ; Activate rendering context
    ; ========================================================

    invoke wglMakeCurrent, \
        hDC, \
        hGLRC


    test eax, eax

    jz OpenGLInitFailed


    ; ========================================================
    ; Background color
    ; ========================================================

    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


    ; ========================================================
    ; Initial client dimensions
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
    ; Calculate aspect-correct mathematical bounds
    ; ========================================================

    invoke UpdateViewForAspect


    ; ========================================================
    ; Configure OpenGL viewport
    ; ========================================================

    invoke SetupViewport


    mov eax, 1


    ret


OpenGLInitFailed:


    xor eax, eax


    ret

InitializeOpenGL ENDP


; ============================================================
; CLEANUP OPENGL
; ============================================================

CleanupOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; Rendering context
    ; ========================================================

    cmp hGLRC, 0

    je SkipContextCleanup


    invoke wglMakeCurrent, 0, 0


    invoke wglDeleteContext, hGLRC


    mov hGLRC, 0


SkipContextCleanup:


    ; ========================================================
    ; Device context
    ; ========================================================

    cmp hDC, 0

    je CleanupDone


    invoke ReleaseDC, \
        targetWnd, \
        hDC


    mov hDC, 0


CleanupDone:

    ret

CleanupOpenGL ENDP


; ============================================================
; WINDOW PROCEDURE
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
    ; Default Windows processing
    ; ========================================================

    invoke DefWindowProcA, \
        hWnd, \
        uMsg, \
        wParam, \
        lParam


    ret


; ============================================================
; PAINT
; ============================================================

WindowPaint:


    invoke RenderScene


    invoke ValidateRect, \
        hWnd, \
        0


    xor eax, eax


    ret


; ============================================================
; RESIZE
;
; LOWORD(lParam) = client width
; HIWORD(lParam) = client height
; ============================================================

WindowSize:


    ; --------------------------------------------------------
    ; Extract width.
    ; --------------------------------------------------------

    mov eax, lParam

    movzx ecx, ax

    mov clientW, ecx


    ; --------------------------------------------------------
    ; Extract height.
    ; --------------------------------------------------------

    mov eax, lParam

    shr eax, 16

    movzx ecx, ax

    mov clientH, ecx


    ; --------------------------------------------------------
    ; OpenGL might not exist during initial creation.
    ; --------------------------------------------------------

    cmp hGLRC, 0

    je WindowSizeFinished


    ; --------------------------------------------------------
    ; Recalculate mathematical viewport.
    ; --------------------------------------------------------

    invoke UpdateViewForAspect


    ; --------------------------------------------------------
    ; Update OpenGL pixel viewport.
    ; --------------------------------------------------------

    invoke SetupViewport


    ; --------------------------------------------------------
    ; Redraw.
    ; --------------------------------------------------------

    invoke RenderScene


WindowSizeFinished:


    xor eax, eax


    ret


; ============================================================
; WINDOWS BACKGROUND ERASE
; ============================================================

BackgroundHandled:


    mov eax, 1


    ret


; ============================================================
; WINDOW DESTROY
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
    ; Initialize x87 FPU
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
    ; Get executable instance
    ; ========================================================

    invoke GetModuleHandleA, 0


    mov hInstance, eax


    ; ========================================================
    ; Configure GraphX window class
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
    ; Standard arrow cursor
    ; ========================================================

    invoke LoadCursorA, \
        0, \
        IDC_ARROW


    mov windowClass.hCursor, eax


    ; OpenGL handles background rendering.

    mov windowClass.hbrBackground, 0


    ; No menu yet.

    mov windowClass.lpszMenuName, 0


    mov windowClass.lpszClassName, OFFSET className


    ; ========================================================
    ; Register GraphX window class
    ; ========================================================

    invoke RegisterClassExA, \
        ADDR windowClass


    test eax, eax

    jz RegistrationFailed


    ; ========================================================
    ; Create GraphX window
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
    ; Display GraphX
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