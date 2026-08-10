.686
.model flat, stdcall
option casemap:none

ExitProcess PROTO STDCALL :DWORD

.code

start:
    invoke ExitProcess, 0

END start