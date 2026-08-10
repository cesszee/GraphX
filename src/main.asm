; ============================================================
; GraphX - Step 10
; 32-bit MASM + Win32 + OpenGL
;
; Features:
;   - Win32 application window
;   - OpenGL rendering context
;   - Cartesian grid
;   - X/Y axes
;   - y = x^2
;   - Aspect-ratio-correct viewport
;   - Keyboard pan
;   - Keyboard zoom
;   - Reset view
;   - ESC to exit
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
; WIN32 API
; ============================================================

GetModuleHandleA PROTO STDCALL :DWORD
ExitProcess      PROTO STDCALL :DWORD

LoadCursorA      PROTO STDCALL :DWORD, :DWORD
RegisterClassExA PROTO STDCALL :DWORD

CreateWindowExA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD

DestroyWindow PROTO STDCALL :DWORD

ShowWindow   PROTO STDCALL :DWORD, :DWORD
UpdateWindow PROTO STDCALL :DWORD

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

SetPixelFormat PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

SwapBuffers PROTO STDCALL :DWORD


; ============================================================
; WGL API
; ============================================================

wglCreateContext PROTO STDCALL :DWORD

wglMakeCurrent PROTO STDCALL \
    :DWORD, :DWORD

wglDeleteContext PROTO STDCALL :DWORD


; ============================================================
; OPENGL API
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

glTranslatef PROTO STDCALL \
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
WM_KEYDOWN    EQU 0100h

WS_OVERLAPPEDWINDOW EQU 00CF0000h
WS_CLIPCHILDREN     EQU 02000000h
WS_CLIPSIBLINGS     EQU 04000000h

CW_USEDEFAULT EQU 80000000h

SW_SHOWNORMAL EQU 1

IDC_ARROW EQU 32512


; ============================================================
; KEYBOARD CONSTANTS
; ============================================================

VK_ESCAPE   EQU 01Bh

VK_A        EQU 041h
VK_D        EQU 044h
VK_R        EQU 052h
VK_S        EQU 053h
VK_W        EQU 057h

VK_ADD      EQU 06Bh
VK_SUBTRACT EQU 06Dh

VK_OEM_PLUS  EQU 0BBh
VK_OEM_MINUS EQU 0BDh


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

GRID_MIN EQU -200
GRID_MAX EQU  200


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
    "GraphX - Pan / Zoom / Reset",0


; ============================================================
; COLORS
; ============================================================

clearRed   REAL4 0.04
clearGreen REAL4 0.06
clearBlue  REAL4 0.10
clearAlpha REAL4 1.0


gridRed   REAL4 0.18
gridGreen REAL4 0.22
gridBlue  REAL4 0.28


axisRed   REAL4 0.92
axisGreen REAL4 0.92
axisBlue  REAL4 0.92


graphRed   REAL4 0.20
graphGreen REAL4 0.85
graphBlue  REAL4 0.35


; ============================================================
; BASIC FLOAT CONSTANTS
; ============================================================

floatZero REAL4 0.0
floatOne  REAL4 1.0


; ============================================================
; VIEW STATE
;
; centerX / centerY determine where the camera is looking.
;
; zoomHalfRange determines the base visible half-range.
;
; Default:
;
;     center = (0,0)
;     zoomHalfRange = 10
; ============================================================

centerX REAL4 0.0
centerY REAL4 0.0

zoomHalfRange REAL4 10.0


; ============================================================
; ZOOM SETTINGS
; ============================================================

zoomInFactor  REAL4 0.80
zoomOutFactor REAL4 1.25

minHalfRange REAL4 0.50
maxHalfRange REAL4 50.0

zoomCandidate REAL4 0.0


; ============================================================
; PAN SETTINGS
;
; Each key press moves 10% of the current visible half-range.
; ============================================================

panFraction REAL4 0.10

panAmountX REAL4 0.0
panAmountY REAL4 0.0


; ============================================================
; CALCULATED VIEWPORT
; ============================================================

viewHalfX REAL4 10.0
viewHalfY REAL4 10.0

viewLeft   REAL4 -10.0
viewRight  REAL4  10.0
viewBottom REAL4 -10.0
viewTop    REAL4  10.0


; ============================================================
; OPENGL TRANSFORMATION VALUES
; ============================================================

viewScaleX REAL4 0.1
viewScaleY REAL4 0.1
viewScaleZ REAL4 1.0

viewTranslateX REAL4 0.0
viewTranslateY REAL4 0.0


; ============================================================
; FUNCTION
;
; y = x^2
; ============================================================

graphStartX REAL4 -3.0
graphStepX  REAL4  0.05


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


currentX REAL4 ?
currentY REAL4 ?

gridIndex DWORD ?
gridCoord REAL4 ?

windowClass WNDCLASSEX <>
messageData MSG <>
clientRect  RECT <>

pfd PIXELFORMATDESCRIPTOR <>


; ============================================================
; CODE
; ============================================================

.code


; ============================================================
; UPDATE VIEW STATE
;
; Calculates:
;
;     viewHalfX
;     viewHalfY
;
; based on:
;
;     zoomHalfRange
;     window aspect ratio
;
; Then calculates:
;
;     left
;     right
;     bottom
;     top
;
; around:
;
;     centerX
;     centerY
; ============================================================

UpdateViewState PROC


    cmp clientW, 0
    je UpdateViewDone

    cmp clientH, 0
    je UpdateViewDone


    ; --------------------------------------------------------
    ; Wide window?
    ; --------------------------------------------------------

    mov eax, clientW

    cmp eax, clientH

    jae ViewWide


; ============================================================
; TALL WINDOW
;
; X uses zoomHalfRange.
;
; Y expands according to aspect ratio.
; ============================================================

ViewTall:


    fld DWORD PTR zoomHalfRange
    fstp DWORD PTR viewHalfX


    fld DWORD PTR zoomHalfRange

    fimul DWORD PTR clientH

    fidiv DWORD PTR clientW

    fstp DWORD PTR viewHalfY


    jmp CalculateBounds


; ============================================================
; WIDE WINDOW
;
; Y uses zoomHalfRange.
;
; X expands according to aspect ratio.
; ============================================================

ViewWide:


    fld DWORD PTR zoomHalfRange
    fstp DWORD PTR viewHalfY


    fld DWORD PTR zoomHalfRange

    fimul DWORD PTR clientW

    fidiv DWORD PTR clientH

    fstp DWORD PTR viewHalfX


; ============================================================
; CALCULATE MATHEMATICAL BOUNDS
; ============================================================

CalculateBounds:


    ; --------------------------------------------------------
    ; left = centerX - halfX
    ; --------------------------------------------------------

    fld DWORD PTR centerX

    fsub DWORD PTR viewHalfX

    fstp DWORD PTR viewLeft


    ; --------------------------------------------------------
    ; right = centerX + halfX
    ; --------------------------------------------------------

    fld DWORD PTR centerX

    fadd DWORD PTR viewHalfX

    fstp DWORD PTR viewRight


    ; --------------------------------------------------------
    ; bottom = centerY - halfY
    ; --------------------------------------------------------

    fld DWORD PTR centerY

    fsub DWORD PTR viewHalfY

    fstp DWORD PTR viewBottom


    ; --------------------------------------------------------
    ; top = centerY + halfY
    ; --------------------------------------------------------

    fld DWORD PTR centerY

    fadd DWORD PTR viewHalfY

    fstp DWORD PTR viewTop


; ============================================================
; CALCULATE OPENGL SCALE
;
; scale = 1 / halfRange
; ============================================================

    fld DWORD PTR floatOne

    fdiv DWORD PTR viewHalfX

    fstp DWORD PTR viewScaleX


    fld DWORD PTR floatOne

    fdiv DWORD PTR viewHalfY

    fstp DWORD PTR viewScaleY


; ============================================================
; TRANSLATION
;
; OpenGL should move the mathematical world opposite
; our camera center.
;
; translateX = -centerX
; translateY = -centerY
; ============================================================

    fld DWORD PTR centerX

    fchs

    fstp DWORD PTR viewTranslateX


    fld DWORD PTR centerY

    fchs

    fstp DWORD PTR viewTranslateY


UpdateViewDone:

    ret

UpdateViewState ENDP


; ============================================================
; SETUP OPENGL PIXEL VIEWPORT
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
; Desired mapping:
;
;     OpenGL X = (WorldX - centerX) / halfX
;     OpenGL Y = (WorldY - centerY) / halfY
;
; Matrix:
;
;     Scale * Translate
; ============================================================

SetupProjection PROC


    invoke glMatrixMode, GL_PROJECTION


    invoke glLoadIdentity


    ; --------------------------------------------------------
    ; Scale first.
    ;
    ; OpenGL matrix multiplication means the later translation
    ; is applied to vertices first:
    ;
    ;     S * T * vertex
    ; --------------------------------------------------------

    invoke glScalef, \
        DWORD PTR viewScaleX, \
        DWORD PTR viewScaleY, \
        DWORD PTR viewScaleZ


    invoke glTranslatef, \
        DWORD PTR viewTranslateX, \
        DWORD PTR viewTranslateY, \
        DWORD PTR floatZero


    invoke glMatrixMode, GL_MODELVIEW


    invoke glLoadIdentity


    ret

SetupProjection ENDP


; ============================================================
; DRAW CARTESIAN GRID
; ============================================================

DrawGrid PROC


    invoke glColor3f, \
        DWORD PTR gridRed, \
        DWORD PTR gridGreen, \
        DWORD PTR gridBlue


    invoke glBegin, GL_LINES


    mov gridIndex, GRID_MIN


GridLoop:


    cmp gridIndex, 0

    je GridNext


    ; --------------------------------------------------------
    ; Convert integer grid coordinate to REAL4.
    ; --------------------------------------------------------

    fild DWORD PTR gridIndex

    fstp DWORD PTR gridCoord


    ; ========================================================
    ; VERTICAL LINE
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewBottom


    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewTop


    ; ========================================================
    ; HORIZONTAL LINE
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
; DRAW AXES
; ============================================================

DrawAxes PROC


    invoke glColor3f, \
        DWORD PTR axisRed, \
        DWORD PTR axisGreen, \
        DWORD PTR axisBlue


    invoke glBegin, GL_LINES


    ; X AXIS

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR floatZero


    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR floatZero


    ; Y AXIS

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
; y = x^2
; ============================================================

DrawFunction PROC


    push edi


    invoke glColor3f, \
        DWORD PTR graphRed, \
        DWORD PTR graphGreen, \
        DWORD PTR graphBlue


    ; --------------------------------------------------------
    ; x = -3
    ; --------------------------------------------------------

    fld DWORD PTR graphStartX

    fstp DWORD PTR currentX


    mov edi, GRAPH_SAMPLES


    invoke glBegin, GL_LINE_STRIP


FunctionLoop:


    ; --------------------------------------------------------
    ; y = x * x
    ; --------------------------------------------------------

    fld DWORD PTR currentX

    fmul DWORD PTR currentX

    fstp DWORD PTR currentY


    invoke glVertex2f, \
        DWORD PTR currentX, \
        DWORD PTR currentY


    ; --------------------------------------------------------
    ; x += 0.05
    ; --------------------------------------------------------

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
; RENDER SCENE
; ============================================================

RenderScene PROC


    cmp hGLRC, 0

    je RenderDone


    cmp clientW, 0

    je RenderDone


    cmp clientH, 0

    je RenderDone


    invoke glClear, GL_COLOR_BUFFER_BIT


    invoke SetupProjection


    invoke DrawGrid


    invoke DrawAxes


    invoke DrawFunction


    invoke SwapBuffers, hDC


RenderDone:

    ret

RenderScene ENDP


; ============================================================
; CALCULATE PAN STEP
;
; Pan by 10% of current visible half-width / half-height.
; ============================================================

CalculatePanStep PROC


    fld DWORD PTR viewHalfX

    fmul DWORD PTR panFraction

    fstp DWORD PTR panAmountX


    fld DWORD PTR viewHalfY

    fmul DWORD PTR panFraction

    fstp DWORD PTR panAmountY


    ret

CalculatePanStep ENDP


; ============================================================
; PAN LEFT
; ============================================================

PanLeft PROC


    invoke CalculatePanStep


    fld DWORD PTR centerX

    fsub DWORD PTR panAmountX

    fstp DWORD PTR centerX


    invoke UpdateViewState


    invoke RenderScene


    ret

PanLeft ENDP


; ============================================================
; PAN RIGHT
; ============================================================

PanRight PROC


    invoke CalculatePanStep


    fld DWORD PTR centerX

    fadd DWORD PTR panAmountX

    fstp DWORD PTR centerX


    invoke UpdateViewState


    invoke RenderScene


    ret

PanRight ENDP


; ============================================================
; PAN UP
; ============================================================

PanUp PROC


    invoke CalculatePanStep


    fld DWORD PTR centerY

    fadd DWORD PTR panAmountY

    fstp DWORD PTR centerY


    invoke UpdateViewState


    invoke RenderScene


    ret

PanUp ENDP


; ============================================================
; PAN DOWN
; ============================================================

PanDown PROC


    invoke CalculatePanStep


    fld DWORD PTR centerY

    fsub DWORD PTR panAmountY

    fstp DWORD PTR centerY


    invoke UpdateViewState


    invoke RenderScene


    ret

PanDown ENDP


; ============================================================
; ZOOM IN
;
; newHalfRange = currentHalfRange * 0.80
;
; Minimum = 0.50
; ============================================================

ZoomIn PROC


    fld DWORD PTR zoomHalfRange

    fmul DWORD PTR zoomInFactor

    fstp DWORD PTR zoomCandidate


    ; --------------------------------------------------------
    ; Compare candidate with minimum.
    ; --------------------------------------------------------

    fld DWORD PTR zoomCandidate

    fcomp DWORD PTR minHalfRange

    fnstsw ax

    sahf


    ; candidate < minimum?

    jb ZoomInClamp


    fld DWORD PTR zoomCandidate

    fstp DWORD PTR zoomHalfRange


    jmp ZoomInUpdate


ZoomInClamp:


    fld DWORD PTR minHalfRange

    fstp DWORD PTR zoomHalfRange


ZoomInUpdate:


    invoke UpdateViewState

    invoke RenderScene


    ret

ZoomIn ENDP


; ============================================================
; ZOOM OUT
;
; newHalfRange = currentHalfRange * 1.25
;
; Maximum = 50
; ============================================================

ZoomOut PROC


    fld DWORD PTR zoomHalfRange

    fmul DWORD PTR zoomOutFactor

    fstp DWORD PTR zoomCandidate


    ; --------------------------------------------------------
    ; Compare candidate with maximum.
    ; --------------------------------------------------------

    fld DWORD PTR zoomCandidate

    fcomp DWORD PTR maxHalfRange

    fnstsw ax

    sahf


    ; candidate > maximum?

    ja ZoomOutClamp


    fld DWORD PTR zoomCandidate

    fstp DWORD PTR zoomHalfRange


    jmp ZoomOutUpdate


ZoomOutClamp:


    fld DWORD PTR maxHalfRange

    fstp DWORD PTR zoomHalfRange


ZoomOutUpdate:


    invoke UpdateViewState

    invoke RenderScene


    ret

ZoomOut ENDP


; ============================================================
; RESET VIEW
; ============================================================

ResetView PROC


    fld DWORD PTR floatZero
    fstp DWORD PTR centerX


    fld DWORD PTR floatZero
    fstp DWORD PTR centerY


    ; Default half-range = 10
    ; Use immediate constant from initialized value below.

    fld DWORD PTR defaultHalfRange
    fstp DWORD PTR zoomHalfRange


    invoke UpdateViewState


    invoke RenderScene


    ret

ResetView ENDP


; ============================================================
; KEYBOARD HANDLER
; ============================================================

HandleKeyboard PROC STDCALL keyCode:DWORD


    mov eax, keyCode


    ; --------------------------------------------------------
    ; ESC
    ; --------------------------------------------------------

    cmp eax, VK_ESCAPE

    je KeyboardExit


    ; --------------------------------------------------------
    ; W
    ; --------------------------------------------------------

    cmp eax, VK_W

    je KeyboardUp


    ; --------------------------------------------------------
    ; S
    ; --------------------------------------------------------

    cmp eax, VK_S

    je KeyboardDown


    ; --------------------------------------------------------
    ; A
    ; --------------------------------------------------------

    cmp eax, VK_A

    je KeyboardLeft


    ; --------------------------------------------------------
    ; D
    ; --------------------------------------------------------

    cmp eax, VK_D

    je KeyboardRight


    ; --------------------------------------------------------
    ; R
    ; --------------------------------------------------------

    cmp eax, VK_R

    je KeyboardReset


    ; --------------------------------------------------------
    ; + / =
    ; --------------------------------------------------------

    cmp eax, VK_OEM_PLUS

    je KeyboardZoomIn


    cmp eax, VK_ADD

    je KeyboardZoomIn


    ; --------------------------------------------------------
    ; -
    ; --------------------------------------------------------

    cmp eax, VK_OEM_MINUS

    je KeyboardZoomOut


    cmp eax, VK_SUBTRACT

    je KeyboardZoomOut


    ret


KeyboardUp:

    invoke PanUp

    ret


KeyboardDown:

    invoke PanDown

    ret


KeyboardLeft:

    invoke PanLeft

    ret


KeyboardRight:

    invoke PanRight

    ret


KeyboardZoomIn:

    invoke ZoomIn

    ret


KeyboardZoomOut:

    invoke ZoomOut

    ret


KeyboardReset:

    invoke ResetView

    ret


KeyboardExit:

    invoke DestroyWindow, hMainWnd

    ret


HandleKeyboard ENDP


; ============================================================
; OPENGL INITIALIZATION
; ============================================================

InitializeOpenGL PROC STDCALL targetWnd:DWORD


    invoke GetDC, targetWnd


    test eax, eax

    jz InitFailed


    mov hDC, eax


    ; --------------------------------------------------------
    ; Pixel format
    ; --------------------------------------------------------

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


    invoke ChoosePixelFormat, \
        hDC, \
        ADDR pfd


    test eax, eax

    jz InitFailed


    mov pixelFormat, eax


    invoke SetPixelFormat, \
        hDC, \
        pixelFormat, \
        ADDR pfd


    test eax, eax

    jz InitFailed


    ; --------------------------------------------------------
    ; WGL context
    ; --------------------------------------------------------

    invoke wglCreateContext, hDC


    test eax, eax

    jz InitFailed


    mov hGLRC, eax


    invoke wglMakeCurrent, \
        hDC, \
        hGLRC


    test eax, eax

    jz InitFailed


    ; --------------------------------------------------------
    ; Background color
    ; --------------------------------------------------------

    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


    ; --------------------------------------------------------
    ; Initial client size
    ; --------------------------------------------------------

    invoke GetClientRect, \
        targetWnd, \
        ADDR clientRect


    mov eax, clientRect.right

    sub eax, clientRect.left

    mov clientW, eax


    mov eax, clientRect.bottom

    sub eax, clientRect.top

    mov clientH, eax


    invoke UpdateViewState


    invoke SetupViewport


    mov eax, 1


    ret


InitFailed:


    xor eax, eax


    ret

InitializeOpenGL ENDP


; ============================================================
; CLEANUP OPENGL
; ============================================================

CleanupOpenGL PROC STDCALL targetWnd:DWORD


    cmp hGLRC, 0

    je SkipGLContext


    invoke wglMakeCurrent, 0, 0


    invoke wglDeleteContext, hGLRC


    mov hGLRC, 0


SkipGLContext:


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


    ; --------------------------------------------------------
    ; WM_PAINT
    ; --------------------------------------------------------

    cmp uMsg, WM_PAINT

    je WindowPaint


    ; --------------------------------------------------------
    ; WM_SIZE
    ; --------------------------------------------------------

    cmp uMsg, WM_SIZE

    je WindowSize


    ; --------------------------------------------------------
    ; WM_KEYDOWN
    ; --------------------------------------------------------

    cmp uMsg, WM_KEYDOWN

    je WindowKeyDown


    ; --------------------------------------------------------
    ; WM_ERASEBKGND
    ; --------------------------------------------------------

    cmp uMsg, WM_ERASEBKGND

    je BackgroundHandled


    ; --------------------------------------------------------
    ; WM_DESTROY
    ; --------------------------------------------------------

    cmp uMsg, WM_DESTROY

    je WindowDestroyed


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


    ; OpenGL may not be initialized yet.

    cmp hGLRC, 0

    je WindowSizeDone


    invoke UpdateViewState


    invoke SetupViewport


    invoke RenderScene


WindowSizeDone:


    xor eax, eax


    ret


; ============================================================
; KEYBOARD
; ============================================================

WindowKeyDown:


    invoke HandleKeyboard, wParam


    xor eax, eax


    ret


; ============================================================
; BACKGROUND
; ============================================================

BackgroundHandled:


    mov eax, 1


    ret


; ============================================================
; DESTROY
; ============================================================

WindowDestroyed:


    invoke CleanupOpenGL, hWnd


    invoke PostQuitMessage, 0


    xor eax, eax


    ret


WindowProc ENDP


; ============================================================
; ADDITIONAL INITIALIZED CONSTANT
;
; Kept here because ResetView references it.
; ============================================================

.data

defaultHalfRange REAL4 10.0


.code


; ============================================================
; PROGRAM ENTRY
; ============================================================

start:


    ; --------------------------------------------------------
    ; Initialize x87.
    ; --------------------------------------------------------

    finit


    ; --------------------------------------------------------
    ; Global handles.
    ; --------------------------------------------------------

    mov hDC, 0

    mov hGLRC, 0

    mov hMainWnd, 0


    mov clientW, 0

    mov clientH, 0


    ; --------------------------------------------------------
    ; Module handle.
    ; --------------------------------------------------------

    invoke GetModuleHandleA, 0


    mov hInstance, eax


    ; --------------------------------------------------------
    ; Window class.
    ; --------------------------------------------------------

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


    invoke LoadCursorA, \
        0, \
        IDC_ARROW


    mov windowClass.hCursor, eax


    mov windowClass.hbrBackground, 0

    mov windowClass.lpszMenuName, 0

    mov windowClass.lpszClassName, OFFSET className


    ; --------------------------------------------------------
    ; Register class.
    ; --------------------------------------------------------

    invoke RegisterClassExA, \
        ADDR windowClass


    test eax, eax

    jz RegistrationFailed


    ; --------------------------------------------------------
    ; Create window.
    ; --------------------------------------------------------

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


    ; --------------------------------------------------------
    ; OpenGL.
    ; --------------------------------------------------------

    invoke InitializeOpenGL, hMainWnd


    test eax, eax

    jz OpenGLCreationFailed


    ; --------------------------------------------------------
    ; Show window.
    ; --------------------------------------------------------

    invoke ShowWindow, \
        hMainWnd, \
        SW_SHOWNORMAL


    invoke UpdateWindow, hMainWnd


    invoke RenderScene


; ============================================================
; MESSAGE LOOP
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
; NORMAL EXIT
; ============================================================

ProgramFinished:


    mov eax, messageData.wParam


    invoke ExitProcess, eax


; ============================================================
; ERRORS
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