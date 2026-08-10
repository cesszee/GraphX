; ============================================================
; GraphX - Step 5
; 32-bit MASM + Win32 + OpenGL
;
; Goal:
;   Create a Win32 window
;   Create an OpenGL rendering context
;   Clear the screen with OpenGL
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

CreateWindowExA  PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD, \
    :DWORD, :DWORD, :DWORD, :DWORD

ShowWindow       PROTO STDCALL :DWORD, :DWORD
UpdateWindow     PROTO STDCALL :DWORD

GetMessageA      PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

TranslateMessage PROTO STDCALL :DWORD
DispatchMessageA PROTO STDCALL :DWORD

DefWindowProcA   PROTO STDCALL \
    :DWORD, :DWORD, :DWORD, :DWORD

PostQuitMessage  PROTO STDCALL :DWORD
ValidateRect     PROTO STDCALL :DWORD, :DWORD

GetDC            PROTO STDCALL :DWORD
ReleaseDC        PROTO STDCALL :DWORD, :DWORD

ChoosePixelFormat PROTO STDCALL :DWORD, :DWORD
SetPixelFormat    PROTO STDCALL :DWORD, :DWORD, :DWORD
SwapBuffers       PROTO STDCALL :DWORD


; ============================================================
; WGL API
; ============================================================

wglCreateContext PROTO STDCALL :DWORD
wglMakeCurrent   PROTO STDCALL :DWORD, :DWORD
wglDeleteContext PROTO STDCALL :DWORD


; ============================================================
; OpenGL 1.x API
;
; DWORD is used for the floating-point parameters here because
; each GLfloat occupies 32 bits in the 32-bit calling ABI.
; ============================================================

glClearColor PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD
glClear      PROTO STDCALL :DWORD


; ============================================================
; Win32 constants
; ============================================================

CS_VREDRAW          EQU 0001h
CS_HREDRAW          EQU 0002h
CS_OWNDC            EQU 0020h

WM_DESTROY          EQU 0002h
WM_PAINT            EQU 000Fh
WM_ERASEBKGND       EQU 0014h
WM_SIZE             EQU 0005h

WS_OVERLAPPEDWINDOW EQU 00CF0000h
WS_CLIPCHILDREN     EQU 02000000h
WS_CLIPSIBLINGS     EQU 04000000h

CW_USEDEFAULT       EQU 80000000h

SW_SHOWNORMAL       EQU 1

IDC_ARROW           EQU 32512


; ============================================================
; Pixel format constants
; ============================================================

PFD_DOUBLEBUFFER    EQU 00000001h
PFD_DRAW_TO_WINDOW  EQU 00000004h
PFD_SUPPORT_OPENGL  EQU 00000020h

PFD_TYPE_RGBA       EQU 0
PFD_MAIN_PLANE      EQU 0


; ============================================================
; OpenGL constants
; ============================================================

GL_COLOR_BUFFER_BIT EQU 00004000h


; ============================================================
; WNDCLASSEXA
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


; ============================================================
; MSG
; ============================================================

MSG STRUCT 4

    hwnd            DWORD ?
    message         DWORD ?
    wParam          DWORD ?
    lParam          DWORD ?
    time            DWORD ?

    ptX             DWORD ?
    ptY             DWORD ?

MSG ENDS


; ============================================================
; PIXELFORMATDESCRIPTOR
;
; Must be exactly 40 bytes.
; STRUCT 1 prevents MASM from inserting unwanted padding.
; ============================================================

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

className db "GraphXWindowClass",0

windowTitle db \
    "GraphX - MASM + OpenGL Mathematical Visualization",0


; ------------------------------------------------------------
; OpenGL clear color
;
; Dark blue/black background
; ------------------------------------------------------------

clearRed   REAL4 0.04
clearGreen REAL4 0.06
clearBlue  REAL4 0.10
clearAlpha REAL4 1.0


; ============================================================
; Uninitialized data
; ============================================================

.data?

hInstance DWORD ?
hMainWnd  DWORD ?

hDC       DWORD ?
hGLRC     DWORD ?

pixelFormat DWORD ?

windowClass WNDCLASSEX <>
messageData MSG <>
pfd         PIXELFORMATDESCRIPTOR <>


; ============================================================
; Code
; ============================================================

.code


; ============================================================
; RenderScene
;
; For Step 5 we only clear the OpenGL color buffer.
; ============================================================

RenderScene PROC STDCALL

    ; No rendering context yet?
    cmp hGLRC, 0
    je RenderDone

    ; Clear the OpenGL color buffer.
    invoke glClear, GL_COLOR_BUFFER_BIT

    ; Display the completed back buffer.
    invoke SwapBuffers, hDC

RenderDone:

    ret

RenderScene ENDP


; ============================================================
; InitializeOpenGL
;
; Input:
;   targetWnd = GraphX window handle
;
; Output:
;   EAX = 1 success
;   EAX = 0 failure
; ============================================================

InitializeOpenGL PROC STDCALL targetWnd:DWORD

    ; --------------------------------------------------------
    ; 1. Obtain the device context belonging to the window
    ; --------------------------------------------------------

    invoke GetDC, targetWnd

    test eax, eax
    jz OpenGLInitFailed

    mov hDC, eax


    ; --------------------------------------------------------
    ; 2. Prepare the pixel format descriptor
    ; --------------------------------------------------------

    mov pfd.nSize, SIZEOF PIXELFORMATDESCRIPTOR
    mov pfd.nVersion, 1


    mov pfd.dwFlags, \
        PFD_DRAW_TO_WINDOW OR \
        PFD_SUPPORT_OPENGL OR \
        PFD_DOUBLEBUFFER


    mov pfd.iPixelType, PFD_TYPE_RGBA


    ; Request 32-bit color.

    mov pfd.cColorBits, 32


    ; Request a depth buffer now so we can use it later
    ; when GraphX reaches 3D rendering.

    mov pfd.cDepthBits, 24


    mov pfd.iLayerType, PFD_MAIN_PLANE


    ; --------------------------------------------------------
    ; 3. Ask Windows for a matching pixel format
    ; --------------------------------------------------------

    invoke ChoosePixelFormat, hDC, ADDR pfd

    test eax, eax
    jz OpenGLInitFailed

    mov pixelFormat, eax


    ; --------------------------------------------------------
    ; 4. Set the window's pixel format
    ; --------------------------------------------------------

    invoke SetPixelFormat, \
        hDC,                \
        pixelFormat,        \
        ADDR pfd

    test eax, eax
    jz OpenGLInitFailed


    ; --------------------------------------------------------
    ; 5. Create an OpenGL rendering context
    ; --------------------------------------------------------

    invoke wglCreateContext, hDC

    test eax, eax
    jz OpenGLInitFailed

    mov hGLRC, eax


    ; --------------------------------------------------------
    ; 6. Make the context current on this thread
    ; --------------------------------------------------------

    invoke wglMakeCurrent, hDC, hGLRC

    test eax, eax
    jz OpenGLInitFailed


    ; --------------------------------------------------------
    ; 7. Set GraphX background color
    ;
    ; The arguments are passed as their raw 32-bit
    ; floating-point representations.
    ; --------------------------------------------------------

    invoke glClearColor, \
        DWORD PTR clearRed,   \
        DWORD PTR clearGreen, \
        DWORD PTR clearBlue,  \
        DWORD PTR clearAlpha


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

    ; --------------------------------------------------------
    ; Disconnect and delete the OpenGL rendering context.
    ; --------------------------------------------------------

    cmp hGLRC, 0
    je SkipGLRCleanup

    invoke wglMakeCurrent, 0, 0

    invoke wglDeleteContext, hGLRC

    mov hGLRC, 0


SkipGLRCleanup:

    ; --------------------------------------------------------
    ; Release the Windows device context.
    ; --------------------------------------------------------

    cmp hDC, 0
    je CleanupFinished

    invoke ReleaseDC, targetWnd, hDC

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
    ; WM_ERASEBKGND
    ;
    ; We render the background using OpenGL, so tell Windows
    ; that background erasing is already handled.
    ; --------------------------------------------------------

    cmp uMsg, WM_ERASEBKGND
    je BackgroundHandled


    ; --------------------------------------------------------
    ; WM_DESTROY
    ; --------------------------------------------------------

    cmp uMsg, WM_DESTROY
    je WindowDestroyed


    ; --------------------------------------------------------
    ; Everything else goes to Windows.
    ; --------------------------------------------------------

    invoke DefWindowProcA, \
        hWnd,              \
        uMsg,              \
        wParam,            \
        lParam

    ret


; ============================================================
; Window needs repainting
; ============================================================

WindowPaint:

    invoke RenderScene

    ; Remove the pending paint region.
    invoke ValidateRect, hWnd, 0

    xor eax, eax
    ret


; ============================================================
; Window was resized
;
; For now we simply redraw.
; glViewport comes in the next step.
; ============================================================

WindowSize:

    invoke RenderScene

    xor eax, eax
    ret


; ============================================================
; Prevent GDI background clearing
; ============================================================

BackgroundHandled:

    mov eax, 1
    ret


; ============================================================
; Window is being destroyed
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

    ; --------------------------------------------------------
    ; Initialize global handles.
    ; --------------------------------------------------------

    mov hDC, 0
    mov hGLRC, 0
    mov hMainWnd, 0


    ; ========================================================
    ; 1. Get executable module handle
    ; ========================================================

    invoke GetModuleHandleA, 0

    mov hInstance, eax


    ; ========================================================
    ; 2. Configure the GraphX window class
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


    ; --------------------------------------------------------
    ; Load Windows arrow cursor
    ; --------------------------------------------------------

    invoke LoadCursorA, 0, IDC_ARROW

    mov windowClass.hCursor, eax


    ; --------------------------------------------------------
    ; No GDI background brush.
    ;
    ; OpenGL owns the drawing area.
    ; --------------------------------------------------------

    mov windowClass.hbrBackground, 0


    mov windowClass.lpszMenuName, 0

    mov windowClass.lpszClassName, OFFSET className

    mov windowClass.hIconSm, 0


    ; ========================================================
    ; 3. Register the window class
    ; ========================================================

    invoke RegisterClassExA, ADDR windowClass

    test eax, eax
    jz RegistrationFailed


    ; ========================================================
    ; 4. Create GraphX window
    ; ========================================================

    invoke CreateWindowExA, \
        0,                  \
        ADDR className,     \
        ADDR windowTitle,   \
        WS_OVERLAPPEDWINDOW OR \
            WS_CLIPCHILDREN OR \
            WS_CLIPSIBLINGS, \
        CW_USEDEFAULT,      \
        CW_USEDEFAULT,      \
        1024,               \
        768,                \
        0,                  \
        0,                  \
        hInstance,          \
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
    ; 6. Show window
    ; ========================================================

    invoke ShowWindow, hMainWnd, SW_SHOWNORMAL

    invoke UpdateWindow, hMainWnd


    ; Draw once immediately.

    invoke RenderScene


; ============================================================
; 7. Windows message loop
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


    ; GetMessage failure

    cmp eax, -1
    je MessageLoopFailed


    invoke TranslateMessage, ADDR messageData

    invoke DispatchMessageA, ADDR messageData

    jmp MessageLoop


; ============================================================
; Normal exit
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

    ; Destroying the window will eventually cause
    ; OpenGL resources/DC resources to be cleaned if present.

    invoke CleanupOpenGL, hMainWnd

    invoke ExitProcess, 3


MessageLoopFailed:

    invoke CleanupOpenGL, hMainWnd

    invoke ExitProcess, 4


END start