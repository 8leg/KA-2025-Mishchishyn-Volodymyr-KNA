.model tiny
.data
    temp16 dw ?   ; used for 16-bit registry holding
    msg db '24', 0Dh, 0Ah, '$'
    baseData db ?
    file db 20 dup(?)   ; stores the name of a file that our batch script gave us
.code

org 100h

start:

    call getFile
    mov byte ptr [di], '$'
    lea si, file
    call print_message

exit:
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

getToData proc
    mov ah, 3dh
    mov bx, 0h
    mov cx, 1
    mov dx, offset baseData
    seekLoop:
        int 21h
        call saveRegs
        mov cl, baseData
        mov msg, cl
        call print_message
        call loadRegs
        cmp baseData, 0h
        je seekLoop
    ret
getToData endp

getFile proc
    lea di, file
    mov si, 82h
begin:
    mov ax, ds:[si] ; this line was killing me for a lot of time, but Claude told me more about indexing. Thanks mate
    inc si
	cmp al, 20h ; those both set flags so why not do it like that?
    cmp al, 0Dh ; carriage return and space both deliminate so yeah
    je cont
    mov [di], ax
    inc di
    jmp begin
cont:
    ret
getFile endp

end start
