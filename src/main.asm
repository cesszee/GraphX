; ============================================================
; GraphX - Step 11
; 32-bit MASM + Win32 + OpenGL
;
; Features:
;   - Native Win32 application
;   - OpenGL rendering
;   - Cartesian grid
;   - X/Y axes
;   - Aspect-ratio-correct mathematical viewport
;   - Pan with W/A/S/D
;   - Zoom with +/-
;   - Reset with R
;   - Exit with ESC
;   - Dynamic graph sampling across visible X range
;   - Function y = x^2 calculated using x87 FPU
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

VK_ESCAPE EQU 01Bh

VK_A EQU 041h
VK_D EQU 044h
VK_R EQU 052h
VK_S EQU 053h
VK_W EQU 057h

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

; 1000 intervals means 1001 plotted points.
GRAPH_INTERVALS    EQU 1000
GRAPH_SAMPLE_COUNT EQU 1001

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
; WINDOW INFORMATION
; ============================================================

className db "GraphXWindowClass",0

windowTitle db \
    "GraphX - Dynamic Function Sampling",0


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
; FLOAT CONSTANTS
; ============================================================

floatZero REAL4 0.0
floatOne  REAL4 1.0


; ============================================================
; DEFAULT CAMERA
; ============================================================

defaultHalfRange REAL4 10.0


; ============================================================
; CAMERA STATE
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
; ============================================================

panFraction REAL4 0.10

panAmountX REAL4 0.0
panAmountY REAL4 0.0


; ============================================================
; MATHEMATICAL VIEWPORT
; ============================================================

viewHalfX REAL4 10.0
viewHalfY REAL4 10.0

viewLeft   REAL4 -10.0
viewRight  REAL4  10.0
viewBottom REAL4 -10.0
viewTop    REAL4  10.0


; ============================================================
; OPENGL VIEW TRANSFORMATION
; ============================================================

viewScaleX REAL4 0.1
viewScaleY REAL4 0.1
viewScaleZ REAL4 1.0

viewTranslateX REAL4 0.0
viewTranslateY REAL4 0.0


; ============================================================
; DYNAMIC GRAPH SAMPLING
;
; graphIntervalCount is stored as an integer because x87
; FIDIV divides by an integer memory operand.
; ============================================================

graphIntervalCount DWORD GRAPH_INTERVALS


; ============================================================
; UNINITIALIZED DATA
; ============================================================

.data?


; ============================================================
; WINDOWS / OPENGL HANDLES
; ============================================================

hInstance DWORD ?
hMainWnd  DWORD ?

hDC   DWORD ?
hGLRC DWORD ?

pixelFormat DWORD ?


; ============================================================
; WINDOW SIZE
; ============================================================

clientW DWORD ?
clientH DWORD ?


; ============================================================
; GRAPH WORKING DATA
; ============================================================

currentX REAL4 ?
currentY REAL4 ?

graphStepX REAL4 ?


; ============================================================
; GRID WORKING DATA
; ============================================================

gridIndex DWORD ?
gridCoord REAL4 ?


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
; UPDATE MATHEMATICAL VIEW
;
; Determines aspect-ratio-correct visible mathematical bounds.
; ============================================================

UpdateViewState PROC


    cmp clientW, 0
    je UpdateViewDone


    cmp clientH, 0
    je UpdateViewDone


    ; --------------------------------------------------------
    ; Wide/square window?
    ; --------------------------------------------------------

    mov eax, clientW

    cmp eax, clientH

    jae ViewWide


; ============================================================
; TALL WINDOW
;
; Keep X half-range at zoomHalfRange.
;
; Expand Y according to:
;
; zoomHalfRange * height / width
; ============================================================

ViewTall:


    fld DWORD PTR zoomHalfRange

    fstp DWORD PTR viewHalfX


    fld DWORD PTR zoomHalfRange

    fimul DWORD PTR clientH

    fidiv DWORD PTR clientW

    fstp DWORD PTR viewHalfY


    jmp CalculateViewBounds


; ============================================================
; WIDE / SQUARE WINDOW
;
; Keep Y half-range at zoomHalfRange.
;
; Expand X according to:
;
; zoomHalfRange * width / height
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

CalculateViewBounds:


    ; left = centerX - halfX

    fld DWORD PTR centerX

    fsub DWORD PTR viewHalfX

    fstp DWORD PTR viewLeft


    ; right = centerX + halfX

    fld DWORD PTR centerX

    fadd DWORD PTR viewHalfX

    fstp DWORD PTR viewRight


    ; bottom = centerY - halfY

    fld DWORD PTR centerY

    fsub DWORD PTR viewHalfY

    fstp DWORD PTR viewBottom


    ; top = centerY + halfY

    fld DWORD PTR centerY

    fadd DWORD PTR viewHalfY

    fstp DWORD PTR viewTop


; ============================================================
; PROJECTION SCALE
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


; ============================================================
; CAMERA TRANSLATION
;
; Mathematical world must move opposite camera position.
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
; SETUP OPENGL MATHEMATICAL PROJECTION
; ============================================================

SetupProjection PROC


    invoke glMatrixMode, GL_PROJECTION


    invoke glLoadIdentity


    ; --------------------------------------------------------
    ; Scaling
    ; --------------------------------------------------------

    invoke glScalef, \
        DWORD PTR viewScaleX, \
        DWORD PTR viewScaleY, \
        DWORD PTR viewScaleZ


    ; --------------------------------------------------------
    ; Camera translation
    ; --------------------------------------------------------

    invoke glTranslatef, \
        DWORD PTR viewTranslateX, \
        DWORD PTR viewTranslateY, \
        DWORD PTR floatZero


    ; --------------------------------------------------------
    ; Return to model-view.
    ; --------------------------------------------------------

    invoke glMatrixMode, GL_MODELVIEW


    invoke glLoadIdentity


    ret

SetupProjection ENDP


; ============================================================
; DRAW GRID
; ============================================================

DrawGrid PROC


    invoke glColor3f, \
        DWORD PTR gridRed, \
        DWORD PTR gridGreen, \
        DWORD PTR gridBlue


    invoke glBegin, GL_LINES


    mov gridIndex, GRID_MIN


GridLoop:


    ; --------------------------------------------------------
    ; Skip zero because axes are rendered separately.
    ; --------------------------------------------------------

    cmp gridIndex, 0

    je GridNext


    ; --------------------------------------------------------
    ; Convert integer grid value to REAL4.
    ; --------------------------------------------------------

    fild DWORD PTR gridIndex

    fstp DWORD PTR gridCoord


    ; ========================================================
    ; VERTICAL GRID LINE
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewBottom


    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewTop


    ; ========================================================
    ; HORIZONTAL GRID LINE
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


    ; ========================================================
    ; X AXIS
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR floatZero


    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR floatZero


    ; ========================================================
    ; Y AXIS
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
; CALCULATE DYNAMIC GRAPH STEP
;
; Instead of:
;
;     x = -3 ... +3
;
; we use:
;
;     x = viewLeft ... viewRight
;
; Step:
;
;     (viewRight - viewLeft) / 1000
; ============================================================

CalculateGraphStep PROC


    fld DWORD PTR viewRight


    fsub DWORD PTR viewLeft


    fidiv DWORD PTR graphIntervalCount


    fstp DWORD PTR graphStepX


    ret

CalculateGraphStep ENDP


; ============================================================
; EVALUATE CURRENT FUNCTION
;
; Current function:
;
;       y = x^2
;
; Input:
;
;       currentX
;
; Output:
;
;       currentY
;
; This procedure will eventually be replaced by the
; GraphX expression evaluator.
; ============================================================

EvaluateCurrentFunction PROC


    fld DWORD PTR currentX


    fmul DWORD PTR currentX


    fstp DWORD PTR currentY


    ret

EvaluateCurrentFunction ENDP


; ============================================================
; DRAW FUNCTION
;
; Dynamically samples y = x^2 across the currently visible
; mathematical X range.
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


    ; ========================================================
    ; Calculate dynamic sampling step.
    ; ========================================================

    invoke CalculateGraphStep


    ; ========================================================
    ; currentX = viewLeft
    ; ========================================================

    fld DWORD PTR viewLeft

    fstp DWORD PTR currentX


    ; ========================================================
    ; Number of points.
    ; ========================================================

    mov edi, GRAPH_SAMPLE_COUNT


    ; ========================================================
    ; Begin graph.
    ; ========================================================

    invoke glBegin, GL_LINE_STRIP


FunctionLoop:


    ; ========================================================
    ; Evaluate:
    ;
    ; y = f(x)
    ;
    ; currently:
    ;
    ; y = x^2
    ; ========================================================

    invoke EvaluateCurrentFunction


    ; ========================================================
    ; Send generated coordinate to OpenGL.
    ; ========================================================

    invoke glVertex2f, \
        DWORD PTR currentX, \
        DWORD PTR currentY


    ; ========================================================
    ; Advance X.
    ;
    ; x = x + graphStepX
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
; MAIN RENDERER
; ============================================================

RenderScene PROC


    cmp hGLRC, 0

    je RenderDone


    cmp clientW, 0

    je RenderDone


    cmp clientH, 0

    je RenderDone


    ; ========================================================
    ; Clear previous frame.
    ; ========================================================

    invoke glClear, GL_COLOR_BUFFER_BIT


    ; ========================================================
    ; Mathematical camera/projection.
    ; ========================================================

    invoke SetupProjection


    ; ========================================================
    ; Grid.
    ; ========================================================

    invoke DrawGrid


    ; ========================================================
    ; Axes.
    ; ========================================================

    invoke DrawAxes


    ; ========================================================
    ; Function.
    ; ========================================================

    invoke DrawFunction


    ; ========================================================
    ; Present completed frame.
    ; ========================================================

    invoke SwapBuffers, hDC


RenderDone:


    ret

RenderScene ENDP


; ============================================================
; CALCULATE PAN STEP
;
; Pan = 10% of current visible half-range.
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
; ============================================================

ZoomIn PROC


    ; candidate = current * 0.80

    fld DWORD PTR zoomHalfRange


    fmul DWORD PTR zoomInFactor


    fstp DWORD PTR zoomCandidate


    ; --------------------------------------------------------
    ; candidate compared against minimum.
    ; --------------------------------------------------------

    fld DWORD PTR zoomCandidate


    fcomp DWORD PTR minHalfRange


    fnstsw ax


    sahf


    jb ZoomInClamp


    fld DWORD PTR zoomCandidate


    fstp DWORD PTR zoomHalfRange


    jmp ZoomInApply


ZoomInClamp:


    fld DWORD PTR minHalfRange


    fstp DWORD PTR zoomHalfRange


ZoomInApply:


    invoke UpdateViewState


    invoke RenderScene


    ret

ZoomIn ENDP


; ============================================================
; ZOOM OUT
; ============================================================

ZoomOut PROC


    ; candidate = current * 1.25

    fld DWORD PTR zoomHalfRange


    fmul DWORD PTR zoomOutFactor


    fstp DWORD PTR zoomCandidate


    ; --------------------------------------------------------
    ; candidate compared against maximum.
    ; --------------------------------------------------------

    fld DWORD PTR zoomCandidate


    fcomp DWORD PTR maxHalfRange


    fnstsw ax


    sahf


    ja ZoomOutClamp


    fld DWORD PTR zoomCandidate


    fstp DWORD PTR zoomHalfRange


    jmp ZoomOutApply


ZoomOutClamp:


    fld DWORD PTR maxHalfRange


    fstp DWORD PTR zoomHalfRange


ZoomOutApply:


    invoke UpdateViewState


    invoke RenderScene


    ret

ZoomOut ENDP


; ============================================================
; RESET VIEW
; ============================================================

ResetView PROC


    ; centerX = 0

    fld DWORD PTR floatZero


    fstp DWORD PTR centerX


    ; centerY = 0

    fld DWORD PTR floatZero


    fstp DWORD PTR centerY


    ; zoom = 10

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


    ; ========================================================
    ; ESC
    ; ========================================================

    cmp eax, VK_ESCAPE

    je KeyboardExit


    ; ========================================================
    ; W
    ; ========================================================

    cmp eax, VK_W

    je KeyboardUp


    ; ========================================================
    ; S
    ; ========================================================

    cmp eax, VK_S

    je KeyboardDown


    ; ========================================================
    ; A
    ; ========================================================

    cmp eax, VK_A

    je KeyboardLeft


    ; ========================================================
    ; D
    ; ========================================================

    cmp eax, VK_D

    je KeyboardRight


    ; ========================================================
    ; R
    ; ========================================================

    cmp eax, VK_R

    je KeyboardReset


    ; ========================================================
    ; + / =
    ; ========================================================

    cmp eax, VK_OEM_PLUS

    je KeyboardZoomIn


    cmp eax, VK_ADD

    je KeyboardZoomIn


    ; ========================================================
    ; -
    ; ========================================================

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


    ; ========================================================
    ; Device Context
    ; ========================================================

    invoke GetDC, targetWnd


    test eax, eax


    jz OpenGLInitFailed


    mov hDC, eax


    ; ========================================================
    ; Pixel Format Descriptor
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
    ; Choose Pixel Format
    ; ========================================================

    invoke ChoosePixelFormat, \
        hDC, \
        ADDR pfd


    test eax, eax


    jz OpenGLInitFailed


    mov pixelFormat, eax


    ; ========================================================
    ; Set Pixel Format
    ; ========================================================

    invoke SetPixelFormat, \
        hDC, \
        pixelFormat, \
        ADDR pfd


    test eax, eax


    jz OpenGLInitFailed


    ; ========================================================
    ; Create OpenGL Rendering Context
    ; ========================================================

    invoke wglCreateContext, hDC


    test eax, eax


    jz OpenGLInitFailed


    mov hGLRC, eax


    ; ========================================================
    ; Make Rendering Context Current
    ; ========================================================

    invoke wglMakeCurrent, \
        hDC, \
        hGLRC


    test eax, eax


    jz OpenGLInitFailed


    ; ========================================================
    ; Background Color
    ; ========================================================

    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


    ; ========================================================
    ; Initial Client Dimensions
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
    ; Calculate mathematical view.
    ; ========================================================

    invoke UpdateViewState


    ; ========================================================
    ; Setup OpenGL pixel viewport.
    ; ========================================================

    invoke SetupViewport


    mov eax, 1


    ret


OpenGLInitFailed:


    xor eax, eax


    ret

InitializeOpenGL ENDP


; ============================================================
; OPENGL CLEANUP
; ============================================================

CleanupOpenGL PROC STDCALL targetWnd:DWORD


    ; ========================================================
    ; Rendering Context
    ; ========================================================

    cmp hGLRC, 0


    je SkipContextCleanup


    invoke wglMakeCurrent, 0, 0


    invoke wglDeleteContext, hGLRC


    mov hGLRC, 0


SkipContextCleanup:


    ; ========================================================
    ; Device Context
    ; ========================================================

    cmp hDC, 0


    je CleanupFinished


    invoke ReleaseDC, \
        targetWnd, \
        hDC


    mov hDC, 0


CleanupFinished:


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
    ; WM_KEYDOWN
    ; ========================================================

    cmp uMsg, WM_KEYDOWN


    je WindowKeyDown


    ; ========================================================
    ; WM_ERASEBKGND
    ; ========================================================

    cmp uMsg, WM_ERASEBKGND


    je WindowBackgroundHandled


    ; ========================================================
    ; WM_DESTROY
    ; ========================================================

    cmp uMsg, WM_DESTROY


    je WindowDestroyed


    ; ========================================================
    ; Default Windows processing.
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
; LOWORD(lParam) = width
; HIWORD(lParam) = height
; ============================================================

WindowSize:


    ; --------------------------------------------------------
    ; Width.
    ; --------------------------------------------------------

    mov eax, lParam


    movzx ecx, ax


    mov clientW, ecx


    ; --------------------------------------------------------
    ; Height.
    ; --------------------------------------------------------

    mov eax, lParam


    shr eax, 16


    movzx ecx, ax


    mov clientH, ecx


    ; --------------------------------------------------------
    ; Window may receive WM_SIZE before OpenGL exists.
    ; --------------------------------------------------------

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
; BACKGROUND ERASE
; ============================================================

WindowBackgroundHandled:


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
; PROGRAM ENTRY
; ============================================================

start:


    ; ========================================================
    ; Initialize x87 FPU.
    ; ========================================================

    finit


    ; ========================================================
    ; Initialize handles/state.
    ; ========================================================

    mov hDC, 0


    mov hGLRC, 0


    mov hMainWnd, 0


    mov clientW, 0


    mov clientH, 0


    ; ========================================================
    ; Get Application Module Handle
    ; ========================================================

    invoke GetModuleHandleA, 0


    mov hInstance, eax


    ; ========================================================
    ; Configure Window Class
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


    ; OpenGL handles the background.

    mov windowClass.hbrBackground, 0


    ; No menu.

    mov windowClass.lpszMenuName, 0


    mov windowClass.lpszClassName, OFFSET className


    ; ========================================================
    ; Register Window Class
    ; ========================================================

    invoke RegisterClassExA, \
        ADDR windowClass


    test eax, eax


    jz RegistrationFailed


    ; ========================================================
    ; Create Main Window
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
    ; Show Window
    ; ========================================================

    invoke ShowWindow, \
        hMainWnd, \
        SW_SHOWNORMAL


    invoke UpdateWindow, hMainWnd


    ; ========================================================
    ; Initial Frame
    ; ========================================================

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


    ; WM_QUIT

    cmp eax, 0


    je ProgramFinished


    ; Error

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