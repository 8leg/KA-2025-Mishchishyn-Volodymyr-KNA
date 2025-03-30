.model tiny
.data
    templen db 8 dup(0)
    len dw 0    ; lentght of drum
    file db 13 dup(0)       ; stores the name of a file that our batch script gave us. 11 because DOS allows only 8 sumbols+.nma
    drum db 32769 dup (0)
    dlen dw 0   ; len of a drum
    temp16 dw 0
    temp8 db ?  ; used for temp data
.code

org 100h

start:
    mov ax, 93D0h   ; memory stuff
    mov es, ax
    mov ax, 7000h
    mov ss, ax      ; give stack enough room to wiggle

    lea di, file
    mov si, 82h     ; 82 because there is two more useless symbols in memory as can be seen in dump
getFilename:
    mov ax, ds:[si]
    inc si
    cmp al, 20h     ; those both set flags so why not do it like that?
    cmp al, 0Dh     ; carriage return and space both deliminate (I know clever words) so yeah
    je openFile
    mov [di], ax
    inc di
    jmp getFilename
openFile:
    ;mov byte ptr [di], 24h
    mov al, 0
    lea dx, file
    mov ah, 3Dh
    int 21h
    jc exit
readingSpecs:
    xchg bx, ax
    mov cx, 8
    lea dx, templen
    mov ah, 3Fh
readLen:
    int 21h
    mov al, [templen+4]
    cmp [templen+5], 0
    je readLine
    mul [templen+5]
    jo exit ; overflow check
readLine:
    sub ax, 2
    mov cx, ax
    mov len, ax
    mov ah, 3Fh
    lea dx, drum
    int 21h
    mov cx, len
    lea si, drum
    mov di, 0
    rep movsb
    mov cx, len
clearDrum:
    dec si
    mov byte ptr [si], 0
    cmp cx, 0
    dec cx
    jne clearDrum
loadAmmoSpecs:
    lea di, drum
    lea dx, temp8
    mov cx, 6
    mov ah, 3Fh
    int 21h
    mov cx, 1
    mov si, 0   ; I'm so sorry for using si as just a flag for cycle. I don't know why but it feels dirthy
    jmp loadAmmo
exit:           ; kind of a patchwork to not make long jumps....
    mov ax, 4C00h
    int 21h
loadAmmo:
    mov ah, 3Fh
    int 21h
    cmp ax, 0
    je closeFile
    cmp si, 2
    je skipComment
    cmp temp8, 09h
    jne addAndGoBack
    inc si
addAndGoBack:
    mov al, temp8
    mov [di], al
    inc di
    jmp loadAmmo
skipComment:
    cmp temp8, 0ah
    jne loadAmmo
    mov si, 0
    jmp loadAmmo
closeFile:
    mov byte ptr [di+bx], '$'
    mov ah, 3Eh
    int 21h

startOver:
    lea bx, drum    ; points at position in the drum
    lea si, temp8   ; points at where the ammo is at
    xor cx, cx
selectAmmo:         ; bx is taken up as pointer to where the ammo is. cx is len of bullet. All stored in temp8, si is free
    cmp byte ptr [bx], 0
    je bye
    cmp byte ptr [bx], 09h
    inc bx
    je loadReady
    mov al, byte ptr [bx-1]
    mov byte ptr [si], al
    inc cx
    inc si
    jmp selectAmmo
loadReady:
    mov di, len     ; starting from end
loadStack:          ; loads es to the stack. Uses twice as much memory but I don't care
    mov al, byte ptr es:[di]
    push ax
    mov byte ptr es:[di], 0
    cmp di, 0
    je nimbleByNimble
    dec di
nimbleByNimble:
    lea si, temp8
    pop ax
    mov byte ptr es:[di], al
    cmp di, cx
    inc di
    jo bye
    jl nimbleByNimble
    push cx
    sub di, cx
    repe cmpsb
    pop cx
    jz reWrite
    jnz nimbleByNimble
reWrite:

bye:
    lea dx, drum
    mov ah, 09h
    int 21h
    mov ax, 4C00h
    int 21h
print_message proc
    mov dl, [si]
    inc si
    cmp dl, 0
    cmp dl, 24h
    jne notRet
    ret
notRet:
    mov ah, 02h
    int 21h
print_message endp

end start