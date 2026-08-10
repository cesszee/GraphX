; ============================================================
; GraphX - Step 4
; First real 32-bit Win32 application window
;
; Build:
;   ml /nologo /c /coff main.asm
;
; Link:
;   link /nologo /SUBSYSTEM:WINDOWS /ENTRY:start main.obj ^
;        user32.lib kernel32.lib ^
;        /OUT:C:\GraphX\build\GraphX.exe
; ============================================================

.686
.model flat, stdcall
option casemap:none


; ============================================================
; Win32 API prototypes
; ============================================================

GetModuleHandleA PROTO STDCALL :DWORD
ExitProcess      PROTO STDCALL :DWORD

LoadCursorA      PROTO STDCALL :DWORD, :DWORD
RegisterClassExA PROTO STDCALL :DWORD

CreateWindowExA  PROTO STDCALL \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD

ShowWindow       PROTO STDCALL :DWORD, :DWORD
UpdateWindow     PROTO STDCALL :DWORD

GetMessageA      PROTO STDCALL \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD

TranslateMessage PROTO STDCALL :DWORD
DispatchMessageA PROTO STDCALL :DWORD

DefWindowProcA   PROTO STDCALL \
    :DWORD,      \
    :DWORD,      \
    :DWORD,      \
    :DWORD

PostQuitMessage  PROTO STDCALL :DWORD


; ============================================================
; Constants
; ============================================================

CS_VREDRAW          EQU 0001h
CS_HREDRAW          EQU 0002h

WM_DESTROY          EQU 0002h

WS_OVERLAPPEDWINDOW EQU 00CF0000h

CW_USEDEFAULT       EQU 80000000h

SW_SHOWNORMAL       EQU 1

IDC_ARROW           EQU 32512

COLOR_WINDOW        EQU 5


; ============================================================
; WNDCLASSEXA structure
;
; 32-bit layout = 12 DWORD fields = 48 bytes
; ============================================================

WNDCLASSEX STRUCT

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
; MSG structure
; ============================================================

MSG STRUCT

    hwnd            DWORD ?
    message         DWORD ?
    wParam          DWORD ?
    lParam          DWORD ?
    time            DWORD ?

    ptX             DWORD ?
    ptY             DWORD ?

MSG ENDS


; ============================================================
; Data
; ============================================================

.data

className db "GraphXWindowClass",0

windowTitle db "GraphX - Mathematical Visualization System",0


; ------------------------------------------------------------
; Global handles
; ------------------------------------------------------------

hInstance DWORD 0
hMainWnd  DWORD 0


; ------------------------------------------------------------
; Structures
; ------------------------------------------------------------

windowClass WNDCLASSEX <>
messageData MSG <>


; ============================================================
; Code
; ============================================================

.code


; ============================================================
; WindowProc
;
; Windows sends messages here.
;
; Parameters:
;   hwnd   = window handle
;   uMsg   = message number
;   wParam = additional message information
;   lParam = additional message information
; ============================================================

WindowProc PROC STDCALL \
    hwnd:DWORD,          \
    uMsg:DWORD,          \
    wParam:DWORD,        \
    lParam:DWORD


    ; --------------------------------------------------------
    ; Did Windows tell us the window was destroyed?
    ; --------------------------------------------------------

    cmp uMsg, WM_DESTROY
    je WindowDestroyed


    ; --------------------------------------------------------
    ; Any message we don't handle ourselves is passed back
    ; to Windows.
    ; --------------------------------------------------------

    invoke DefWindowProcA, \
        hwnd,              \
        uMsg,              \
        wParam,            \
        lParam

    ret


WindowDestroyed:

    ; --------------------------------------------------------
    ; Put WM_QUIT into our thread's message queue.
    ; --------------------------------------------------------

    invoke PostQuitMessage, 0

    xor eax, eax
    ret


WindowProc ENDP


; ============================================================
; Program entry
; ============================================================

start:


    ; ========================================================
    ; 1. Get this executable's module handle
    ; ========================================================

    invoke GetModuleHandleA, 0

    mov hInstance, eax


    ; ========================================================
    ; 2. Prepare WNDCLASSEX
    ; ========================================================

    mov windowClass.cbSize, SIZEOF WNDCLASSEX


    ; Redraw when horizontal or vertical size changes

    mov windowClass.style, CS_HREDRAW OR CS_VREDRAW


    ; Address of our window procedure

    mov windowClass.lpfnWndProc, OFFSET WindowProc


    ; No extra class/window bytes

    mov windowClass.cbClsExtra, 0
    mov windowClass.cbWndExtra, 0


    ; Application instance

    mov eax, hInstance
    mov windowClass.hInstance, eax


    ; No custom icon yet

    mov windowClass.hIcon, 0
    mov windowClass.hIconSm, 0


    ; ========================================================
    ; 3. Load the normal Windows arrow cursor
    ; ========================================================

    invoke LoadCursorA, 0, IDC_ARROW

    mov windowClass.hCursor, eax


    ; ========================================================
    ; 4. Background brush
    ;
    ; System color brushes use COLOR_xxx + 1.
    ; ========================================================

    mov windowClass.hbrBackground, COLOR_WINDOW + 1


    ; No menu yet

    mov windowClass.lpszMenuName, 0


    ; Window class name

    mov windowClass.lpszClassName, OFFSET className


    ; ========================================================
    ; 5. Register the window class
    ; ========================================================

    invoke RegisterClassExA, ADDR windowClass

    test eax, eax

    jz RegistrationFailed


    ; ========================================================
    ; 6. Create the GraphX window
    ; ========================================================

    invoke CreateWindowExA, \
        0,                  \
        ADDR className,     \
        ADDR windowTitle,   \
        WS_OVERLAPPEDWINDOW,\
        CW_USEDEFAULT,      \
        CW_USEDEFAULT,      \
        1024,               \
        768,                \
        0,                  \
        0,                  \
        hInstance,          \
        0


    ; CreateWindowExA returns HWND in EAX.

    test eax, eax

    jz WindowCreationFailed


    mov hMainWnd, eax


    ; ========================================================
    ; 7. Show the window
    ; ========================================================

    invoke ShowWindow, hMainWnd, SW_SHOWNORMAL


    ; Ask Windows to paint it now.

    invoke UpdateWindow, hMainWnd


; ============================================================
; 8. Main message loop
; ============================================================

MessageLoop:

    invoke GetMessageA, \
        ADDR messageData, \
        0,                \
        0,                \
        0


    ; --------------------------------------------------------
    ; GetMessage returns:
    ;
    ; > 0 = normal message
    ;   0 = WM_QUIT
    ;  -1 = error
    ; --------------------------------------------------------

    cmp eax, 0
    je ProgramFinished

    cmp eax, -1
    je MessageError


    ; Translate keyboard-related messages.

    invoke TranslateMessage, ADDR messageData


    ; Send the message to WindowProc.

    invoke DispatchMessageA, ADDR messageData


    jmp MessageLoop


; ============================================================
; Normal program termination
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


MessageError:

    invoke ExitProcess, 3


END start