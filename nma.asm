.model tiny
.data
    temp16 dw ?   ; used for 16-bit registry holding
    msg db 256 dup(?)
    fileData db 32769 dup(?)
    file db 20 dup(?)   ; stores the name of a file that our batch script gave us
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
readFile:
    XCHG ax, bx
    mov cx, 32768
    lea  dx, fileData
    mov ah, 3Fh
    int 21h
exit:
    mov byte ptr [di], '$'
    mov di, dx
    add di, ax
    mov byte ptr [di], '$'
    lea si, file
    call print_message
    lea si, fileData
    call print_message
    mov ax, 4C00h
    int 21h

print_message proc
    mov dx, si
    mov ah, 09h
    int 21h
    ret
print_message endp

saveRegs proc
    pop temp16
    push ax
    push bx
    push cx
    push dx
    push temp16
    ret
saveRegs endp

loadRegs proc
    pop temp16
    pop dx
    pop cx
    pop bx
    pop ax
    push temp16
    ret
loadRegs endp

clearRegs proc
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    xor si, si
    xor di, di
clearRegs endp

end start
