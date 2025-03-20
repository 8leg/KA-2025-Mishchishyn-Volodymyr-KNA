.model tiny
.code
org 100h
start:
    call print_message
    
    mov ax, 4C00h
    int 21h

print_message proc
    mov dx, offset msg
    mov ah, 09h
    int 21h
    ret
print_message endp
    
msg db '24', 0Dh, 0Ah, '$'
end start
