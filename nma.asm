.model tiny
.data
    temp16 dw ?   ; used for 16-bit registry holding
    msg db '24', 0Dh, 0Ah, '$'
    baseData db ?
    file db 20 dup(0)   ; stores the name of a file that our batch script gave us
.code

org 100h

start:

    lea si, msg
    call print_message

exit:
    mov ax, 4C00h
    int 21h

print_message proc
    lea dx, [si]
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

getFileName proc
    mov ah, 62h ; chatGPT helped me with understanding PSP and some ideas in this segment are from him, but no code copied
    int 21h
    mov si, bx  ; pointer to where PSP starts
    lea di, file; pointer to where we are in file var
    add si, 80h
    mov cx, [si]; a pretty neat pointer optimisation: just load all into si and then add and inc. Nice
    cmp cx, 0
    je exit
    inc si
copyName:
    mov ax, [si]
    cmp al, 0dh
    je gotFile
    mov [di], al
    inc si
    inc di
    loop copyName
gotFile:
    ret
getFileName endp

end start
