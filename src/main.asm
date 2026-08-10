; ============================================================
; GraphX - Step 7
; 32-bit MASM + Win32 + OpenGL
;
; Features:
;   - Win32 application window
;   - OpenGL rendering context
;   - Resizable viewport
;   - Mathematical coordinates -10 to +10
;   - Cartesian grid
;   - X axis
;   - Y axis
;
; Assemble:
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
; Win32 API
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

ValidateRect PROTO STDCALL :DWORD, :DWORD
GetClientRect PROTO STDCALL :DWORD, :DWORD

GetDC       PROTO STDCALL :DWORD
ReleaseDC   PROTO STDCALL :DWORD, :DWORD

ChoosePixelFormat PROTO STDCALL :DWORD, :DWORD
SetPixelFormat    PROTO STDCALL :DWORD, :DWORD, :DWORD

SwapBuffers PROTO STDCALL :DWORD


; ============================================================
; WGL API
; ============================================================

wglCreateContext PROTO STDCALL :DWORD
wglMakeCurrent   PROTO STDCALL :DWORD, :DWORD
wglDeleteContext PROTO STDCALL :DWORD


; ============================================================
; OpenGL API
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
; Win32 constants
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
; Pixel format constants
; ============================================================

PFD_DOUBLEBUFFER   EQU 00000001h
PFD_DRAW_TO_WINDOW EQU 00000004h
PFD_SUPPORT_OPENGL EQU 00000020h

PFD_TYPE_RGBA  EQU 0
PFD_MAIN_PLANE EQU 0


; ============================================================
; OpenGL constants
; ============================================================

GL_COLOR_BUFFER_BIT EQU 00004000h

GL_LINES EQU 0001h

GL_MODELVIEW  EQU 1700h
GL_PROJECTION EQU 1701h


; ============================================================
; Other constants
; ============================================================

GRID_COUNT EQU 21


; ============================================================
; Structures
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
; Initialized data
; ============================================================

.data


; ============================================================
; Window strings
; ============================================================

className db "GraphXWindowClass",0

windowTitle db \
    "GraphX - Cartesian Grid",0


; ============================================================
; Background color
; ============================================================

clearRed   REAL4 0.04
clearGreen REAL4 0.06
clearBlue  REAL4 0.10
clearAlpha REAL4 1.0


; ============================================================
; Grid color
; ============================================================

gridRed   REAL4 0.18
gridGreen REAL4 0.22
gridBlue  REAL4 0.28


; ============================================================
; Axis color
; ============================================================

axisRed   REAL4 0.90
axisGreen REAL4 0.90
axisBlue  REAL4 0.90


; ============================================================
; Mathematical limits
; ============================================================

mathZero REAL4 0.0

mathMin REAL4 -10.0
mathMax REAL4  10.0


; ============================================================
; Coordinate scaling
;
; -10 .. +10 mathematical coordinates
; become
; -1 .. +1 OpenGL coordinates
; ============================================================

mathScaleX REAL4 0.1
mathScaleY REAL4 0.1
mathScaleZ REAL4 1.0


; ============================================================
; Cartesian grid positions
;
; We deliberately store these as REAL4 values so they can
; be passed directly to glVertex2f.
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
; Uninitialized data
; ============================================================

.data?


hInstance DWORD ?
hMainWnd  DWORD ?

hDC   DWORD ?
hGLRC DWORD ?

pixelFormat DWORD ?

clientW DWORD ?
clientH DWORD ?

windowClass WNDCLASSEX <>
messageData MSG <>
clientRect  RECT <>

pfd PIXELFORMATDESCRIPTOR <>


; ============================================================
; Code
; ============================================================

.code


; ============================================================
; SetupViewport
; ============================================================

SetupViewport PROC

    cmp clientW, 0
    je SetupViewportDone

    cmp clientH, 0
    je SetupViewportDone


    invoke glViewport, \
        0,              \
        0,              \
        clientW,        \
        clientH


SetupViewportDone:

    ret

SetupViewport ENDP


; ============================================================
; SetupProjection
;
; Converts mathematical values:
;
;     -10 .. +10
;
; into OpenGL:
;
;     -1 .. +1
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
; DrawGrid
;
; Draw vertical lines:
;
; x = -10
; x = -9
; ...
; x = 10
;
; And horizontal lines:
;
; y = -10
; y = -9
; ...
; y = 10
;
; We skip 0 because the X/Y axes will be drawn separately.
; ============================================================

DrawGrid PROC

    push esi
    push edi


    ; --------------------------------------------------------
    ; Set grid color
    ; --------------------------------------------------------

    invoke glColor3f, \
        DWORD PTR gridRed, \
        DWORD PTR gridGreen, \
        DWORD PTR gridBlue


    ; --------------------------------------------------------
    ; Start line rendering
    ; --------------------------------------------------------

    invoke glBegin, GL_LINES


    ; --------------------------------------------------------
    ; ESI = address of first REAL4 grid value
    ; EDI = number of values
    ; --------------------------------------------------------

    mov esi, OFFSET gridValues
    mov edi, GRID_COUNT


GridLoop:

    ; Current grid coordinate.

    mov eax, DWORD PTR [esi]


    ; --------------------------------------------------------
    ; Skip coordinate 0.
    ;
    ; REAL4 +0.0 = 00000000h
    ; --------------------------------------------------------

    test eax, eax
    jz SkipGridCoordinate


    ; ========================================================
    ; Vertical line
    ;
    ; (x, -10)
    ;     |
    ;     |
    ; (x, +10)
    ; ========================================================

    invoke glVertex2f, \
        eax, \
        DWORD PTR mathMin


    ; Reload because function calls can modify EAX.

    mov eax, DWORD PTR [esi]


    invoke glVertex2f, \
        eax, \
        DWORD PTR mathMax


    ; ========================================================
    ; Horizontal line
    ;
    ; (-10, y) ---------------- (+10, y)
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
; DrawAxes
; ============================================================

DrawAxes PROC


    ; --------------------------------------------------------
    ; Bright axis color
    ; --------------------------------------------------------

    invoke glColor3f, \
        DWORD PTR axisRed, \
        DWORD PTR axisGreen, \
        DWORD PTR axisBlue


    invoke glBegin, GL_LINES


    ; ========================================================
    ; X AXIS
    ;
    ; (-10,0) ----------------------------- (10,0)
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
; RenderScene
; ============================================================

RenderScene PROC


    ; OpenGL not initialized?

    cmp hGLRC, 0
    je RenderSceneDone


    ; Window minimized?

    cmp clientW, 0
    je RenderSceneDone

    cmp clientH, 0
    je RenderSceneDone


    ; ========================================================
    ; Clear frame
    ; ========================================================

    invoke glClear, GL_COLOR_BUFFER_BIT


    ; ========================================================
    ; Mathematical coordinate setup
    ; ========================================================

    invoke SetupProjection


    ; ========================================================
    ; Draw grid first
    ; ========================================================

    invoke DrawGrid


    ; ========================================================
    ; Draw axes over grid
    ; ========================================================

    invoke DrawAxes


    ; ========================================================
    ; Display back buffer
    ; ========================================================

    invoke SwapBuffers, hDC


RenderSceneDone:

    ret

RenderScene ENDP


; ============================================================
; InitializeOpenGL
;
; EAX = 1 success
; EAX = 0 failure
; ============================================================

InitializeOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; Get device context
    ; ========================================================

    invoke GetDC, targetWnd

    test eax, eax
    jz OpenGLInitFailed

    mov hDC, eax


    ; ========================================================
    ; Configure pixel format
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
    ; Create OpenGL rendering context
    ; ========================================================

    invoke wglCreateContext, hDC


    test eax, eax
    jz OpenGLInitFailed


    mov hGLRC, eax


    ; ========================================================
    ; Make context current
    ; ========================================================

    invoke wglMakeCurrent, \
        hDC, \
        hGLRC


    test eax, eax
    jz OpenGLInitFailed


    ; ========================================================
    ; Configure GraphX background
    ; ========================================================

    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


    ; ========================================================
    ; Obtain client dimensions
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


    invoke SetupViewport


    mov eax, 1

    ret


OpenGLInitFailed:

    xor eax, eax

    ret

InitializeOpenGL ENDP


; ============================================================
; CleanupOpenGL
; ============================================================

CleanupOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; Delete OpenGL rendering context
    ; ========================================================

    cmp hGLRC, 0
    je SkipGLContext


    invoke wglMakeCurrent, 0, 0


    invoke wglDeleteContext, hGLRC


    mov hGLRC, 0


SkipGLContext:


    ; ========================================================
    ; Release DC
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
; Window procedure
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
; Paint
; ============================================================

WindowPaint:

    invoke RenderScene

    invoke ValidateRect, hWnd, 0

    xor eax, eax

    ret


; ============================================================
; Resize
;
; LOWORD(lParam) = width
; HIWORD(lParam) = height
; ============================================================

WindowSize:


    ; Width

    mov eax, lParam

    movzx ecx, ax

    mov clientW, ecx


    ; Height

    mov eax, lParam

    shr eax, 16

    movzx ecx, ax

    mov clientH, ecx


    ; OpenGL may not exist yet because WM_SIZE can occur
    ; during CreateWindowExA.

    cmp hGLRC, 0
    je WindowSizeFinished


    invoke SetupViewport

    invoke RenderScene


WindowSizeFinished:

    xor eax, eax

    ret


; ============================================================
; Prevent Windows from painting over OpenGL
; ============================================================

BackgroundHandled:

    mov eax, 1

    ret


; ============================================================
; Destroy
; ============================================================

WindowDestroyed:

    invoke CleanupOpenGL, hWnd

    invoke PostQuitMessage, 0


    xor eax, eax

    ret


WindowProc ENDP


; ============================================================
; Program entry
; ============================================================

start:


    ; ========================================================
    ; Initialize globals
    ; ========================================================

    mov hDC, 0
    mov hGLRC, 0
    mov hMainWnd, 0

    mov clientW, 0
    mov clientH, 0


    ; ========================================================
    ; Obtain module instance
    ; ========================================================

    invoke GetModuleHandleA, 0

    mov hInstance, eax


    ; ========================================================
    ; Configure window class
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
    ; Cursor
    ; ========================================================

    invoke LoadCursorA, \
        0, \
        IDC_ARROW


    mov windowClass.hCursor, eax


    ; OpenGL paints background.

    mov windowClass.hbrBackground, 0


    ; No menu yet.

    mov windowClass.lpszMenuName, 0


    mov windowClass.lpszClassName, OFFSET className


    ; ========================================================
    ; Register window class
    ; ========================================================

    invoke RegisterClassExA, \
        ADDR windowClass


    test eax, eax
    jz RegistrationFailed


    ; ========================================================
    ; Create window
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


    invoke RenderScene


; ============================================================
; Main Windows message loop
; ============================================================

MessageLoop:


    invoke GetMessageA, \
        ADDR messageData, \
        0, \
        0, \
        0


    cmp eax, 0
    je ProgramFinished


    cmp eax, -1
    je MessageLoopFailed


    invoke TranslateMessage, \
        ADDR messageData


    invoke DispatchMessageA, \
        ADDR messageData


    jmp MessageLoop


; ============================================================
; Normal exit
; ============================================================

ProgramFinished:

    mov eax, messageData.wParam

    invoke ExitProcess, eax


; ============================================================
; Failure exits
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