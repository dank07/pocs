; a PE with a Debug Directory (and missing symbols)

; Ange Albertini, BSD LICENCE 2012-2013

%include 'consts.inc'

IMAGEBASE equ 400000h
org IMAGEBASE
bits 32

SECTIONALIGN equ 1000h
FILEALIGN equ 200h

istruc IMAGE_DOS_HEADER
    at IMAGE_DOS_HEADER.e_magic,  db 'MZ'
    at IMAGE_DOS_HEADER.e_lfanew, dd NT_Headers - IMAGEBASE
iend

NT_Headers:
istruc IMAGE_NT_HEADERS
    at IMAGE_NT_HEADERS.Signature, db 'PE', 0, 0
iend
istruc IMAGE_FILE_HEADER
    at IMAGE_FILE_HEADER.Machine,               dw IMAGE_FILE_MACHINE_I386
    at IMAGE_FILE_HEADER.NumberOfSections,      dw NUMBEROFSECTIONS
    at IMAGE_FILE_HEADER.SizeOfOptionalHeader,  dw SIZEOFOPTIONALHEADER
    at IMAGE_FILE_HEADER.Characteristics,       dw IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_32BIT_MACHINE \
        | 200h | 0eh  ; IMAGE_FILE_DEBUG_STRIPPED  <===
iend

OptionalHeader:
istruc IMAGE_OPTIONAL_HEADER32
    at IMAGE_OPTIONAL_HEADER32.Magic,                 dw IMAGE_NT_OPTIONAL_HDR32_MAGIC
    at IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint,   dd EntryPoint - IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.ImageBase,             dd IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.SectionAlignment,      dd SECTIONALIGN
    at IMAGE_OPTIONAL_HEADER32.FileAlignment,         dd FILEALIGN
    at IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion, dw 4
    at IMAGE_OPTIONAL_HEADER32.SizeOfImage,           dd 2 * SECTIONALIGN
    at IMAGE_OPTIONAL_HEADER32.SizeOfHeaders,         dd SIZEOFHEADERS
    at IMAGE_OPTIONAL_HEADER32.Subsystem,             dw IMAGE_SUBSYSTEM_WINDOWS_CUI
    at IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes,   dd 16
iend

istruc IMAGE_DATA_DIRECTORY_16
    at IMAGE_DATA_DIRECTORY_16.ImportsVA, dd Import_Descriptor - IMAGEBASE
    at IMAGE_DATA_DIRECTORY_16.DebugVA,   dd Debug - IMAGEBASE, DEBUGSIZE
iend

SIZEOFOPTIONALHEADER equ $ - OptionalHeader
SectionHeader:
istruc IMAGE_SECTION_HEADER
    at IMAGE_SECTION_HEADER.VirtualSize,      dd 1 * SECTIONALIGN
    at IMAGE_SECTION_HEADER.VirtualAddress,   dd 1 * SECTIONALIGN
    at IMAGE_SECTION_HEADER.SizeOfRawData,    dd 2 * FILEALIGN
    at IMAGE_SECTION_HEADER.PointerToRawData, dd 1 * FILEALIGN
    at IMAGE_SECTION_HEADER.Characteristics,  dd IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_MEM_WRITE
iend
NUMBEROFSECTIONS equ ($ - SectionHeader) / IMAGE_SECTION_HEADER_size
SIZEOFHEADERS equ $ - IMAGEBASE

section progbits vstart=IMAGEBASE + SECTIONALIGN align=FILEALIGN

EntryPoint: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; enable DbgPrint output
    times 3 push 0
    call [__imp__SymGetOptions]
    or eax, SYMOPT_DEBUG
_
    push eax
    call [__imp__SymSetOptions]
_
    push 1
    push 0
    push -1
    call [__imp__SymInitialize]
    cmp eax, 1
    jnz end_
    
    push Msg
    call [__imp__printf]
    add esp, 1 * 4
_
end_:
    push 0
    call [__imp__ExitProcess]
_c

Msg db " * a PE with a Debug Directory (and missing symbols)", 0ah, 0
_d

Debug: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
istruc IMAGE_DEBUG_DIRECTORY
    at IMAGE_DEBUG_DIRECTORY.Type, dd IMAGE_DEBUG_TYPE_CODEVIEW
    at IMAGE_DEBUG_DIRECTORY.SizeOfData, dd CODEVIEWSIZE
    at IMAGE_DEBUG_DIRECTORY.AddressOfRawData, dd CodeView - IMAGEBASE
    at IMAGE_DEBUG_DIRECTORY.PointerToRawData, dd CodeView - IMAGEBASE - SECTIONALIGN + FILEALIGN
iend
DEBUGSIZE equ $ - Debug
_d

CodeView:
SIG  db 'RSDS'
GUID dd 0,0,0,0
AGE  dd 00000060h
db 'nosymbols.pdb', 0
    align 4, db 0
CODEVIEWSIZE equ $ - CodeView

_d
Import_Descriptor: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_import_descriptor kernel32.dll
_import_descriptor msvcrt.dll
_import_descriptor dbghelp.dll
istruc IMAGE_IMPORT_DESCRIPTOR
iend
_d

kernel32.dll_hintnames:
    dd hnExitProcess - IMAGEBASE
    dd 0
msvcrt.dll_hintnames:
    dd hnprintf - IMAGEBASE
    dd 0

dbghelp.dll_hintnames:
    dd hnSymGetOptions - IMAGEBASE
    dd hnSymSetOptions - IMAGEBASE
    dd hnSymInitialize - IMAGEBASE
    dd 0
_d

hnExitProcess:
    dw 0
    db 'ExitProcess', 0
hnprintf:
    dw 0
    db 'printf', 0
hnSymGetOptions:
    dw 0
    db 'SymGetOptions', 0
hnSymSetOptions:
    dw 0
    db 'SymSetOptions', 0
hnSymInitialize:
    dw 0
    db 'SymInitialize', 0
_d

kernel32.dll_iat:
__imp__ExitProcess:
    dd hnExitProcess - IMAGEBASE
    dd 0

msvcrt.dll_iat:
__imp__printf:
    dd hnprintf - IMAGEBASE
    dd 0
dbghelp.dll_iat:
__imp__SymGetOptions dd hnSymGetOptions - IMAGEBASE
__imp__SymSetOptions dd hnSymSetOptions - IMAGEBASE
__imp__SymInitialize dd hnSymInitialize - IMAGEBASE
    dd 0
_d

kernel32.dll db 'kernel32.dll', 0
msvcrt.dll db 'msvcrt.dll', 0
dbghelp.dll db 'dbghelp.dll', 0
_d

align FILEALIGN, db 0
