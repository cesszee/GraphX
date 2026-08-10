; ============================================================
; GraphX - Step 15
; 32-bit MASM + Win32 + OpenGL
;
; Expression engine supports:
;
;   x / X
;   integer constants
;   decimal constants
;   +  -  *  /
;   parentheses
;   unary minus
;   unary plus
;
; Examples:
;
;   x
;   2*x+3
;   x*x
;   (x+2)*(x-2)
;   0.5*x+1
;   -x
;   -(x*x)+4
;   -0.25*x*x+4
;
; Controls:
;
;   Expression box + ENTER = compile/graph expression
;
;   W A S D = pan
;   + / -   = zoom
;   R       = reset
;   ESC     = exit
;
; ============================================================

.686
.model flat, stdcall
option casemap:none


; ============================================================
; FORWARD DECLARATIONS
; ============================================================

RenderScene PROTO STDCALL
ApplyExpression PROTO STDCALL

ExpressionEditProc PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD


; ============================================================
; WIN32 API
; ============================================================

GetModuleHandleA PROTO STDCALL :DWORD
ExitProcess      PROTO STDCALL :DWORD

LoadCursorA PROTO STDCALL \
    :DWORD, :DWORD

RegisterClassExA PROTO STDCALL \
    :DWORD

CreateWindowExA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD

DestroyWindow PROTO STDCALL \
    :DWORD

ShowWindow PROTO STDCALL \
    :DWORD, :DWORD

UpdateWindow PROTO STDCALL \
    :DWORD

GetMessageA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

TranslateMessage PROTO STDCALL \
    :DWORD

DispatchMessageA PROTO STDCALL \
    :DWORD

DefWindowProcA PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

PostQuitMessage PROTO STDCALL \
    :DWORD

ValidateRect PROTO STDCALL \
    :DWORD, :DWORD

GetClientRect PROTO STDCALL \
    :DWORD, :DWORD

GetDC PROTO STDCALL \
    :DWORD

ReleaseDC PROTO STDCALL \
    :DWORD, :DWORD

ChoosePixelFormat PROTO STDCALL \
    :DWORD, :DWORD

SetPixelFormat PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

SwapBuffers PROTO STDCALL \
    :DWORD

SetFocus PROTO STDCALL \
    :DWORD

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

wglCreateContext PROTO STDCALL \
    :DWORD

wglMakeCurrent PROTO STDCALL \
    :DWORD, :DWORD

wglDeleteContext PROTO STDCALL \
    :DWORD


; ============================================================
; OPENGL
; ============================================================

glClearColor PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

glClear PROTO STDCALL \
    :DWORD

glViewport PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

glMatrixMode PROTO STDCALL \
    :DWORD

glLoadIdentity PROTO STDCALL

glScalef PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

glTranslatef PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

glColor3f PROTO STDCALL \
    :DWORD, :DWORD, :DWORD

glBegin PROTO STDCALL \
    :DWORD

glEnd PROTO STDCALL

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

WS_CLIPCHILDREN EQU 02000000h
WS_CLIPSIBLINGS EQU 04000000h

WS_CHILD   EQU 40000000h
WS_VISIBLE EQU 10000000h
WS_TABSTOP EQU 00010000h

WS_EX_CLIENTEDGE EQU 00000200h

ES_AUTOHSCROLL EQU 0080h

CW_USEDEFAULT EQU 80000000h

SW_SHOWNORMAL EQU 1

IDC_ARROW EQU 32512

GWL_WNDPROC EQU 0FFFFFFFCh


; ============================================================
; MESSAGE BOX
; ============================================================

MB_OK        EQU 00000000h
MB_ICONERROR EQU 00000010h


; ============================================================
; KEYBOARD
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
; OPENGL CONSTANTS
; ============================================================

GL_COLOR_BUFFER_BIT EQU 00004000h

GL_LINES      EQU 0001h
GL_LINE_STRIP EQU 0003h

GL_MODELVIEW  EQU 1700h
GL_PROJECTION EQU 1701h


; ============================================================
; GRAPH CONSTANTS
; ============================================================

GRAPH_INTERVALS    EQU 1000
GRAPH_SAMPLE_COUNT EQU 1001

GRID_MIN EQU -200
GRID_MAX EQU  200


; ============================================================
; EXPRESSION ENGINE
; ============================================================

MAX_EXPRESSION_LENGTH EQU 256

MAX_RPN_TOKENS     EQU 128
MAX_OPERATOR_STACK EQU 64
MAX_EVAL_STACK     EQU 128


TOKEN_CONST EQU 1
TOKEN_X     EQU 2

TOKEN_ADD EQU 3
TOKEN_SUB EQU 4
TOKEN_MUL EQU 5
TOKEN_DIV EQU 6

TOKEN_NEG EQU 7


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

editClassName db "EDIT",0

windowTitle db \
    "GraphX - Parentheses / Decimals / Unary Negative",0


; ============================================================
; DEFAULT EXPRESSION
; ============================================================

expressionText db "x*x",0,252 DUP(0)

lastGoodExpression db MAX_EXPRESSION_LENGTH DUP(0)


; ============================================================
; ERROR
; ============================================================

errorTitle db "GraphX Expression Error",0

errorMessage db \
    "Invalid mathematical expression.",13,10,13,10, \
    "Supported:",13,10, \
    "x, decimal numbers, +, -, *, /, parentheses",13,10,13,10, \
    "Examples:",13,10, \
    "(x+2)*(x-2)",13,10, \
    "0.5*x+1",13,10, \
    "-(x*x)+4",0


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
; FLOAT / INTEGER CONSTANTS
; ============================================================

floatZero REAL4 0.0
floatOne  REAL4 1.0

floatPointOne REAL4 0.1

integerTen DWORD 10


; ============================================================
; CAMERA
; ============================================================

defaultHalfRange REAL4 10.0

centerX REAL4 0.0
centerY REAL4 0.0

zoomHalfRange REAL4 10.0


; ============================================================
; ZOOM
; ============================================================

zoomInFactor  REAL4 0.80
zoomOutFactor REAL4 1.25

minHalfRange REAL4 0.50
maxHalfRange REAL4 50.0

zoomCandidate REAL4 0.0


; ============================================================
; PAN
; ============================================================

panFraction REAL4 0.10

panAmountX REAL4 0.0
panAmountY REAL4 0.0


; ============================================================
; MATHEMATICAL VIEW
; ============================================================

viewHalfX REAL4 10.0
viewHalfY REAL4 10.0

viewLeft   REAL4 -10.0
viewRight  REAL4  10.0
viewBottom REAL4 -10.0
viewTop    REAL4  10.0


; ============================================================
; OPENGL CAMERA
; ============================================================

viewScaleX REAL4 0.1
viewScaleY REAL4 0.1
viewScaleZ REAL4 1.0

viewTranslateX REAL4 0.0
viewTranslateY REAL4 0.0


; ============================================================
; GRAPH
; ============================================================

graphIntervalCount DWORD GRAPH_INTERVALS


; ============================================================
; PARSER STATE
; ============================================================

rpnCount DWORD 0

operatorTop DWORD 0

parserExpectOperand DWORD 1


; Decimal parser

parserNumber REAL4 0.0

parserFractionScale REAL4 0.1

parserDigitInt DWORD 0

parserDigitSeen DWORD 0

parserDecimalSeen DWORD 0


; Evaluator

evalStackTop DWORD 0

evalOperandB REAL4 0.0


; ============================================================
; UNINITIALIZED DATA
; ============================================================

.data?


; ============================================================
; WINDOWS / OPENGL
; ============================================================

hInstance DWORD ?
hMainWnd DWORD ?

hExpressionEdit DWORD ?
oldEditProc DWORD ?

hDC DWORD ?
hGLRC DWORD ?

pixelFormat DWORD ?


clientW DWORD ?
clientH DWORD ?


; ============================================================
; GRAPH
; ============================================================

currentX REAL4 ?
currentY REAL4 ?

graphStepX REAL4 ?


; ============================================================
; GRID
; ============================================================

gridIndex DWORD ?
gridCoord REAL4 ?


; ============================================================
; MOUSE
; ============================================================

mousePixelX DWORD ?
mousePixelY DWORD ?

mouseWorldX REAL4 ?
mouseWorldY REAL4 ?

mouseRangeX REAL4 ?
mouseRangeY REAL4 ?

mouseOffsetY REAL4 ?

mouseActive DWORD ?


; ============================================================
; EXPRESSION ENGINE ARRAYS
; ============================================================

rpnTypes BYTE MAX_RPN_TOKENS DUP(?)

rpnValues REAL4 MAX_RPN_TOKENS DUP(?)

operatorStack BYTE MAX_OPERATOR_STACK DUP(?)

evalStack REAL4 MAX_EVAL_STACK DUP(?)

currentOperator BYTE ?


; ============================================================
; WINDOWS STRUCTURES
; ============================================================

windowClass WNDCLASSEX <>
messageData MSG <>
clientRect RECT <>

pfd PIXELFORMATDESCRIPTOR <>


; ============================================================
; CODE
; ============================================================

.code


; ============================================================
; COPY STRING
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
; OPERATOR PRECEDENCE
;
; + - = 1
; * / = 2
; unary NEG = 3
; ============================================================

GetOperatorPrecedence PROC STDCALL opChar:DWORD


    mov eax, opChar


    cmp al, '+'
    je Precedence1


    cmp al, '-'
    je Precedence1


    cmp al, '*'
    je Precedence2


    cmp al, '/'
    je Precedence2


    cmp al, '~'
    je Precedence3


    xor eax, eax

    ret


Precedence1:


    mov eax, 1

    ret


Precedence2:


    mov eax, 2

    ret


Precedence3:


    mov eax, 3

    ret


GetOperatorPrecedence ENDP


; ============================================================
; EMIT OPERATOR INTO RPN
; ============================================================

EmitOperatorToken PROC STDCALL opChar:DWORD


    mov ecx, rpnCount


    cmp ecx, MAX_RPN_TOKENS
    jae EmitOperatorFailed


    mov eax, opChar


    cmp al, '+'
    je EmitAdd


    cmp al, '-'
    je EmitSub


    cmp al, '*'
    je EmitMul


    cmp al, '/'
    je EmitDiv


    cmp al, '~'
    je EmitNeg


    jmp EmitOperatorFailed


EmitAdd:


    mov BYTE PTR [rpnTypes + ecx], TOKEN_ADD

    jmp EmitOperatorSuccess


EmitSub:


    mov BYTE PTR [rpnTypes + ecx], TOKEN_SUB

    jmp EmitOperatorSuccess


EmitMul:


    mov BYTE PTR [rpnTypes + ecx], TOKEN_MUL

    jmp EmitOperatorSuccess


EmitDiv:


    mov BYTE PTR [rpnTypes + ecx], TOKEN_DIV

    jmp EmitOperatorSuccess


EmitNeg:


    mov BYTE PTR [rpnTypes + ecx], TOKEN_NEG


EmitOperatorSuccess:


    inc ecx


    mov rpnCount, ecx


    mov eax, 1

    ret


EmitOperatorFailed:


    xor eax, eax

    ret


EmitOperatorToken ENDP


; ============================================================
; COMPILE INFIX EXPRESSION TO RPN
;
; Supports:
;
; decimals
; parentheses
; unary -
; unary +
; + - * /
; x
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


    mov esi, OFFSET expressionText


; ============================================================
; MAIN PARSER LOOP
; ============================================================

ParseLoop:


    mov al, BYTE PTR [esi]


    cmp al, 0
    je ParseEnd


    ; Ignore spaces.

    cmp al, ' '
    je ParseAdvance


    ; Ignore tab.

    cmp al, 9
    je ParseAdvance


    ; Variable.

    cmp al, 'x'
    je ParseVariable


    cmp al, 'X'
    je ParseVariable


    ; Left parenthesis.

    cmp al, '('
    je ParseLeftParenthesis


    ; Right parenthesis.

    cmp al, ')'
    je ParseRightParenthesis


    ; Number can begin with digit.

    cmp al, '0'
    jb ParseCheckDecimalStart


    cmp al, '9'
    jbe ParseNumber


ParseCheckDecimalStart:


    ; Allow .5

    cmp al, '.'
    je ParseNumber


; ============================================================
; OPERATORS
; ============================================================

    cmp al, '+'
    je ParsePlus


    cmp al, '-'
    je ParseMinus


    cmp al, '*'
    je ParseBinaryOperator


    cmp al, '/'
    je ParseBinaryOperator


    jmp ParseFailed


; ============================================================
; WHITESPACE
; ============================================================

ParseAdvance:


    inc esi

    jmp ParseLoop


; ============================================================
; VARIABLE X
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
; LEFT PARENTHESIS
; ============================================================

ParseLeftParenthesis:


    ; Cannot have:
    ;
    ; x(
    ; 2(
    ;
    ; without an operator.

    cmp parserExpectOperand, 1
    jne ParseFailed


    mov ecx, operatorTop


    cmp ecx, MAX_OPERATOR_STACK
    jae ParseFailed


    mov BYTE PTR [operatorStack + ecx], '('


    inc ecx


    mov operatorTop, ecx


    inc esi


    jmp ParseLoop


; ============================================================
; RIGHT PARENTHESIS
; ============================================================

ParseRightParenthesis:


    ; () is invalid.

    cmp parserExpectOperand, 0
    jne ParseFailed


RightParenthesisPop:


    mov ecx, operatorTop


    test ecx, ecx
    jz ParseFailed


    dec ecx


    mov al, BYTE PTR [operatorStack + ecx]


    cmp al, '('
    je RightParenthesisFound


    mov operatorTop, ecx


    movzx eax, al


    invoke EmitOperatorToken, eax


    test eax, eax
    jz ParseFailed


    jmp RightParenthesisPop


RightParenthesisFound:


    ; Remove '('.

    mov operatorTop, ecx


    inc esi


; ------------------------------------------------------------
; If a unary minus was before the parenthesized expression:
;
;     -(x+2)
;
; emit NEG after the parenthesized result.
; ------------------------------------------------------------

RightParenthesisUnaryLoop:


    mov ecx, operatorTop


    test ecx, ecx
    jz RightParenthesisDone


    dec ecx


    mov al, BYTE PTR [operatorStack + ecx]


    cmp al, '~'
    jne RightParenthesisDone


    mov operatorTop, ecx


    movzx eax, al


    invoke EmitOperatorToken, eax


    test eax, eax
    jz ParseFailed


    jmp RightParenthesisUnaryLoop


RightParenthesisDone:


    mov parserExpectOperand, 0


    jmp ParseLoop


; ============================================================
; NUMBER
;
; Examples:
;
;   2
;   12
;   0.5
;   12.75
;   .5
;
; Number is constructed directly with x87.
; ============================================================

ParseNumber:


    cmp parserExpectOperand, 1
    jne ParseFailed


    ; parserNumber = 0

    fld DWORD PTR floatZero

    fstp DWORD PTR parserNumber


    ; fraction scale = 0.1

    fld DWORD PTR floatPointOne

    fstp DWORD PTR parserFractionScale


    mov parserDigitSeen, 0

    mov parserDecimalSeen, 0


NumberLoop:


    mov al, BYTE PTR [esi]


    ; Digit?

    cmp al, '0'
    jb NumberCheckDecimal


    cmp al, '9'
    ja NumberCheckDecimal


    ; Convert ASCII digit -> integer.

    movzx eax, al


    sub eax, '0'


    mov parserDigitInt, eax


    mov parserDigitSeen, 1


    cmp parserDecimalSeen, 0
    jne NumberFractionDigit


; ------------------------------------------------------------
; INTEGER PART
;
; number = number * 10 + digit
; ------------------------------------------------------------

    fld DWORD PTR parserNumber


    fimul DWORD PTR integerTen


    fiadd DWORD PTR parserDigitInt


    fstp DWORD PTR parserNumber


    inc esi


    jmp NumberLoop


; ------------------------------------------------------------
; FRACTIONAL PART
;
; number =
; number + digit * fractionScale
; ------------------------------------------------------------

NumberFractionDigit:


    fild DWORD PTR parserDigitInt


    fmul DWORD PTR parserFractionScale


    fadd DWORD PTR parserNumber


    fstp DWORD PTR parserNumber


    ; fractionScale *= 0.1

    fld DWORD PTR parserFractionScale


    fmul DWORD PTR floatPointOne


    fstp DWORD PTR parserFractionScale


    inc esi


    jmp NumberLoop


; ------------------------------------------------------------
; DECIMAL POINT
; ------------------------------------------------------------

NumberCheckDecimal:


    cmp al, '.'
    jne NumberFinished


    ; Only one decimal point.

    cmp parserDecimalSeen, 0
    jne NumberFinished


    mov parserDecimalSeen, 1


    inc esi


    jmp NumberLoop


NumberFinished:


    ; "." alone is invalid.

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


    ; ESI already points to next character.

    jmp ParseLoop


; ============================================================
; PLUS
;
; Unary:
;
;     +x
;
; Binary:
;
;     x+2
; ============================================================

ParsePlus:


    cmp parserExpectOperand, 1
    je ParseUnaryPlus


    jmp ParseBinaryOperator


ParseUnaryPlus:


    ; Unary plus changes nothing.

    inc esi


    jmp ParseLoop


; ============================================================
; MINUS
;
; Unary:
;
;     -x
;
; represented internally as '~'
;
; Binary:
;
;     x-2
; ============================================================

ParseMinus:


    cmp parserExpectOperand, 1
    je ParseUnaryMinus


    jmp ParseBinaryOperator


ParseUnaryMinus:


    mov ecx, operatorTop


    cmp ecx, MAX_OPERATOR_STACK
    jae ParseFailed


    mov BYTE PTR [operatorStack + ecx], '~'


    inc ecx


    mov operatorTop, ecx


    inc esi


    ; Still expecting an operand.

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


; ============================================================
; SHUNTING-YARD OPERATOR POP
; ============================================================

BinaryPopLoop:


    mov ecx, operatorTop


    test ecx, ecx
    jz BinaryPushIncoming


    dec ecx


    mov al, BYTE PTR [operatorStack + ecx]


    ; Never pop through left parenthesis.

    cmp al, '('
    je BinaryPushIncoming


    movzx eax, al


    invoke GetOperatorPrecedence, eax


    ; Existing precedence < incoming precedence:
    ; stop.

    cmp eax, ebx
    jb BinaryPushIncoming


    ; Pop existing operator.

    mov ecx, operatorTop


    dec ecx


    movzx eax, BYTE PTR [operatorStack + ecx]


    mov operatorTop, ecx


    invoke EmitOperatorToken, eax


    test eax, eax
    jz ParseFailed


    jmp BinaryPopLoop


; ============================================================
; PUSH BINARY OPERATOR
; ============================================================

BinaryPushIncoming:


    mov ecx, operatorTop


    cmp ecx, MAX_OPERATOR_STACK
    jae ParseFailed


    mov al, currentOperator


    mov BYTE PTR [operatorStack + ecx], al


    inc ecx


    mov operatorTop, ecx


    mov parserExpectOperand, 1


    inc esi


    jmp ParseLoop


; ============================================================
; END
; ============================================================

ParseEnd:


    ; Cannot end with:
    ;
    ; x+
    ; x*
    ; (
    ; -
    ;

    cmp parserExpectOperand, 0
    jne ParseFailed


    cmp rpnCount, 0
    je ParseFailed


; ============================================================
; FLUSH OPERATOR STACK
; ============================================================

FlushOperatorStack:


    mov ecx, operatorTop


    test ecx, ecx
    jz CompileSuccess


    dec ecx


    mov al, BYTE PTR [operatorStack + ecx]


    ; Unmatched parenthesis.

    cmp al, '('
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
; RPN EVALUATOR
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


    cmp eax, TOKEN_ADD
    je EvaluateBinary


    cmp eax, TOKEN_SUB
    je EvaluateBinary


    cmp eax, TOKEN_MUL
    je EvaluateBinary


    cmp eax, TOKEN_DIV
    je EvaluateBinary


    jmp EvaluationFailed


; ============================================================
; CONSTANT
; ============================================================

EvaluateConstant:


    mov ecx, evalStackTop


    cmp ecx, MAX_EVAL_STACK
    jae EvaluationFailed


    mov edx, DWORD PTR [rpnValues + esi*4]


    mov DWORD PTR [evalStack + ecx*4], edx


    inc ecx


    mov evalStackTop, ecx


    jmp EvaluationNext


; ============================================================
; VARIABLE X
; ============================================================

EvaluateVariable:


    mov ecx, evalStackTop


    cmp ecx, MAX_EVAL_STACK
    jae EvaluationFailed


    mov edx, DWORD PTR currentX


    mov DWORD PTR [evalStack + ecx*4], edx


    inc ecx


    mov evalStackTop, ecx


    jmp EvaluationNext


; ============================================================
; UNARY NEGATION
;
; Stack:
;
;     A
;
; becomes:
;
;     -A
; ============================================================

EvaluateNeg:


    mov ecx, evalStackTop


    cmp ecx, 1
    jb EvaluationFailed


    dec ecx


    fld DWORD PTR [evalStack + ecx*4]


    fchs


    fstp DWORD PTR [evalStack + ecx*4]


    jmp EvaluationNext


; ============================================================
; BINARY OPERATOR
;
; Stack:
;
;     ... A B
;
; becomes:
;
;     ... result
; ============================================================

EvaluateBinary:


    mov ebx, eax


    mov ecx, evalStackTop


    cmp ecx, 2
    jb EvaluationFailed


    sub ecx, 2


    ; A

    fld DWORD PTR [evalStack + ecx*4]


    ; B

    mov edx, DWORD PTR [evalStack + ecx*4 + 4]


    mov DWORD PTR evalOperandB, edx


    cmp ebx, TOKEN_ADD
    je ExecuteAdd


    cmp ebx, TOKEN_SUB
    je ExecuteSub


    cmp ebx, TOKEN_MUL
    je ExecuteMul


    cmp ebx, TOKEN_DIV
    je ExecuteDiv


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


EvaluationNext:


    inc esi


    jmp EvaluationLoop


EvaluationFinished:


    cmp evalStackTop, 1
    jne EvaluationFailed


    mov eax, DWORD PTR [evalStack]


    mov DWORD PTR currentY, eax


    mov eax, 1


    jmp EvaluationExit


EvaluationFailed:


    fld DWORD PTR floatZero


    fstp DWORD PTR currentY


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
; APPLY EXPRESSION FROM EDIT CONTROL
; ============================================================

ApplyExpression PROC STDCALL


    invoke GetWindowTextA, \
        hExpressionEdit, \
        ADDR expressionText, \
        MAX_EXPRESSION_LENGTH


    invoke CompileExpression


    test eax, eax
    jz ApplyExpressionFailed


; ============================================================
; SUCCESS
; ============================================================

    invoke CopyCString, \
        ADDR lastGoodExpression, \
        ADDR expressionText, \
        MAX_EXPRESSION_LENGTH


    invoke SetFocus, hMainWnd


    invoke RenderScene


    mov eax, 1


    ret


; ============================================================
; INVALID EXPRESSION
; ============================================================

ApplyExpressionFailed:


    ; Restore last valid expression.

    invoke CopyCString, \
        ADDR expressionText, \
        ADDR lastGoodExpression, \
        MAX_EXPRESSION_LENGTH


    invoke SetWindowTextA, \
        hExpressionEdit, \
        ADDR expressionText


    ; Restore the previous valid RPN program.

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
; UPDATE CAMERA / VIEW
; ============================================================

UpdateViewState PROC STDCALL


    cmp clientW, 0
    je UpdateViewDone


    cmp clientH, 0
    je UpdateViewDone


    mov eax, clientW


    cmp eax, clientH
    jae ViewWide


; ============================================================
; TALL WINDOW
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
; WIDE WINDOW
; ============================================================

ViewWide:


    fld DWORD PTR zoomHalfRange


    fstp DWORD PTR viewHalfY


    fld DWORD PTR zoomHalfRange


    fimul DWORD PTR clientW


    fidiv DWORD PTR clientH


    fstp DWORD PTR viewHalfX


CalculateViewBounds:


    ; Left

    fld DWORD PTR centerX

    fsub DWORD PTR viewHalfX

    fstp DWORD PTR viewLeft


    ; Right

    fld DWORD PTR centerX

    fadd DWORD PTR viewHalfX

    fstp DWORD PTR viewRight


    ; Bottom

    fld DWORD PTR centerY

    fsub DWORD PTR viewHalfY

    fstp DWORD PTR viewBottom


    ; Top

    fld DWORD PTR centerY

    fadd DWORD PTR viewHalfY

    fstp DWORD PTR viewTop


    ; Scale X

    fld DWORD PTR floatOne

    fdiv DWORD PTR viewHalfX

    fstp DWORD PTR viewScaleX


    ; Scale Y

    fld DWORD PTR floatOne

    fdiv DWORD PTR viewHalfY

    fstp DWORD PTR viewScaleY


    ; Translation X

    fld DWORD PTR centerX

    fchs

    fstp DWORD PTR viewTranslateX


    ; Translation Y

    fld DWORD PTR centerY

    fchs

    fstp DWORD PTR viewTranslateY


UpdateViewDone:


    ret


UpdateViewState ENDP


; ============================================================
; OPENGL VIEWPORT
; ============================================================

SetupViewport PROC STDCALL


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
; GRID
; ============================================================

DrawGrid PROC STDCALL


    invoke glColor3f, \
        DWORD PTR gridRed, \
        DWORD PTR gridGreen, \
        DWORD PTR gridBlue


    invoke glBegin, GL_LINES


    mov gridIndex, GRID_MIN


GridLoop:


    cmp gridIndex, 0
    je GridNext


    fild DWORD PTR gridIndex


    fstp DWORD PTR gridCoord


    ; Vertical

    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewBottom


    invoke glVertex2f, \
        DWORD PTR gridCoord, \
        DWORD PTR viewTop


    ; Horizontal

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
; AXES
; ============================================================

DrawAxes PROC STDCALL


    invoke glColor3f, \
        DWORD PTR axisRed, \
        DWORD PTR axisGreen, \
        DWORD PTR axisBlue


    invoke glBegin, GL_LINES


    ; X

    invoke glVertex2f, \
        DWORD PTR viewLeft, \
        DWORD PTR floatZero


    invoke glVertex2f, \
        DWORD PTR viewRight, \
        DWORD PTR floatZero


    ; Y

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


    invoke glBegin, GL_LINE_STRIP


GraphLoop:


    invoke EvaluateCurrentFunction


    invoke glVertex2f, \
        DWORD PTR currentX, \
        DWORD PTR currentY


    fld DWORD PTR currentX


    fadd DWORD PTR graphStepX


    fstp DWORD PTR currentX


    dec edi


    jnz GraphLoop


    invoke glEnd


    pop edi


    ret


DrawFunction ENDP


; ============================================================
; MOUSE -> MATHEMATICAL COORDINATE
; ============================================================

UpdateMouseWorld PROC STDCALL


    cmp clientW, 0
    je UpdateMouseDone


    cmp clientH, 0
    je UpdateMouseDone


    ; X range

    fld DWORD PTR viewRight


    fsub DWORD PTR viewLeft


    fstp DWORD PTR mouseRangeX


    ; X coordinate

    fild DWORD PTR mousePixelX


    fidiv DWORD PTR clientW


    fmul DWORD PTR mouseRangeX


    fadd DWORD PTR viewLeft


    fstp DWORD PTR mouseWorldX


    ; Y range

    fld DWORD PTR viewTop


    fsub DWORD PTR viewBottom


    fstp DWORD PTR mouseRangeY


    ; Y offset

    fild DWORD PTR mousePixelY


    fidiv DWORD PTR clientH


    fmul DWORD PTR mouseRangeY


    fstp DWORD PTR mouseOffsetY


    ; Mathematical Y

    fld DWORD PTR viewTop


    fsub DWORD PTR mouseOffsetY


    fstp DWORD PTR mouseWorldY


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


    ; Vertical

    invoke glVertex2f, \
        DWORD PTR mouseWorldX, \
        DWORD PTR viewBottom


    invoke glVertex2f, \
        DWORD PTR mouseWorldX, \
        DWORD PTR viewTop


    ; Horizontal

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
; RENDER SCENE
; ============================================================

RenderScene PROC STDCALL


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


    invoke DrawCrosshair


    invoke SwapBuffers, hDC


RenderDone:


    ret


RenderScene ENDP


; ============================================================
; PAN STEP
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


; ============================================================
; PAN LEFT
; ============================================================

PanLeft PROC STDCALL


    invoke CalculatePanStep


    fld DWORD PTR centerX


    fsub DWORD PTR panAmountX


    fstp DWORD PTR centerX


    invoke UpdateViewState

    invoke UpdateMouseWorld

    invoke RenderScene


    ret


PanLeft ENDP


; ============================================================
; PAN RIGHT
; ============================================================

PanRight PROC STDCALL


    invoke CalculatePanStep


    fld DWORD PTR centerX


    fadd DWORD PTR panAmountX


    fstp DWORD PTR centerX


    invoke UpdateViewState

    invoke UpdateMouseWorld

    invoke RenderScene


    ret


PanRight ENDP


; ============================================================
; PAN UP
; ============================================================

PanUp PROC STDCALL


    invoke CalculatePanStep


    fld DWORD PTR centerY


    fadd DWORD PTR panAmountY


    fstp DWORD PTR centerY


    invoke UpdateViewState

    invoke UpdateMouseWorld

    invoke RenderScene


    ret


PanUp ENDP


; ============================================================
; PAN DOWN
; ============================================================

PanDown PROC STDCALL


    invoke CalculatePanStep


    fld DWORD PTR centerY


    fsub DWORD PTR panAmountY


    fstp DWORD PTR centerY


    invoke UpdateViewState

    invoke UpdateMouseWorld

    invoke RenderScene


    ret


PanDown ENDP


; ============================================================
; ZOOM IN
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

    invoke RenderScene


    ret


ZoomIn ENDP


; ============================================================
; ZOOM OUT
; ============================================================

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
; EDIT CONTROL SUBCLASS
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
; CREATE EXPRESSION EDIT BOX
; ============================================================

CreateExpressionInput PROC STDCALL parentWnd:DWORD


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
        500, \
        28, \
        parentWnd, \
        1001, \
        hInstance, \
        0


    test eax, eax
    jz CreateInputFailed


    mov hExpressionEdit, eax


    invoke SetWindowLongA, \
        hExpressionEdit, \
        GWL_WNDPROC, \
        OFFSET ExpressionEditProc


    test eax, eax
    jz CreateInputFailed


    mov oldEditProc, eax


    mov eax, 1

    ret


CreateInputFailed:


    xor eax, eax

    ret


CreateExpressionInput ENDP


; ============================================================
; OPENGL INITIALIZATION
; ============================================================

InitializeOpenGL PROC STDCALL targetWnd:DWORD


    invoke GetDC, targetWnd


    test eax, eax
    jz OpenGLInitFailed


    mov hDC, eax


; ============================================================
; PIXEL FORMAT
; ============================================================

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


; ============================================================
; WGL CONTEXT
; ============================================================

    invoke wglCreateContext, hDC


    test eax, eax
    jz OpenGLInitFailed


    mov hGLRC, eax


    invoke wglMakeCurrent, \
        hDC, \
        hGLRC


    test eax, eax
    jz OpenGLInitFailed


; ============================================================
; BACKGROUND
; ============================================================

    invoke glClearColor, \
        DWORD PTR clearRed, \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue, \
        DWORD PTR clearAlpha


; ============================================================
; CLIENT SIZE
; ============================================================

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


OpenGLInitFailed:


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


    invoke ReleaseDC, \
        targetWnd, \
        hDC


    mov hDC, 0


CleanupDone:


    ret


CleanupOpenGL ENDP


; ============================================================
; MAIN WINDOW PROCEDURE
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


    mov eax, lParam


    movzx ecx, ax


    mov clientW, ecx


    mov eax, lParam


    shr eax, 16


    movzx ecx, ax


    mov clientH, ecx


    cmp hGLRC, 0
    je WindowSizeDone


    invoke UpdateViewState


    invoke SetupViewport


    invoke UpdateMouseWorld


    invoke RenderScene


WindowSizeDone:


    xor eax, eax

    ret


; ============================================================
; MOUSE MOVE
; ============================================================

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


    invoke RenderScene


    xor eax, eax

    ret


; ============================================================
; GRAPH CLICK
; ============================================================

WindowMouseClick:


    invoke SetFocus, hWnd


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
; ERASE BACKGROUND
; ============================================================

WindowBackground:


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
; PROGRAM ENTRY
; ============================================================

start:


    ; Initialize x87.

    finit


    ; Handles.

    mov hDC, 0

    mov hGLRC, 0

    mov hMainWnd, 0

    mov hExpressionEdit, 0

    mov oldEditProc, 0


    mov clientW, 0

    mov clientH, 0


    mov mouseActive, 0

    mov mousePixelX, 0

    mov mousePixelY, 0


; ============================================================
; COMPILE INITIAL EXPRESSION
; ============================================================

    invoke CompileExpression


    test eax, eax
    jz InitialExpressionFailed


    invoke CopyCString, \
        ADDR lastGoodExpression, \
        ADDR expressionText, \
        MAX_EXPRESSION_LENGTH


; ============================================================
; MODULE HANDLE
; ============================================================

    invoke GetModuleHandleA, 0


    mov hInstance, eax


; ============================================================
; WINDOW CLASS
; ============================================================

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


; ============================================================
; REGISTER CLASS
; ============================================================

    invoke RegisterClassExA, \
        ADDR windowClass


    test eax, eax
    jz RegistrationFailed


; ============================================================
; CREATE WINDOW
; ============================================================

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


; ============================================================
; CREATE EXPRESSION BOX
; ============================================================

    invoke CreateExpressionInput, hMainWnd


    test eax, eax
    jz ExpressionInputFailed


; ============================================================
; OPENGL
; ============================================================

    invoke InitializeOpenGL, hMainWnd


    test eax, eax
    jz OpenGLCreationFailed


; ============================================================
; SHOW
; ============================================================

    invoke ShowWindow, \
        hMainWnd, \
        SW_SHOWNORMAL


    invoke UpdateWindow, hMainWnd


    invoke RenderScene


    invoke SetFocus, hExpressionEdit


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
; EXIT
; ============================================================

ProgramFinished:


    mov eax, messageData.wParam


    invoke ExitProcess, eax


; ============================================================
; ERRORS
; ============================================================

InitialExpressionFailed:


    invoke ExitProcess, 5


RegistrationFailed:


    invoke ExitProcess, 1


WindowCreationFailed:


    invoke ExitProcess, 2


ExpressionInputFailed:


    invoke ExitProcess, 6


OpenGLCreationFailed:


    invoke CleanupOpenGL, hMainWnd


    invoke ExitProcess, 3


MessageLoopFailed:


    invoke CleanupOpenGL, hMainWnd


    invoke ExitProcess, 4


END start