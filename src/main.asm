.686
.model flat, stdcall
option casemap:none

MessageBoxA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess PROTO STDCALL :DWORD

.data
msgText  db "GraphX is running!",0
msgTitle db "GraphX",0

.code

start:
    invoke MessageBoxA, 0, ADDR msgText, ADDR msgTitle, 0
    invoke ExitProcess, 0

END start
