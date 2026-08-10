; ============================================================
; GraphX 
; 32-bit MASM + Win32 + OpenGL
;
;
; Existing:
;   Runtime expression input
;   RPN compiler/evaluator
;   + - * / ^
;   parentheses / unary minus
;   sin / cos / tan / sqrt
;   pan / zoom / reset
;   mouse coordinates
;   crosshair
;   status display
;
; ============================================================

.686
.model flat, stdcall
option casemap:none


; ============================================================
; FORWARD DECLARATIONS
; ============================================================

RenderScene PROTO STDCALL

ExpressionEditProc PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD


; ============================================================
; WIN32 API
; ============================================================

GetModuleHandleA PROTO STDCALL :DWORD
ExitProcess      PROTO STDCALL :DWORD

LoadCursorA PROTO STDCALL :DWORD, :DWORD

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

ValidateRect PROTO STDCALL :DWORD, :DWORD
GetClientRect PROTO STDCALL :DWORD, :DWORD

GetDC PROTO STDCALL :DWORD
ReleaseDC PROTO STDCALL :DWORD, :DWORD

ChoosePixelFormat PROTO STDCALL :DWORD, :DWORD

SetPixelFormat PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

SwapBuffers PROTO STDCALL :DWORD

SetFocus PROTO STDCALL :DWORD

GetWindowTextA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

SetWindowTextA PROTO STDCALL \
    :DWORD, :DWORD

SetWindowLongA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

CallWindowProcA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

MessageBoxA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD


; ============================================================
; WGL
; ============================================================

wglCreateContext PROTO STDCALL :DWORD

wglMakeCurrent PROTO STDCALL \
    :DWORD, :DWORD

wglDeleteContext PROTO STDCALL :DWORD


; ============================================================
; OPENGL
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
; WINDOWS CONSTANTS
; ============================================================

CS_VREDRAW EQU 0001h
CS_HREDRAW EQU 0002h
CS_OWNDC   EQU 0020h

WM_DESTROY     EQU 0002h
WM_SIZE        EQU 0005h
WM_PAINT       EQU 000Fh
WM_ERASEBKGND  EQU 0014h
WM_KEYDOWN     EQU 0100h
WM_CHAR        EQU 0102h
WM_MOUSEMOVE   EQU 0200h
WM_LBUTTONDOWN EQU 0201h

WS_OVERLAPPEDWINDOW EQU 00CF0000h
WS_CLIPCHILDREN     EQU 02000000h
WS_CLIPSIBLINGS     EQU 04000000h

WS_CHILD   EQU 40000000h
WS_VISIBLE EQU 10000000h
WS_TABSTOP EQU 00010000h

WS_EX_CLIENTEDGE EQU 00000200h

ES_AUTOHSCROLL EQU 0080h

CW_USEDEFAULT EQU 80000000h
SW_SHOWNORMAL EQU 1

IDC_ARROW EQU 32512

GWL_WNDPROC EQU 0FFFFFFFCh

MB_OK        EQU 00000000h
MB_ICONERROR EQU 00000010h


; ============================================================
; KEYS
; ============================================================

VK_RETURN EQU 00Dh
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
; PIXEL FORMAT
; ============================================================

PFD_DOUBLEBUFFER   EQU 00000001h
PFD_DRAW_TO_WINDOW EQU 00000004h
PFD_SUPPORT_OPENGL EQU 00000020h

PFD_TYPE_RGBA  EQU 0
PFD_MAIN_PLANE EQU 0


; ============================================================
; OPENGL
; ============================================================

GL_COLOR_BUFFER_BIT EQU 00004000h

GL_LINES      EQU 0001h
GL_LINE_STRIP EQU 0003h

GL_MODELVIEW  EQU 1700h
GL_PROJECTION EQU 1701h


; ============================================================
; GRAPHX
; ============================================================

TOP_PANEL_HEIGHT EQU 72

EDIT_ID   EQU 1001
STATUS_ID EQU 1002

GRAPH_INTERVALS    EQU 1000
GRAPH_SAMPLE_COUNT EQU 1001

; Grid is generated as:
;
; coordinate = integer multiple * gridStep
;
GRID_MULT_MIN EQU -1000
GRID_MULT_MAX EQU  1000


; ============================================================
; EXPRESSION ENGINE
; ============================================================

MAX_EXPRESSION_LENGTH EQU 256

MAX_RPN_TOKENS     EQU 128
MAX_OPERATOR_STACK EQU 64
MAX_EVAL_STACK     EQU 128

MAX_POWER_ABS EQU 64


TOKEN_CONST EQU 1
TOKEN_X     EQU 2

TOKEN_ADD EQU 3
TOKEN_SUB EQU 4
TOKEN_MUL EQU 5
TOKEN_DIV EQU 6

TOKEN_NEG EQU 7

TOKEN_SIN  EQU 8
TOKEN_COS  EQU 9
TOKEN_TAN  EQU 10
TOKEN_SQRT EQU 11

TOKEN_POW EQU 12


OP_NEG EQU 0F0h

OP_SIN  EQU 0F1h
OP_COS  EQU 0F2h
OP_TAN  EQU 0F3h
OP_SQRT EQU 0F4h


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
; DATA
; ============================================================

.data

className db "GraphXWindowClass",0
editClassName db "EDIT",0
staticClassName db "STATIC",0

windowTitle db \
    "GraphX",0


expressionText db "x^2",0,252 DUP(0)
lastGoodExpression db MAX_EXPRESSION_LENGTH DUP(0)


; ============================================================
; STATUS STRINGS
; ============================================================

statusText db 300 DUP(0)

txtMouseX db "Mouse X=",0
txtMouseY db "  Y=",0

txtNoMouse db "--",0

txtCenter db "   |   Center=(",0
txtComma db ", ",0
txtCloseParen db ")",0

txtZoom db "   |   Zoom=",0

txtGrid db "   |   Grid=",0

txtControls db \
    "   |   W/A/S/D pan   +/- zoom   R reset",0


errorTitle db "GraphX Expression Error",0

errorMessage db \
    "Invalid mathematical expression.",13,10,13,10, \
    "Supported:",13,10, \
    "x, decimals, +, -, *, /, ^",13,10, \
    "parentheses, sin(), cos(), tan(), sqrt()",13,10,13,10, \
    "Power exponent must currently be an integer",13,10, \
    "between -64 and +64.",0


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

crossRed   REAL4 0.95
crossGreen REAL4 0.55
crossBlue  REAL4 0.20


; ============================================================
; CONSTANTS
; ============================================================

floatZero REAL4 0.0
floatOne  REAL4 1.0
floatPointOne REAL4 0.1

tanEpsilon REAL4 0.0001

integerTen     DWORD 10
integerHundred DWORD 100


; ============================================================
; CAMERA
; ============================================================

defaultHalfRange REAL4 10.0

centerX REAL4 0.0
centerY REAL4 0.0

zoomHalfRange REAL4 10.0

zoomInFactor  REAL4 0.80
zoomOutFactor REAL4 1.25

minHalfRange REAL4 0.50
maxHalfRange REAL4 50.0

zoomCandidate REAL4 0.0

panFraction REAL4 0.10

panAmountX REAL4 0.0
panAmountY REAL4 0.0


; ============================================================
; VIEW
; ============================================================

viewHalfX REAL4 10.0
viewHalfY REAL4 10.0

viewLeft   REAL4 -10.0
viewRight  REAL4  10.0
viewBottom REAL4 -10.0
viewTop    REAL4  10.0

viewScaleX REAL4 0.1
viewScaleY REAL4 0.1
viewScaleZ REAL4 1.0

viewTranslateX REAL4 0.0
viewTranslateY REAL4 0.0


; ============================================================
; ADAPTIVE GRID
; ============================================================

gridStep REAL4 1.0

gridThreshold01 REAL4 1.0
gridThreshold02 REAL4 2.0
gridThreshold05 REAL4 5.0
gridThreshold10 REAL4 10.0
gridThreshold20 REAL4 20.0

gridStep01 REAL4 0.1
gridStep02 REAL4 0.2
gridStep05 REAL4 0.5
gridStep10 REAL4 1.0
gridStep20 REAL4 2.0
gridStep50 REAL4 5.0


; ============================================================
; GRAPH / PARSER
; ============================================================

graphIntervalCount DWORD GRAPH_INTERVALS

rpnCount DWORD 0
operatorTop DWORD 0

parserExpectOperand DWORD 1
parserNeedFunctionParen DWORD 0

parserNumber REAL4 0.0
parserFractionScale REAL4 0.1

parserDigitInt DWORD 0
parserDigitSeen DWORD 0
parserDecimalSeen DWORD 0

evalStackTop DWORD 0
evalOperandB REAL4 0.0

functionInput REAL4 0.0
functionSin REAL4 0.0
functionCos REAL4 0.0

powerExponentInt DWORD 0

powerBase REAL4 0.0
powerResult REAL4 1.0

powerNegative DWORD 0

graphSegmentActive DWORD 0

statusScaled DWORD 0
statusFraction DWORD 0


; ============================================================
; UNINITIALIZED DATA
; ============================================================

.data?

hInstance DWORD ?
hMainWnd DWORD ?

hExpressionEdit DWORD ?
hStatus DWORD ?

oldEditProc DWORD ?

hDC DWORD ?
hGLRC DWORD ?

pixelFormat DWORD ?

clientW DWORD ?
clientH DWORD ?
graphH DWORD ?

currentX REAL4 ?
currentY REAL4 ?

graphStepX REAL4 ?

gridMultiple DWORD ?
gridCoord REAL4 ?

mousePixelX DWORD ?
mousePixelY DWORD ?
mouseGraphY DWORD ?

mouseWorldX REAL4 ?
mouseWorldY REAL4 ?

mouseRangeX REAL4 ?
mouseRangeY REAL4 ?
mouseOffsetY REAL4 ?

mouseActive DWORD ?

rpnTypes BYTE MAX_RPN_TOKENS DUP(?)
rpnValues REAL4 MAX_RPN_TOKENS DUP(?)

operatorStack BYTE MAX_OPERATOR_STACK DUP(?)
evalStack REAL4 MAX_EVAL_STACK DUP(?)

currentOperator BYTE ?

statusDigits BYTE 16 DUP(?)

windowClass WNDCLASSEX <>
messageData MSG <>
clientRect RECT <>
pfd PIXELFORMATDESCRIPTOR <>


; ============================================================
; CODE
; ============================================================

.code


; ============================================================
; STRING COPY
; ============================================================

CopyCString PROC STDCALL \
    destPtr:DWORD, \
    srcPtr:DWORD, \
    maxCount:DWORD

    push esi
    push edi
    push ecx

    mov edi, destPtr
    mov esi, srcPtr
    mov ecx, maxCount

    test ecx, ecx
    jz CopyDone

    dec ecx

CopyLoop:

    test ecx, ecx
    jz CopyForceZero

    mov al, BYTE PTR [esi]
    mov BYTE PTR [edi], al

    inc esi
    inc edi

    test al, al
    jz CopyDone

    dec ecx

    jmp CopyLoop

CopyForceZero:

    mov BYTE PTR [edi], 0

CopyDone:

    pop ecx
    pop edi
    pop esi

    ret

CopyCString ENDP


; ============================================================
; APPEND STRING
; ============================================================

AppendCString PROC STDCALL \
    destPtr:DWORD, \
    srcPtr:DWORD

    push esi
    push edi

    mov edi, destPtr
    mov esi, srcPtr

AppendStringLoop:

    mov al, BYTE PTR [esi]

    cmp al, 0
    je AppendStringDone

    mov BYTE PTR [edi], al

    inc esi
    inc edi

    jmp AppendStringLoop

AppendStringDone:

    mov BYTE PTR [edi], 0

    mov eax, edi

    pop edi
    pop esi

    ret

AppendCString ENDP


; ============================================================
; APPEND REAL4 WITH TWO DECIMAL PLACES
; ============================================================

AppendFixed2 PROC STDCALL \
    destPtr:DWORD, \
    valuePtr:DWORD

    push esi
    push edi
    push ebx
    push ecx
    push edx

    mov edi, destPtr
    mov esi, valuePtr

    fld DWORD PTR [esi]
    fimul DWORD PTR integerHundred
    fistp DWORD PTR statusScaled

    mov eax, statusScaled

    test eax, eax
    jge FixedPositive

    mov BYTE PTR [edi], '-'
    inc edi

    neg eax

FixedPositive:

    xor edx, edx

    mov ebx, 100
    div ebx

    mov statusFraction, edx

    lea esi, statusDigits

    xor ecx, ecx

    test eax, eax
    jne FixedIntegerLoop

    mov BYTE PTR [edi], '0'
    inc edi

    jmp FixedDecimalPoint

FixedIntegerLoop:

    xor edx, edx

    mov ebx, 10
    div ebx

    add dl, '0'

    mov BYTE PTR [esi + ecx], dl

    inc ecx

    test eax, eax
    jne FixedIntegerLoop

FixedWriteDigits:

    dec ecx

    mov al, BYTE PTR [esi + ecx]

    mov BYTE PTR [edi], al

    inc edi

    test ecx, ecx
    jne FixedWriteDigits

FixedDecimalPoint:

    mov BYTE PTR [edi], '.'
    inc edi

    mov eax, statusFraction

    xor edx, edx

    mov ebx, 10
    div ebx

    add al, '0'

    mov BYTE PTR [edi], al
    inc edi

    add dl, '0'

    mov BYTE PTR [edi], dl
    inc edi

    mov BYTE PTR [edi], 0

    mov eax, edi

    pop edx
    pop ecx
    pop ebx
    pop edi
    pop esi

    ret

AppendFixed2 ENDP


; ============================================================
; STATUS TEXT
; ============================================================

UpdateStatusText PROC STDCALL

    push edi

    lea edi, statusText

    invoke AppendCString, edi, ADDR txtMouseX
    mov edi, eax

    cmp mouseActive, 0
    je StatusNoMouseX

    invoke AppendFixed2, edi, ADDR mouseWorldX
    mov edi, eax

    jmp StatusMouseY

StatusNoMouseX:

    invoke AppendCString, edi, ADDR txtNoMouse
    mov edi, eax

StatusMouseY:

    invoke AppendCString, edi, ADDR txtMouseY
    mov edi, eax

    cmp mouseActive, 0
    je StatusNoMouseY

    invoke AppendFixed2, edi, ADDR mouseWorldY
    mov edi, eax

    jmp StatusCenter

StatusNoMouseY:

    invoke AppendCString, edi, ADDR txtNoMouse
    mov edi, eax

StatusCenter:

    invoke AppendCString, edi, ADDR txtCenter
    mov edi, eax

    invoke AppendFixed2, edi, ADDR centerX
    mov edi, eax

    invoke AppendCString, edi, ADDR txtComma
    mov edi, eax

    invoke AppendFixed2, edi, ADDR centerY
    mov edi, eax

    invoke AppendCString, edi, ADDR txtCloseParen
    mov edi, eax

    invoke AppendCString, edi, ADDR txtZoom
    mov edi, eax

    invoke AppendFixed2, edi, ADDR zoomHalfRange
    mov edi, eax

    invoke AppendCString, edi, ADDR txtGrid
    mov edi, eax

    invoke AppendFixed2, edi, ADDR gridStep
    mov edi, eax

    invoke AppendCString, edi, ADDR txtControls

    cmp hStatus, 0
    je StatusDone

    invoke SetWindowTextA, hStatus, ADDR statusText

StatusDone:

    pop edi

    ret

UpdateStatusText ENDP


; ============================================================
; SELECT ADAPTIVE GRID STEP
;
; Zoom <= 1   : .1
; Zoom <= 2   : .2
; Zoom <= 5   : .5
; Zoom <= 10  : 1
; Zoom <= 20  : 2
; otherwise   : 5
; ============================================================

UpdateGridStep PROC STDCALL

    fld DWORD PTR zoomHalfRange
    fcomp DWORD PTR gridThreshold01
    fnstsw ax
    sahf
    jbe GridUse01

    fld DWORD PTR zoomHalfRange
    fcomp DWORD PTR gridThreshold02
    fnstsw ax
    sahf
    jbe GridUse02

    fld DWORD PTR zoomHalfRange
    fcomp DWORD PTR gridThreshold05
    fnstsw ax
    sahf
    jbe GridUse05

    fld DWORD PTR zoomHalfRange
    fcomp DWORD PTR gridThreshold10
    fnstsw ax
    sahf
    jbe GridUse10

    fld DWORD PTR zoomHalfRange
    fcomp DWORD PTR gridThreshold20
    fnstsw ax
    sahf
    jbe GridUse20

    fld DWORD PTR gridStep50
    fstp DWORD PTR gridStep

    ret

GridUse01:

    fld DWORD PTR gridStep01
    fstp DWORD PTR gridStep
    ret

GridUse02:

    fld DWORD PTR gridStep02
    fstp DWORD PTR gridStep
    ret

GridUse05:

    fld DWORD PTR gridStep05
    fstp DWORD PTR gridStep
    ret

GridUse10:

    fld DWORD PTR gridStep10
    fstp DWORD PTR gridStep
    ret

GridUse20:

    fld DWORD PTR gridStep20
    fstp DWORD PTR gridStep
    ret

UpdateGridStep ENDP


; ============================================================
; OPERATOR PRECEDENCE
; ============================================================

GetOperatorPrecedence PROC STDCALL opValue:DWORD

    mov eax, opValue

    cmp al, '+'
    je Prec1

    cmp al, '-'
    je Prec1

    cmp al, '*'
    je Prec2

    cmp al, '/'
    je Prec2

    cmp al, OP_NEG
    je Prec3

    cmp al, '^'
    je Prec4

    xor eax, eax
    ret

Prec1:
    mov eax, 1
    ret

Prec2:
    mov eax, 2
    ret

Prec3:
    mov eax, 3
    ret

Prec4:
    mov eax, 4
    ret

GetOperatorPrecedence ENDP


; ============================================================
; PUSH OPERATOR
; ============================================================

PushOperatorMarker PROC STDCALL marker:DWORD

    mov ecx, operatorTop

    cmp ecx, MAX_OPERATOR_STACK
    jae PushMarkerFailed

    mov eax, marker

    mov BYTE PTR [operatorStack + ecx], al

    inc ecx

    mov operatorTop, ecx

    mov eax, 1
    ret

PushMarkerFailed:

    xor eax, eax
    ret

PushOperatorMarker ENDP


; ============================================================
; EMIT RPN OPERATOR
; ============================================================

EmitOperatorToken PROC STDCALL opValue:DWORD

    mov ecx, rpnCount

    cmp ecx, MAX_RPN_TOKENS
    jae EmitFailed

    mov eax, opValue

    cmp al, '+'
    je EmitAdd

    cmp al, '-'
    je EmitSub

    cmp al, '*'
    je EmitMul

    cmp al, '/'
    je EmitDiv

    cmp al, '^'
    je EmitPow

    cmp al, OP_NEG
    je EmitNeg

    cmp al, OP_SIN
    je EmitSin

    cmp al, OP_COS
    je EmitCos

    cmp al, OP_TAN
    je EmitTan

    cmp al, OP_SQRT
    je EmitSqrt

    jmp EmitFailed

EmitAdd:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_ADD
    jmp EmitSuccess

EmitSub:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_SUB
    jmp EmitSuccess

EmitMul:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_MUL
    jmp EmitSuccess

EmitDiv:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_DIV
    jmp EmitSuccess

EmitPow:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_POW
    jmp EmitSuccess

EmitNeg:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_NEG
    jmp EmitSuccess

EmitSin:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_SIN
    jmp EmitSuccess

EmitCos:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_COS
    jmp EmitSuccess

EmitTan:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_TAN
    jmp EmitSuccess

EmitSqrt:
    mov BYTE PTR [rpnTypes + ecx], TOKEN_SQRT

EmitSuccess:

    inc ecx

    mov rpnCount, ecx

    mov eax, 1
    ret

EmitFailed:

    xor eax, eax
    ret

EmitOperatorToken ENDP


; ============================================================
; COMPILE EXPRESSION
; ============================================================

CompileExpression PROC STDCALL

    push esi
    push edi
    push ebx
    push ecx
    push edx

    mov rpnCount, 0
    mov operatorTop, 0

    mov parserExpectOperand, 1
    mov parserNeedFunctionParen, 0

    mov esi, OFFSET expressionText

ParseLoop:

    mov al, BYTE PTR [esi]

    cmp al, 0
    je ParseEnd

    cmp al, ' '
    je ParseAdvance

    cmp al, 9
    je ParseAdvance

    cmp parserNeedFunctionParen, 0
    je ParseNormal

    cmp al, '('
    jne ParseFailed

    mov parserNeedFunctionParen, 0

    jmp ParseLeftParenthesis

ParseNormal:

    cmp al, 'x'
    je ParseVariable

    cmp al, 'X'
    je ParseVariable

    cmp al, '('
    je ParseLeftParenthesis

    cmp al, ')'
    je ParseRightParenthesis

    cmp al, '0'
    jb ParseCheckDecimal

    cmp al, '9'
    jbe ParseNumber

ParseCheckDecimal:

    cmp al, '.'
    je ParseNumber

    mov dl, al
    or dl, 20h

    cmp dl, 's'
    je ParseSFunction

    cmp dl, 'c'
    je ParseCosFunction

    cmp dl, 't'
    je ParseTanFunction

    cmp al, '+'
    je ParsePlus

    cmp al, '-'
    je ParseMinus

    cmp al, '*'
    je ParseBinaryOperator

    cmp al, '/'
    je ParseBinaryOperator

    cmp al, '^'
    je ParseBinaryOperator

    jmp ParseFailed


ParseAdvance:

    inc esi

    jmp ParseLoop


; ============================================================
; VARIABLE
; ============================================================

ParseVariable:

    cmp parserExpectOperand, 1
    jne ParseFailed

    mov ecx, rpnCount

    cmp ecx, MAX_RPN_TOKENS
    jae ParseFailed

    mov BYTE PTR [rpnTypes + ecx], TOKEN_X

    inc ecx

    mov rpnCount, ecx

    mov parserExpectOperand, 0

    inc esi

    jmp ParseLoop


; ============================================================
; SIN / SQRT
; ============================================================

ParseSFunction:

    cmp parserExpectOperand, 1
    jne ParseFailed

    mov al, BYTE PTR [esi + 1]
    or al, 20h

    cmp al, 'i'
    jne ParseCheckSqrt

    mov al, BYTE PTR [esi + 2]
    or al, 20h

    cmp al, 'n'
    jne ParseFailed

    invoke PushOperatorMarker, OP_SIN

    test eax, eax
    jz ParseFailed

    add esi, 3

    mov parserNeedFunctionParen, 1

    jmp ParseLoop


ParseCheckSqrt:

    mov al, BYTE PTR [esi + 1]
    or al, 20h

    cmp al, 'q'
    jne ParseFailed

    mov al, BYTE PTR [esi + 2]
    or al, 20h

    cmp al, 'r'
    jne ParseFailed

    mov al, BYTE PTR [esi + 3]
    or al, 20h

    cmp al, 't'
    jne ParseFailed

    invoke PushOperatorMarker, OP_SQRT

    test eax, eax
    jz ParseFailed

    add esi, 4

    mov parserNeedFunctionParen, 1

    jmp ParseLoop


; ============================================================
; COS
; ============================================================

ParseCosFunction:

    cmp parserExpectOperand, 1
    jne ParseFailed

    mov al, BYTE PTR [esi + 1]
    or al, 20h

    cmp al, 'o'
    jne ParseFailed

    mov al, BYTE PTR [esi + 2]
    or al, 20h

    cmp al, 's'
    jne ParseFailed

    invoke PushOperatorMarker, OP_COS

    test eax, eax
    jz ParseFailed

    add esi, 3

    mov parserNeedFunctionParen, 1

    jmp ParseLoop


; ============================================================
; TAN
; ============================================================

ParseTanFunction:

    cmp parserExpectOperand, 1
    jne ParseFailed

    mov al, BYTE PTR [esi + 1]
    or al, 20h

    cmp al, 'a'
    jne ParseFailed

    mov al, BYTE PTR [esi + 2]
    or al, 20h

    cmp al, 'n'
    jne ParseFailed

    invoke PushOperatorMarker, OP_TAN

    test eax, eax
    jz ParseFailed

    add esi, 3

    mov parserNeedFunctionParen, 1

    jmp ParseLoop


; ============================================================
; LEFT PARENTHESIS
; ============================================================

ParseLeftParenthesis:

    cmp parserExpectOperand, 1
    jne ParseFailed

    invoke PushOperatorMarker, '('

    test eax, eax
    jz ParseFailed

    inc esi

    jmp ParseLoop


; ============================================================
; RIGHT PARENTHESIS
; ============================================================

ParseRightParenthesis:

    cmp parserExpectOperand, 0
    jne ParseFailed

RightParenPop:

    mov ecx, operatorTop

    test ecx, ecx
    jz ParseFailed

    dec ecx

    mov al, BYTE PTR [operatorStack + ecx]

    cmp al, '('
    je RightParenFound

    mov operatorTop, ecx

    movzx eax, al

    invoke EmitOperatorToken, eax

    test eax, eax
    jz ParseFailed

    jmp RightParenPop

RightParenFound:

    mov operatorTop, ecx

    inc esi

RightParenFunctionCheck:

    mov ecx, operatorTop

    test ecx, ecx
    jz RightParenUnaryCheck

    dec ecx

    mov al, BYTE PTR [operatorStack + ecx]

    cmp al, OP_SIN
    je RightParenEmitFunction

    cmp al, OP_COS
    je RightParenEmitFunction

    cmp al, OP_TAN
    je RightParenEmitFunction

    cmp al, OP_SQRT
    je RightParenEmitFunction

    jmp RightParenUnaryCheck

RightParenEmitFunction:

    mov operatorTop, ecx

    movzx eax, al

    invoke EmitOperatorToken, eax

    test eax, eax
    jz ParseFailed

RightParenUnaryCheck:

    mov ecx, operatorTop

    test ecx, ecx
    jz RightParenDone

    dec ecx

    mov al, BYTE PTR [operatorStack + ecx]

    cmp al, OP_NEG
    jne RightParenDone

    mov operatorTop, ecx

    movzx eax, al

    invoke EmitOperatorToken, eax

    test eax, eax
    jz ParseFailed

    jmp RightParenUnaryCheck

RightParenDone:

    mov parserExpectOperand, 0

    jmp ParseLoop


; ============================================================
; NUMBER
; ============================================================

ParseNumber:

    cmp parserExpectOperand, 1
    jne ParseFailed

    fld DWORD PTR floatZero
    fstp DWORD PTR parserNumber

    fld DWORD PTR floatPointOne
    fstp DWORD PTR parserFractionScale

    mov parserDigitSeen, 0
    mov parserDecimalSeen, 0

NumberLoop:

    mov al, BYTE PTR [esi]

    cmp al, '0'
    jb NumberCheckDot

    cmp al, '9'
    ja NumberCheckDot

    movzx eax, al

    sub eax, '0'

    mov parserDigitInt, eax

    mov parserDigitSeen, 1

    cmp parserDecimalSeen, 0
    jne NumberFraction

    fld DWORD PTR parserNumber

    fimul DWORD PTR integerTen

    fiadd DWORD PTR parserDigitInt

    fstp DWORD PTR parserNumber

    inc esi

    jmp NumberLoop

NumberFraction:

    fild DWORD PTR parserDigitInt

    fmul DWORD PTR parserFractionScale

    fadd DWORD PTR parserNumber

    fstp DWORD PTR parserNumber

    fld DWORD PTR parserFractionScale

    fmul DWORD PTR floatPointOne

    fstp DWORD PTR parserFractionScale

    inc esi

    jmp NumberLoop

NumberCheckDot:

    cmp al, '.'
    jne NumberFinished

    cmp parserDecimalSeen, 0
    jne NumberFinished

    mov parserDecimalSeen, 1

    inc esi

    jmp NumberLoop

NumberFinished:

    cmp parserDigitSeen, 1
    jne ParseFailed

    mov edi, rpnCount

    cmp edi, MAX_RPN_TOKENS
    jae ParseFailed

    mov BYTE PTR [rpnTypes + edi], TOKEN_CONST

    fld DWORD PTR parserNumber

    fstp DWORD PTR [rpnValues + edi*4]

    inc edi

    mov rpnCount, edi

    mov parserExpectOperand, 0

    jmp ParseLoop


; ============================================================
; PLUS / MINUS
; ============================================================

ParsePlus:

    cmp parserExpectOperand, 1
    je ParseUnaryPlus

    jmp ParseBinaryOperator

ParseUnaryPlus:

    inc esi

    jmp ParseLoop


ParseMinus:

    cmp parserExpectOperand, 1
    je ParseUnaryMinus

    jmp ParseBinaryOperator

ParseUnaryMinus:

    invoke PushOperatorMarker, OP_NEG

    test eax, eax
    jz ParseFailed

    inc esi

    jmp ParseLoop


; ============================================================
; BINARY OPERATOR
; ============================================================

ParseBinaryOperator:

    cmp parserExpectOperand, 0
    jne ParseFailed

    mov currentOperator, al

    movzx eax, BYTE PTR currentOperator

    invoke GetOperatorPrecedence, eax

    mov ebx, eax

BinaryPopLoop:

    mov ecx, operatorTop

    test ecx, ecx
    jz PushBinaryOperator

    dec ecx

    mov al, BYTE PTR [operatorStack + ecx]

    cmp al, '('
    je PushBinaryOperator

    movzx eax, al

    invoke GetOperatorPrecedence, eax

    test eax, eax
    jz PushBinaryOperator

    cmp currentOperator, '^'
    jne BinaryNormalAssociativity

    cmp eax, ebx
    jbe PushBinaryOperator

    jmp BinaryPopOperator

BinaryNormalAssociativity:

    cmp eax, ebx
    jb PushBinaryOperator

BinaryPopOperator:

    mov ecx, operatorTop

    dec ecx

    movzx eax, BYTE PTR [operatorStack + ecx]

    mov operatorTop, ecx

    invoke EmitOperatorToken, eax

    test eax, eax
    jz ParseFailed

    jmp BinaryPopLoop

PushBinaryOperator:

    movzx eax, BYTE PTR currentOperator

    invoke PushOperatorMarker, eax

    test eax, eax
    jz ParseFailed

    mov parserExpectOperand, 1

    inc esi

    jmp ParseLoop


; ============================================================
; END PARSE
; ============================================================

ParseEnd:

    cmp parserNeedFunctionParen, 0
    jne ParseFailed

    cmp parserExpectOperand, 0
    jne ParseFailed

    cmp rpnCount, 0
    je ParseFailed

FlushOperatorStack:

    mov ecx, operatorTop

    test ecx, ecx
    jz CompileSuccess

    dec ecx

    mov al, BYTE PTR [operatorStack + ecx]

    cmp al, '('
    je ParseFailed

    cmp al, OP_SIN
    je ParseFailed

    cmp al, OP_COS
    je ParseFailed

    cmp al, OP_TAN
    je ParseFailed

    cmp al, OP_SQRT
    je ParseFailed

    mov operatorTop, ecx

    movzx eax, al

    invoke EmitOperatorToken, eax

    test eax, eax
    jz ParseFailed

    jmp FlushOperatorStack

CompileSuccess:

    mov eax, 1

    jmp CompileExit

ParseFailed:

    xor eax, eax

CompileExit:

    pop edx
    pop ecx
    pop ebx
    pop edi
    pop esi

    ret

CompileExpression ENDP


; ============================================================
; EVALUATE RPN
; ============================================================

EvaluateCurrentFunction PROC STDCALL

    push esi
    push edi
    push ebx
    push ecx
    push edx

    mov evalStackTop, 0

    xor esi, esi

    mov edi, rpnCount

    test edi, edi
    jz EvaluationFailed

EvaluationLoop:

    cmp esi, edi
    jae EvaluationFinished

    movzx eax, BYTE PTR [rpnTypes + esi]

    cmp eax, TOKEN_CONST
    je EvaluateConstant

    cmp eax, TOKEN_X
    je EvaluateVariable

    cmp eax, TOKEN_NEG
    je EvaluateNeg

    cmp eax, TOKEN_SIN
    je EvaluateSin

    cmp eax, TOKEN_COS
    je EvaluateCos

    cmp eax, TOKEN_TAN
    je EvaluateTan

    cmp eax, TOKEN_SQRT
    je EvaluateSqrt

    cmp eax, TOKEN_ADD
    je EvaluateBinary

    cmp eax, TOKEN_SUB
    je EvaluateBinary

    cmp eax, TOKEN_MUL
    je EvaluateBinary

    cmp eax, TOKEN_DIV
    je EvaluateBinary

    cmp eax, TOKEN_POW
    je EvaluateBinary

    jmp EvaluationFailed


EvaluateConstant:

    mov ecx, evalStackTop

    cmp ecx, MAX_EVAL_STACK
    jae EvaluationFailed

    mov edx, DWORD PTR [rpnValues + esi*4]

    mov DWORD PTR [evalStack + ecx*4], edx

    inc ecx

    mov evalStackTop, ecx

    jmp EvaluationNext


EvaluateVariable:

    mov ecx, evalStackTop

    cmp ecx, MAX_EVAL_STACK
    jae EvaluationFailed

    mov edx, DWORD PTR currentX

    mov DWORD PTR [evalStack + ecx*4], edx

    inc ecx

    mov evalStackTop, ecx

    jmp EvaluationNext


EvaluateNeg:

    mov ecx, evalStackTop

    cmp ecx, 1
    jb EvaluationFailed

    dec ecx

    fld DWORD PTR [evalStack + ecx*4]

    fchs

    fstp DWORD PTR [evalStack + ecx*4]

    jmp EvaluationNext


EvaluateSin:

    mov ecx, evalStackTop

    cmp ecx, 1
    jb EvaluationFailed

    dec ecx

    fld DWORD PTR [evalStack + ecx*4]

    fsin

    fstp DWORD PTR [evalStack + ecx*4]

    jmp EvaluationNext


EvaluateCos:

    mov ecx, evalStackTop

    cmp ecx, 1
    jb EvaluationFailed

    dec ecx

    fld DWORD PTR [evalStack + ecx*4]

    fcos

    fstp DWORD PTR [evalStack + ecx*4]

    jmp EvaluationNext


EvaluateTan:

    mov ecx, evalStackTop

    cmp ecx, 1
    jb EvaluationFailed

    dec ecx

    mov eax, DWORD PTR [evalStack + ecx*4]

    mov DWORD PTR functionInput, eax

    fld DWORD PTR functionInput

    fsin

    fstp DWORD PTR functionSin

    fld DWORD PTR functionInput

    fcos

    fstp DWORD PTR functionCos

    fld DWORD PTR functionCos

    fabs

    fcomp DWORD PTR tanEpsilon

    fnstsw ax
    sahf

    jb EvaluationFailed

    fld DWORD PTR functionSin

    fdiv DWORD PTR functionCos

    fstp DWORD PTR [evalStack + ecx*4]

    jmp EvaluationNext


EvaluateSqrt:

    mov ecx, evalStackTop

    cmp ecx, 1
    jb EvaluationFailed

    dec ecx

    fld DWORD PTR [evalStack + ecx*4]

    fcomp DWORD PTR floatZero

    fnstsw ax
    sahf

    jb EvaluationFailed

    fld DWORD PTR [evalStack + ecx*4]

    fsqrt

    fstp DWORD PTR [evalStack + ecx*4]

    jmp EvaluationNext


; ============================================================
; BINARY OPERATORS
; ============================================================

EvaluateBinary:

    mov ebx, eax

    mov ecx, evalStackTop

    cmp ecx, 2
    jb EvaluationFailed

    sub ecx, 2

    mov edx, DWORD PTR [evalStack + ecx*4 + 4]

    mov DWORD PTR evalOperandB, edx

    cmp ebx, TOKEN_POW
    je ExecutePower

    cmp ebx, TOKEN_DIV
    jne LoadBinaryA

    mov eax, edx

    and eax, 7FFFFFFFh

    jz EvaluationFailed

LoadBinaryA:

    fld DWORD PTR [evalStack + ecx*4]

    cmp ebx, TOKEN_ADD
    je ExecuteAdd

    cmp ebx, TOKEN_SUB
    je ExecuteSub

    cmp ebx, TOKEN_MUL
    je ExecuteMul

    cmp ebx, TOKEN_DIV
    je ExecuteDiv

    fstp st(0)

    jmp EvaluationFailed


ExecuteAdd:

    fadd DWORD PTR evalOperandB

    jmp StoreBinaryResult


ExecuteSub:

    fsub DWORD PTR evalOperandB

    jmp StoreBinaryResult


ExecuteMul:

    fmul DWORD PTR evalOperandB

    jmp StoreBinaryResult


ExecuteDiv:

    fdiv DWORD PTR evalOperandB


StoreBinaryResult:

    fstp DWORD PTR [evalStack + ecx*4]

    inc ecx

    mov evalStackTop, ecx

    jmp EvaluationNext


; ============================================================
; INTEGER POWER
; ============================================================

ExecutePower:

    mov eax, DWORD PTR evalOperandB

    mov edx, eax

    and edx, 7F800000h

    cmp edx, 7F800000h
    je EvaluationFailed

    fld DWORD PTR evalOperandB

    fistp DWORD PTR powerExponentInt

    fild DWORD PTR powerExponentInt

    fcomp DWORD PTR evalOperandB

    fnstsw ax
    sahf

    jne EvaluationFailed

    mov eax, powerExponentInt

    cmp eax, MAX_POWER_ABS
    jg EvaluationFailed

    cmp eax, -MAX_POWER_ABS
    jl EvaluationFailed

    mov eax, DWORD PTR [evalStack + ecx*4]

    mov DWORD PTR powerBase, eax

    fld DWORD PTR floatOne

    fstp DWORD PTR powerResult

    mov powerNegative, 0

    mov eax, powerExponentInt

    test eax, eax
    jz PowerFinished

    jg PowerPositive

    mov powerNegative, 1

    mov edx, DWORD PTR powerBase

    and edx, 7FFFFFFFh

    jz EvaluationFailed

    neg eax

PowerPositive:

PowerLoop:

    test eax, eax
    jz PowerMultiplicationFinished

    fld DWORD PTR powerResult

    fmul DWORD PTR powerBase

    fstp DWORD PTR powerResult

    dec eax

    jmp PowerLoop

PowerMultiplicationFinished:

    cmp powerNegative, 0
    je PowerFinished

    fld DWORD PTR floatOne

    fdiv DWORD PTR powerResult

    fstp DWORD PTR powerResult

PowerFinished:

    mov eax, DWORD PTR powerResult

    mov edx, eax

    and edx, 7F800000h

    cmp edx, 7F800000h
    je EvaluationFailed

    mov DWORD PTR [evalStack + ecx*4], eax

    inc ecx

    mov evalStackTop, ecx

    jmp EvaluationNext


EvaluationNext:

    inc esi

    jmp EvaluationLoop


EvaluationFinished:

    cmp evalStackTop, 1
    jne EvaluationFailed

    mov eax, DWORD PTR [evalStack]

    mov edx, eax

    and edx, 7F800000h

    cmp edx, 7F800000h
    je EvaluationFailed

    mov DWORD PTR currentY, eax

    mov eax, 1

    jmp EvaluationExit


EvaluationFailed:

    xor eax, eax


EvaluationExit:

    pop edx
    pop ecx
    pop ebx
    pop edi
    pop esi

    ret

EvaluateCurrentFunction ENDP


; ============================================================
; APPLY EXPRESSION
; ============================================================

ApplyExpression PROC STDCALL

    invoke GetWindowTextA, \
        hExpressionEdit, \
        ADDR expressionText, \
        MAX_EXPRESSION_LENGTH

    invoke CompileExpression

    test eax, eax
    jz ApplyExpressionFailed

    invoke CopyCString, \
        ADDR lastGoodExpression, \
        ADDR expressionText, \
        MAX_EXPRESSION_LENGTH

    invoke SetFocus, hMainWnd

    invoke RenderScene

    mov eax, 1

    ret

ApplyExpressionFailed:

    invoke CopyCString, \
        ADDR expressionText, \
        ADDR lastGoodExpression, \
        MAX_EXPRESSION_LENGTH

    invoke SetWindowTextA, \
        hExpressionEdit, \
        ADDR expressionText

    invoke CompileExpression

    invoke MessageBoxA, \
        hMainWnd, \
        ADDR errorMessage, \
        ADDR errorTitle, \
        MB_OK OR MB_ICONERROR

    invoke SetFocus, hExpressionEdit

    xor eax, eax

    ret

ApplyExpression ENDP


; ============================================================
; UPDATE CAMERA
; ============================================================

UpdateViewState PROC STDCALL

    cmp clientW, 0
    je UpdateViewDone

    cmp graphH, 0
    je UpdateViewDone

    mov eax, clientW

    cmp eax, graphH
    jae ViewWide

ViewTall:

    fld DWORD PTR zoomHalfRange
    fstp DWORD PTR viewHalfX

    fld DWORD PTR zoomHalfRange
    fimul DWORD PTR graphH
    fidiv DWORD PTR clientW
    fstp DWORD PTR viewHalfY

    jmp CalculateViewBounds

ViewWide:

    fld DWORD PTR zoomHalfRange
    fstp DWORD PTR viewHalfY

    fld DWORD PTR zoomHalfRange
    fimul DWORD PTR clientW
    fidiv DWORD PTR graphH
    fstp DWORD PTR viewHalfX

CalculateViewBounds:

    fld DWORD PTR centerX
    fsub DWORD PTR viewHalfX
    fstp DWORD PTR viewLeft

    fld DWORD PTR centerX
    fadd DWORD PTR viewHalfX
    fstp DWORD PTR viewRight

    fld DWORD PTR centerY
    fsub DWORD PTR viewHalfY
    fstp DWORD PTR viewBottom

    fld DWORD PTR centerY
    fadd DWORD PTR viewHalfY
    fstp DWORD PTR viewTop

    fld DWORD PTR floatOne
    fdiv DWORD PTR viewHalfX
    fstp DWORD PTR viewScaleX

    fld DWORD PTR floatOne
    fdiv DWORD PTR viewHalfY
    fstp DWORD PTR viewScaleY

    fld DWORD PTR centerX
    fchs
    fstp DWORD PTR viewTranslateX

    fld DWORD PTR centerY
    fchs
    fstp DWORD PTR viewTranslateY

    ; NEW:
    ; Select grid spacing after zoom/view update.

    invoke UpdateGridStep

UpdateViewDone:

    ret

UpdateViewState ENDP


; ============================================================
; VIEWPORT
; ============================================================

SetupViewport PROC STDCALL

    cmp clientW, 0
    je SetupViewportDone

    cmp graphH, 0
    je SetupViewportDone

    invoke glViewport, \
        0, \
        0, \
        clientW, \
        graphH

SetupViewportDone:

    ret

SetupViewport ENDP


; ============================================================
; PROJECTION
; ============================================================

SetupProjection PROC STDCALL

    invoke glMatrixMode, GL_PROJECTION

    invoke glLoadIdentity

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
; ADAPTIVE GRID
;
; coordinate = gridMultiple * gridStep
;
; Examples:
;
; gridStep=.1:
; -1.0, -.9, -.8 ...
;
; gridStep=5:
; -10, -5, 0, 5, 10 ...
; ============================================================

DrawGrid PROC STDCALL

    invoke glColor3f, \
        DWORD PTR gridRed, \
        DWORD PTR gridGreen, \
        DWORD PTR gridBlue

    invoke glBegin, GL_LINES

    mov gridMultiple, GRID_MULT_MIN

GridLoop:

    cmp gridMultiple, 0
    je GridNext

    ; coordinate = integer * gridStep

    fild DWORD PTR gridMultiple

    fmul DWORD PTR gridStep

    fstp DWORD PTR gridCoord

    ; vertical

    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewBottom

    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewTop

    ; horizontal

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR gridCoord

    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR gridCoord

GridNext:

    inc gridMultiple

    cmp gridMultiple, GRID_MULT_MAX
    jle GridLoop

    invoke glEnd

    ret

DrawGrid ENDP


; ============================================================
; AXES
; ============================================================

DrawAxes PROC STDCALL

    invoke glColor3f, \
        DWORD PTR axisRed, \
        DWORD PTR axisGreen, \
        DWORD PTR axisBlue

    invoke glBegin, GL_LINES

    ; X axis

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR floatZero

    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR floatZero

    ; Y axis

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
; GRAPH STEP
; ============================================================

CalculateGraphStep PROC STDCALL

    fld DWORD PTR viewRight

    fsub DWORD PTR viewLeft

    fidiv DWORD PTR graphIntervalCount

    fstp DWORD PTR graphStepX

    ret

CalculateGraphStep ENDP


; ============================================================
; DRAW FUNCTION
; ============================================================

DrawFunction PROC STDCALL

    push edi

    invoke glColor3f, \
        DWORD PTR graphRed, \
        DWORD PTR graphGreen, \
        DWORD PTR graphBlue

    invoke CalculateGraphStep

    fld DWORD PTR viewLeft

    fstp DWORD PTR currentX

    mov edi, GRAPH_SAMPLE_COUNT

    mov graphSegmentActive, 0

GraphLoop:

    invoke EvaluateCurrentFunction

    test eax, eax
    jz InvalidGraphPoint

    cmp graphSegmentActive, 0
    jne PlotGraphPoint

    invoke glBegin, GL_LINE_STRIP

    mov graphSegmentActive, 1

PlotGraphPoint:

    invoke glVertex2f, \
        DWORD PTR currentX, \
        DWORD PTR currentY

    jmp AdvanceGraph

InvalidGraphPoint:

    cmp graphSegmentActive, 0
    je AdvanceGraph

    invoke glEnd

    mov graphSegmentActive, 0

AdvanceGraph:

    fld DWORD PTR currentX

    fadd DWORD PTR graphStepX

    fstp DWORD PTR currentX

    dec edi

    jnz GraphLoop

    cmp graphSegmentActive, 0
    je DrawFunctionDone

    invoke glEnd

    mov graphSegmentActive, 0

DrawFunctionDone:

    pop edi

    ret

DrawFunction ENDP


; ============================================================
; MOUSE -> MATHEMATICAL COORDINATE
; ============================================================

UpdateMouseWorld PROC STDCALL

    cmp mouseActive, 0
    je UpdateMouseDone

    cmp clientW, 0
    je UpdateMouseDone

    cmp graphH, 0
    je UpdateMouseDone

    mov eax, mousePixelY

    cmp eax, TOP_PANEL_HEIGHT
    jb MouseOutsideGraph

    sub eax, TOP_PANEL_HEIGHT

    mov mouseGraphY, eax

    cmp eax, graphH
    ja MouseOutsideGraph

    fld DWORD PTR viewRight

    fsub DWORD PTR viewLeft

    fstp DWORD PTR mouseRangeX

    fild DWORD PTR mousePixelX

    fidiv DWORD PTR clientW

    fmul DWORD PTR mouseRangeX

    fadd DWORD PTR viewLeft

    fstp DWORD PTR mouseWorldX

    fld DWORD PTR viewTop

    fsub DWORD PTR viewBottom

    fstp DWORD PTR mouseRangeY

    fild DWORD PTR mouseGraphY

    fidiv DWORD PTR graphH

    fmul DWORD PTR mouseRangeY

    fstp DWORD PTR mouseOffsetY

    fld DWORD PTR viewTop

    fsub DWORD PTR mouseOffsetY

    fstp DWORD PTR mouseWorldY

    ret

MouseOutsideGraph:

    mov mouseActive, 0

UpdateMouseDone:

    ret

UpdateMouseWorld ENDP


; ============================================================
; CROSSHAIR
; ============================================================

DrawCrosshair PROC STDCALL

    cmp mouseActive, 0
    je CrosshairDone

    invoke glColor3f, \
        DWORD PTR crossRed, \
        DWORD PTR crossGreen, \
        DWORD PTR crossBlue

    invoke glBegin, GL_LINES

    invoke glVertex2f, \
        DWORD PTR mouseWorldX, \
        DWORD PTR viewBottom

    invoke glVertex2f, \
        DWORD PTR mouseWorldX, \
        DWORD PTR viewTop

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR mouseWorldY

    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR mouseWorldY

    invoke glEnd

CrosshairDone:

    ret

DrawCrosshair ENDP


; ============================================================
; RENDER
; ============================================================

RenderScene PROC STDCALL

    cmp hGLRC, 0
    je RenderDone

    cmp clientW, 0
    je RenderDone

    cmp graphH, 0
    je RenderDone

    invoke glClear, GL_COLOR_BUFFER_BIT

    invoke SetupProjection

    invoke DrawGrid

    invoke DrawAxes

    invoke DrawFunction

    invoke DrawCrosshair

    invoke SwapBuffers, hDC

RenderDone:

    ret

RenderScene ENDP


; ============================================================
; PAN
; ============================================================

CalculatePanStep PROC STDCALL

    fld DWORD PTR viewHalfX

    fmul DWORD PTR panFraction

    fstp DWORD PTR panAmountX

    fld DWORD PTR viewHalfY

    fmul DWORD PTR panFraction

    fstp DWORD PTR panAmountY

    ret

CalculatePanStep ENDP


PanLeft PROC STDCALL

    invoke CalculatePanStep

    fld DWORD PTR centerX

    fsub DWORD PTR panAmountX

    fstp DWORD PTR centerX

    invoke UpdateViewState
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    ret

PanLeft ENDP


PanRight PROC STDCALL

    invoke CalculatePanStep

    fld DWORD PTR centerX

    fadd DWORD PTR panAmountX

    fstp DWORD PTR centerX

    invoke UpdateViewState
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    ret

PanRight ENDP


PanUp PROC STDCALL

    invoke CalculatePanStep

    fld DWORD PTR centerY

    fadd DWORD PTR panAmountY

    fstp DWORD PTR centerY

    invoke UpdateViewState
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    ret

PanUp ENDP


PanDown PROC STDCALL

    invoke CalculatePanStep

    fld DWORD PTR centerY

    fsub DWORD PTR panAmountY

    fstp DWORD PTR centerY

    invoke UpdateViewState
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    ret

PanDown ENDP


; ============================================================
; ZOOM
; ============================================================

ZoomIn PROC STDCALL

    fld DWORD PTR zoomHalfRange

    fmul DWORD PTR zoomInFactor

    fstp DWORD PTR zoomCandidate

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
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    ret

ZoomIn ENDP


ZoomOut PROC STDCALL

    fld DWORD PTR zoomHalfRange

    fmul DWORD PTR zoomOutFactor

    fstp DWORD PTR zoomCandidate

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
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    ret

ZoomOut ENDP


; ============================================================
; RESET
; ============================================================

ResetView PROC STDCALL

    fld DWORD PTR floatZero
    fstp DWORD PTR centerX

    fld DWORD PTR floatZero
    fstp DWORD PTR centerY

    fld DWORD PTR defaultHalfRange
    fstp DWORD PTR zoomHalfRange

    invoke UpdateViewState
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    ret

ResetView ENDP


; ============================================================
; KEYBOARD
; ============================================================

HandleKeyboard PROC STDCALL keyCode:DWORD

    mov eax, keyCode

    cmp eax, VK_ESCAPE
    je KeyExit

    cmp eax, VK_W
    je KeyUp

    cmp eax, VK_S
    je KeyDown

    cmp eax, VK_A
    je KeyLeft

    cmp eax, VK_D
    je KeyRight

    cmp eax, VK_R
    je KeyReset

    cmp eax, VK_OEM_PLUS
    je KeyZoomIn

    cmp eax, VK_ADD
    je KeyZoomIn

    cmp eax, VK_OEM_MINUS
    je KeyZoomOut

    cmp eax, VK_SUBTRACT
    je KeyZoomOut

    ret

KeyUp:
    invoke PanUp
    ret

KeyDown:
    invoke PanDown
    ret

KeyLeft:
    invoke PanLeft
    ret

KeyRight:
    invoke PanRight
    ret

KeyZoomIn:
    invoke ZoomIn
    ret

KeyZoomOut:
    invoke ZoomOut
    ret

KeyReset:
    invoke ResetView
    ret

KeyExit:
    invoke DestroyWindow, hMainWnd
    ret

HandleKeyboard ENDP


; ============================================================
; EDIT CONTROL
; ============================================================

ExpressionEditProc PROC STDCALL \
    hWnd:DWORD, \
    uMsg:DWORD, \
    wParam:DWORD, \
    lParam:DWORD

    cmp uMsg, WM_KEYDOWN
    jne EditCheckChar

    cmp wParam, VK_RETURN
    je EditEnter

    cmp wParam, VK_ESCAPE
    je EditEscape

    jmp EditDefault

EditCheckChar:

    cmp uMsg, WM_CHAR
    jne EditDefault

    cmp wParam, VK_RETURN
    je EditSwallow

    jmp EditDefault

EditEnter:

    invoke ApplyExpression

    xor eax, eax
    ret

EditEscape:

    invoke DestroyWindow, hMainWnd

    xor eax, eax
    ret

EditSwallow:

    xor eax, eax
    ret

EditDefault:

    invoke CallWindowProcA, \
        oldEditProc, \
        hWnd, \
        uMsg, \
        wParam, \
        lParam

    ret

ExpressionEditProc ENDP


; ============================================================
; CREATE UI
; ============================================================

CreateInterface PROC STDCALL parentWnd:DWORD

    invoke CreateWindowExA, \
        WS_EX_CLIENTEDGE, \
        ADDR editClassName, \
        ADDR expressionText, \
        WS_CHILD OR \
            WS_VISIBLE OR \
            WS_TABSTOP OR \
            ES_AUTOHSCROLL, \
        12, \
        10, \
        520, \
        26, \
        parentWnd, \
        EDIT_ID, \
        hInstance, \
        0

    test eax, eax
    jz CreateInterfaceFailed

    mov hExpressionEdit, eax

    invoke SetWindowLongA, \
        hExpressionEdit, \
        GWL_WNDPROC, \
        OFFSET ExpressionEditProc

    test eax, eax
    jz CreateInterfaceFailed

    mov oldEditProc, eax


    invoke CreateWindowExA, \
        0, \
        ADDR staticClassName, \
        ADDR statusText, \
        WS_CHILD OR WS_VISIBLE, \
        12, \
        43, \
        1060, \
        22, \
        parentWnd, \
        STATUS_ID, \
        hInstance, \
        0

    test eax, eax
    jz CreateInterfaceFailed

    mov hStatus, eax

    mov eax, 1
    ret

CreateInterfaceFailed:

    xor eax, eax
    ret

CreateInterface ENDP


; ============================================================
; OPENGL INITIALIZATION
; ============================================================

InitializeOpenGL PROC STDCALL targetWnd:DWORD

    push edi

    invoke GetDC, targetWnd

    test eax, eax
    jz OpenGLInitFailed

    mov hDC, eax


    lea edi, pfd

    xor eax, eax

    mov ecx, SIZEOF PIXELFORMATDESCRIPTOR / 4

    cld
    rep stosd


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
    jz OpenGLInitFailed

    mov pixelFormat, eax


    invoke SetPixelFormat, \
        hDC, \
        pixelFormat, \
        ADDR pfd

    test eax, eax
    jz OpenGLInitFailed


    invoke wglCreateContext, hDC

    test eax, eax
    jz OpenGLInitFailed

    mov hGLRC, eax


    invoke wglMakeCurrent, \
        hDC, \
        hGLRC

    test eax, eax
    jz OpenGLInitFailed


    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


    invoke GetClientRect, \
        targetWnd, \
        ADDR clientRect


    mov eax, clientRect.right

    sub eax, clientRect.left

    mov clientW, eax


    mov eax, clientRect.bottom

    sub eax, clientRect.top

    mov clientH, eax


    sub eax, TOP_PANEL_HEIGHT

    jle InitialGraphZero

    mov graphH, eax

    jmp InitialGraphReady

InitialGraphZero:

    mov graphH, 0

InitialGraphReady:

    invoke UpdateViewState

    invoke SetupViewport


    pop edi

    mov eax, 1
    ret

OpenGLInitFailed:

    pop edi

    xor eax, eax
    ret

InitializeOpenGL ENDP


; ============================================================
; CLEANUP
; ============================================================

CleanupOpenGL PROC STDCALL targetWnd:DWORD

    cmp hGLRC, 0
    je SkipContextCleanup

    invoke wglMakeCurrent, 0, 0

    invoke wglDeleteContext, hGLRC

    mov hGLRC, 0

SkipContextCleanup:

    cmp hDC, 0
    je CleanupDone

    invoke ReleaseDC, targetWnd, hDC

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

    cmp uMsg, WM_PAINT
    je WindowPaint

    cmp uMsg, WM_SIZE
    je WindowSize

    cmp uMsg, WM_KEYDOWN
    je WindowKeyDown

    cmp uMsg, WM_MOUSEMOVE
    je WindowMouseMove

    cmp uMsg, WM_LBUTTONDOWN
    je WindowMouseClick

    cmp uMsg, WM_ERASEBKGND
    je WindowBackground

    cmp uMsg, WM_DESTROY
    je WindowDestroyed


    invoke DefWindowProcA, \
        hWnd, \
        uMsg, \
        wParam, \
        lParam

    ret


WindowPaint:

    invoke RenderScene

    invoke ValidateRect, hWnd, 0

    xor eax, eax
    ret


WindowSize:

    mov eax, lParam

    movzx ecx, ax

    mov clientW, ecx


    mov eax, lParam

    shr eax, 16

    movzx ecx, ax

    mov clientH, ecx


    mov eax, clientH

    sub eax, TOP_PANEL_HEIGHT

    jle ResizeGraphZero

    mov graphH, eax

    jmp ResizeGraphReady

ResizeGraphZero:

    mov graphH, 0

ResizeGraphReady:

    cmp hGLRC, 0
    je WindowSizeDone

    invoke UpdateViewState
    invoke SetupViewport
    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

WindowSizeDone:

    xor eax, eax
    ret


WindowMouseMove:

    mov eax, lParam

    movzx ecx, ax

    mov mousePixelX, ecx


    mov eax, lParam

    shr eax, 16

    movzx ecx, ax

    mov mousePixelY, ecx


    mov mouseActive, 1

    invoke UpdateMouseWorld
    invoke UpdateStatusText
    invoke RenderScene

    xor eax, eax
    ret


WindowMouseClick:

    mov eax, mousePixelY

    cmp eax, TOP_PANEL_HEIGHT
    jb WindowClickDone

    invoke SetFocus, hWnd

WindowClickDone:

    xor eax, eax
    ret


WindowKeyDown:

    invoke HandleKeyboard, wParam

    xor eax, eax
    ret


WindowBackground:

    mov eax, 1
    ret


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

    finit


    mov hDC, 0
    mov hGLRC, 0
    mov hMainWnd, 0

    mov hExpressionEdit, 0
    mov hStatus, 0
    mov oldEditProc, 0

    mov clientW, 0
    mov clientH, 0
    mov graphH, 0

    mov mouseActive, 0
    mov mousePixelX, 0
    mov mousePixelY, 0


    invoke CompileExpression

    test eax, eax
    jz InitialExpressionFailed


    invoke CopyCString, \
        ADDR lastGoodExpression, \
        ADDR expressionText, \
        MAX_EXPRESSION_LENGTH


    invoke GetModuleHandleA, 0

    mov hInstance, eax


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


    invoke RegisterClassExA, \
        ADDR windowClass

    test eax, eax
    jz RegistrationFailed


    invoke CreateWindowExA, \
        0, \
        ADDR className, \
        ADDR windowTitle, \
        WS_OVERLAPPEDWINDOW OR \
            WS_CLIPCHILDREN OR \
            WS_CLIPSIBLINGS, \
        CW_USEDEFAULT, \
        CW_USEDEFAULT, \
        1100, \
        800, \
        0, \
        0, \
        hInstance, \
        0

    test eax, eax
    jz WindowCreationFailed

    mov hMainWnd, eax


    invoke CreateInterface, hMainWnd

    test eax, eax
    jz InterfaceCreationFailed


    invoke InitializeOpenGL, hMainWnd

    test eax, eax
    jz OpenGLCreationFailed


    invoke UpdateStatusText


    invoke ShowWindow, \
        hMainWnd, \
        SW_SHOWNORMAL

    invoke UpdateWindow, hMainWnd

    invoke RenderScene

    invoke SetFocus, hExpressionEdit


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


ProgramFinished:

    mov eax, messageData.wParam

    invoke ExitProcess, eax


InitialExpressionFailed:

    invoke ExitProcess, 5


RegistrationFailed:

    invoke ExitProcess, 1


WindowCreationFailed:

    invoke ExitProcess, 2


InterfaceCreationFailed:

    invoke ExitProcess, 6


OpenGLCreationFailed:

    invoke CleanupOpenGL, hMainWnd

    invoke ExitProcess, 3


MessageLoopFailed:

    invoke CleanupOpenGL, hMainWnd

    invoke ExitProcess, 4


END start