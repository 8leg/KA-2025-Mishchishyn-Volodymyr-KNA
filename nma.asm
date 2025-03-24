.model tiny
.data
    temp8 dw ?  ; used for temp data
    templen db 8 dup(?)
    line db 32768 dup (0)
    file db 20 dup(?)   ; stores the name of a file that our batch script gave us
    len dw 0    ; lentght of line
.code

org 100h

start:
    lea di, file
    mov si, 82h     ; 82 because there is two more useless symbols in memory as can be seen in dump
getFilename:
    mov ax, ds:[si] ; this line was killing me, but Claude told me more about ds indexing. Thanks mate
    inc si
	cmp al, 20h     ; those both set flags so why not do it like that?
    cmp al, 0Dh     ; carriage return and space both deliminate (I know clever words) so yeah
    je openFile
    mov [di], ax
    inc di
    jmp getFilename
openFile:
    mov al, 0
    lea dx, file
    mov ah, 3Dh
    int 21h
    jc exit
readingSpecs:
    xchg ax, bx
    mov cx, 8
    lea dx, templen
    mov ah, 3Fh
readLen:
    int 21h
    mov al, [templen+4]
    cmp [templen+5], 0
    je readLine
    mul [templen+5]
    sub ax, 2
readLine:
    mov cx, ax
    mov len, ax
    mov ah, 3Fh
    lea dx, line
    int 21h

closeFile:
    mov ah, 3Eh
    int 21h
exit:
    mov byte ptr [di], '$'
    lea di, line
    mov [line+24], '$'
    lea si, file
    call print_message
    lea si, line
    call print_message
    mov ax, 4C00h
    int 21h

print_message proc
    mov dx, si
    mov ah, 09h
    int 21h
    ret
print_message endp

end start
