; ============================================================
; GraphX - Step 6
; 32-bit MASM + Win32 + OpenGL
;
; Features:
;   - Win32 application window
;   - OpenGL rendering context
;   - Resizable OpenGL viewport
;   - Mathematical coordinates
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
; Win32 API Prototypes
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

GetMessageA      PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

TranslateMessage PROTO STDCALL :DWORD
DispatchMessageA PROTO STDCALL :DWORD

DefWindowProcA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

PostQuitMessage PROTO STDCALL :DWORD

ValidateRect PROTO STDCALL :DWORD, :DWORD

GetDC      PROTO STDCALL :DWORD
ReleaseDC  PROTO STDCALL :DWORD, :DWORD

GetClientRect PROTO STDCALL :DWORD, :DWORD

ChoosePixelFormat PROTO STDCALL :DWORD, :DWORD
SetPixelFormat    PROTO STDCALL :DWORD, :DWORD, :DWORD

SwapBuffers PROTO STDCALL :DWORD


; ============================================================
; WGL Prototypes
; ============================================================

wglCreateContext PROTO STDCALL :DWORD
wglMakeCurrent   PROTO STDCALL :DWORD, :DWORD
wglDeleteContext PROTO STDCALL :DWORD


; ============================================================
; OpenGL Prototypes
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
; Win32 Constants
; ============================================================

CS_VREDRAW      EQU 0001h
CS_HREDRAW      EQU 0002h
CS_OWNDC        EQU 0020h

WM_DESTROY      EQU 0002h
WM_SIZE         EQU 0005h
WM_PAINT        EQU 000Fh
WM_ERASEBKGND   EQU 0014h

WS_OVERLAPPEDWINDOW EQU 00CF0000h
WS_CLIPCHILDREN     EQU 02000000h
WS_CLIPSIBLINGS     EQU 04000000h

CW_USEDEFAULT EQU 80000000h

SW_SHOWNORMAL EQU 1

IDC_ARROW EQU 32512


; ============================================================
; Pixel Format Constants
; ============================================================

PFD_DOUBLEBUFFER   EQU 00000001h
PFD_DRAW_TO_WINDOW EQU 00000004h
PFD_SUPPORT_OPENGL EQU 00000020h

PFD_TYPE_RGBA EQU 0
PFD_MAIN_PLANE EQU 0


; ============================================================
; OpenGL Constants
; ============================================================

GL_COLOR_BUFFER_BIT EQU 00004000h

GL_LINES EQU 0001h

GL_MODELVIEW  EQU 1700h
GL_PROJECTION EQU 1701h


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
; Initialized Data
; ============================================================

.data


; ------------------------------------------------------------
; Window information
; ------------------------------------------------------------

className db "GraphXWindowClass",0

windowTitle db \
    "GraphX - Mathematical Visualization System",0


; ============================================================
; OpenGL colors
; ============================================================

; Dark background

clearRed   REAL4 0.04
clearGreen REAL4 0.06
clearBlue  REAL4 0.10
clearAlpha REAL4 1.0


; ------------------------------------------------------------
; Axis color
; ------------------------------------------------------------

axisRed   REAL4 0.90
axisGreen REAL4 0.90
axisBlue  REAL4 0.90


; ============================================================
; Mathematical constants
; ============================================================

mathZero REAL4 0.0

mathMin REAL4 -10.0
mathMax REAL4  10.0


; ------------------------------------------------------------
; Projection scaling
;
; Mathematical coordinates:
;
;    -10 ... +10
;
; OpenGL coordinates:
;
;    -1 ... +1
;
; Therefore:
;
;    1 / 10 = 0.1
; ------------------------------------------------------------

mathScaleX REAL4 0.1
mathScaleY REAL4 0.1
mathScaleZ REAL4 1.0


; ============================================================
; Uninitialized Data
; ============================================================

.data?


hInstance DWORD ?
hMainWnd  DWORD ?

hDC   DWORD ?
hGLRC DWORD ?

pixelFormat DWORD ?


; ------------------------------------------------------------
; Current OpenGL viewport size
; ------------------------------------------------------------

clientW DWORD ?
clientH DWORD ?


; ------------------------------------------------------------
; Structures
; ------------------------------------------------------------

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
;
; Configures OpenGL viewport whenever the GraphX window
; changes size.
; ============================================================

SetupViewport PROC

    ; Don't attempt rendering if minimized.

    cmp clientW, 0
    je SetupViewportFinished

    cmp clientH, 0
    je SetupViewportFinished


    ; --------------------------------------------------------
    ; Tell OpenGL how large the drawing area is.
    ; --------------------------------------------------------

    invoke glViewport, \
        0,              \
        0,              \
        clientW,        \
        clientH


SetupViewportFinished:

    ret

SetupViewport ENDP


; ============================================================
; SetupProjection
;
; Establishes GraphX mathematical coordinates.
;
; We begin with OpenGL identity projection:
;
;       -1 .. +1
;
; Then scale coordinates by 0.1:
;
;       -10 .. +10
;
; Therefore:
;
;       x = -10 -> -1
;       x =  0  ->  0
;       x = +10 -> +1
; ============================================================

SetupProjection PROC

    ; --------------------------------------------------------
    ; Projection matrix
    ; --------------------------------------------------------

    invoke glMatrixMode, GL_PROJECTION

    invoke glLoadIdentity


    ; --------------------------------------------------------
    ; Map GraphX mathematical coordinates into OpenGL NDC.
    ; --------------------------------------------------------

    invoke glScalef, \
        DWORD PTR mathScaleX, \
        DWORD PTR mathScaleY, \
        DWORD PTR mathScaleZ


    ; --------------------------------------------------------
    ; Return to model-view matrix.
    ; --------------------------------------------------------

    invoke glMatrixMode, GL_MODELVIEW

    invoke glLoadIdentity

    ret

SetupProjection ENDP


; ============================================================
; DrawAxes
;
; Draw:
;
;                   +Y
;                    |
;                    |
;                    |
;        -X ----------+---------- +X
;                    |
;                    |
;                    |
;                   -Y
;
; Mathematical range:
;
;       X = -10 ... +10
;       Y = -10 ... +10
; ============================================================

DrawAxes PROC

    ; --------------------------------------------------------
    ; Axis color
    ; --------------------------------------------------------

    invoke glColor3f, \
        DWORD PTR axisRed, \
        DWORD PTR axisGreen, \
        DWORD PTR axisBlue


    ; --------------------------------------------------------
    ; Start line rendering
    ; --------------------------------------------------------

    invoke glBegin, GL_LINES


    ; ========================================================
    ; X AXIS
    ;
    ; (-10, 0) -------- (10, 0)
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
    ; (0, -10)
    ;     |
    ;     |
    ; (0, 10)
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
;
; Main OpenGL renderer.
; ============================================================

RenderScene PROC

    ; --------------------------------------------------------
    ; Is OpenGL initialized?
    ; --------------------------------------------------------

    cmp hGLRC, 0
    je RenderFinished


    ; --------------------------------------------------------
    ; Is the window minimized?
    ; --------------------------------------------------------

    cmp clientW, 0
    je RenderFinished

    cmp clientH, 0
    je RenderFinished


    ; ========================================================
    ; 1. Clear previous frame
    ; ========================================================

    invoke glClear, GL_COLOR_BUFFER_BIT


    ; ========================================================
    ; 2. Prepare mathematical projection
    ; ========================================================

    invoke SetupProjection


    ; ========================================================
    ; 3. Draw GraphX axes
    ; ========================================================

    invoke DrawAxes


    ; ========================================================
    ; 4. Display back buffer
    ; ========================================================

    invoke SwapBuffers, hDC


RenderFinished:

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
    ; 1. Get Windows device context
    ; ========================================================

    invoke GetDC, targetWnd

    test eax, eax
    jz OpenGLInitializationFailed

    mov hDC, eax


    ; ========================================================
    ; 2. Configure pixel format
    ; ========================================================

    mov pfd.nSize, SIZEOF PIXELFORMATDESCRIPTOR

    mov pfd.nVersion, 1


    mov pfd.dwFlags, \
        PFD_DRAW_TO_WINDOW OR \
        PFD_SUPPORT_OPENGL OR \
        PFD_DOUBLEBUFFER


    mov pfd.iPixelType, PFD_TYPE_RGBA


    ; 32-bit RGBA color

    mov pfd.cColorBits, 32


    ; Reserve 24-bit depth buffer for future 3D.

    mov pfd.cDepthBits, 24


    mov pfd.iLayerType, PFD_MAIN_PLANE


    ; ========================================================
    ; 3. Select pixel format
    ; ========================================================

    invoke ChoosePixelFormat, \
        hDC,                   \
        ADDR pfd

    test eax, eax
    jz OpenGLInitializationFailed


    mov pixelFormat, eax


    ; ========================================================
    ; 4. Install pixel format
    ; ========================================================

    invoke SetPixelFormat, \
        hDC,                \
        pixelFormat,        \
        ADDR pfd

    test eax, eax
    jz OpenGLInitializationFailed


    ; ========================================================
    ; 5. Create OpenGL context
    ; ========================================================

    invoke wglCreateContext, hDC

    test eax, eax
    jz OpenGLInitializationFailed


    mov hGLRC, eax


    ; ========================================================
    ; 6. Make rendering context active
    ; ========================================================

    invoke wglMakeCurrent, \
        hDC,                \
        hGLRC

    test eax, eax
    jz OpenGLInitializationFailed


    ; ========================================================
    ; 7. Configure background
    ; ========================================================

    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


    ; ========================================================
    ; 8. Obtain actual client area size
    ; ========================================================

    invoke GetClientRect, \
        targetWnd,         \
        ADDR clientRect


    mov eax, clientRect.right
    sub eax, clientRect.left

    mov clientW, eax


    mov eax, clientRect.bottom
    sub eax, clientRect.top

    mov clientH, eax


    ; ========================================================
    ; 9. Configure viewport
    ; ========================================================

    invoke SetupViewport


    mov eax, 1
    ret


OpenGLInitializationFailed:

    xor eax, eax
    ret


InitializeOpenGL ENDP


; ============================================================
; CleanupOpenGL
; ============================================================

CleanupOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; Remove OpenGL context
    ; ========================================================

    cmp hGLRC, 0
    je SkipContextCleanup


    ; Detach current context

    invoke wglMakeCurrent, 0, 0


    ; Delete it

    invoke wglDeleteContext, hGLRC


    mov hGLRC, 0


SkipContextCleanup:


    ; ========================================================
    ; Release Windows DC
    ; ========================================================

    cmp hDC, 0
    je CleanupFinished


    invoke ReleaseDC, \
        targetWnd,     \
        hDC


    mov hDC, 0


CleanupFinished:

    ret

CleanupOpenGL ENDP


; ============================================================
; WindowProc
; ============================================================

WindowProc PROC STDCALL \
    hWnd:DWORD,          \
    uMsg:DWORD,          \
    wParam:DWORD,        \
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
        hWnd,              \
        uMsg,              \
        wParam,            \
        lParam

    ret


; ============================================================
; WM_PAINT
; ============================================================

WindowPaint:

    invoke RenderScene

    invoke ValidateRect, hWnd, 0

    xor eax, eax

    ret


; ============================================================
; WM_SIZE
;
; LOWORD(lParam)  = client width
; HIWORD(lParam)  = client height
; ============================================================

WindowSize:


    ; --------------------------------------------------------
    ; Extract width
    ; --------------------------------------------------------

    mov eax, lParam

    movzx ecx, ax

    mov clientW, ecx


    ; --------------------------------------------------------
    ; Extract height
    ; --------------------------------------------------------

    shr eax, 16

    movzx ecx, ax

    mov clientH, ecx


    ; --------------------------------------------------------
    ; WM_SIZE can happen before OpenGL initialization.
    ; --------------------------------------------------------

    cmp hGLRC, 0
    je WindowSizeFinished


    invoke SetupViewport

    invoke RenderScene


WindowSizeFinished:

    xor eax, eax

    ret


; ============================================================
; OpenGL handles background clearing
; ============================================================

BackgroundHandled:

    mov eax, 1

    ret


; ============================================================
; WM_DESTROY
; ============================================================

WindowDestroyed:

    invoke CleanupOpenGL, hWnd

    invoke PostQuitMessage, 0

    xor eax, eax

    ret


WindowProc ENDP


; ============================================================
; Program Entry
; ============================================================

start:


    ; ========================================================
    ; Initialize global variables
    ; ========================================================

    mov hDC, 0
    mov hGLRC, 0
    mov hMainWnd, 0

    mov clientW, 0
    mov clientH, 0


    ; ========================================================
    ; 1. Obtain application module handle
    ; ========================================================

    invoke GetModuleHandleA, 0

    mov hInstance, eax


    ; ========================================================
    ; 2. Configure window class
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
    ; Load arrow cursor
    ; ========================================================

    invoke LoadCursorA, \
        0,               \
        IDC_ARROW


    mov windowClass.hCursor, eax


    ; OpenGL handles background.

    mov windowClass.hbrBackground, 0


    ; No menu yet.

    mov windowClass.lpszMenuName, 0


    mov windowClass.lpszClassName, OFFSET className


    ; ========================================================
    ; 3. Register GraphX window class
    ; ========================================================

    invoke RegisterClassExA, \
        ADDR windowClass


    test eax, eax

    jz RegistrationFailed


    ; ========================================================
    ; 4. Create GraphX window
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
    ; 5. Initialize OpenGL
    ; ========================================================

    invoke InitializeOpenGL, hMainWnd


    test eax, eax

    jz OpenGLCreationFailed


    ; ========================================================
    ; 6. Show GraphX
    ; ========================================================

    invoke ShowWindow, \
        hMainWnd,        \
        SW_SHOWNORMAL


    invoke UpdateWindow, hMainWnd


    ; Initial render.

    invoke RenderScene


; ============================================================
; Main Windows Message Loop
; ============================================================

MessageLoop:


    invoke GetMessageA, \
        ADDR messageData, \
        0,                \
        0,                \
        0


    ; WM_QUIT

    cmp eax, 0

    je ProgramFinished


    ; Error

    cmp eax, -1

    je MessageLoopFailed


    ; Translate keyboard input

    invoke TranslateMessage, \
        ADDR messageData


    ; Dispatch event to WindowProc

    invoke DispatchMessageA, \
        ADDR messageData


    jmp MessageLoop


; ============================================================
; Normal Exit
; ============================================================

ProgramFinished:


    mov eax, messageData.wParam

    invoke ExitProcess, eax


; ============================================================
; Error exits
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