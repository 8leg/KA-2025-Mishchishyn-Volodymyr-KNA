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
loadReady:
    mov di, len     ; starting from end
loadStack:          ; loads es to the stack. Uses twice as much memory but I don't care
    dec di
    mov al, byte ptr es:[di]
    push ax
    mov byte ptr es:[di], 0
    cmp di, 0
    jne loadStack
    cmp temp16, 1234h   ; this is a switch so we can skip startOver
    jne startOver
    mov temp16, 0000h
    jmp selectAmmo
startOver:
    lea bx, drum    ; points at position in the drum
    lea si, temp8   ; points at where the ammo is at
    xor cx, cx
    jmp selectAmmo
selectAmmo:         ; bx is taken up as pointer to where the ammo is. cx is len of bullet. All stored in temp8, si is free
    inc bx
    cmp byte ptr [bx], 0
    je bye
    cmp byte ptr [bx-1], 09h
    je bitByBit
    mov al, byte ptr [bx-1]
    mov byte ptr [si], al
    inc cx
    inc si
    jmp selectAmmo
bitByBit:           ; none are bind to here, but beware of stack. DI is pointer in ES
    cmp di, len
    jge skipPayload
    lea si, temp8
    pop ax
    mov byte ptr es:[di], al
    inc di
    jo bye
    cmp di, cx
    jl bitByBit
    push cx
    push di
    sub di, cx
    repe cmpsb
    jz reWrite
    pop di
    pop cx
    jmp bitByBit
loadReady_relay:
    jmp loadReady
reWrite:
    pop di
    pop cx
    sub di, cx
writing_cycle:      ; time to switch to snake_case. Just for the hell of it
    mov ah, [bx]
    mov es:[di], ah
    inc di
    jo bye
    inc bx
    cmp byte ptr [bx], 09h
    je restore_line
    jmp writing_cycle
restore_line:       ; restores line from the stack. At least it should. Then starts over
    mov len, di
    cmp sp, 0ffffh
    jge loadReady_relay
    pop ax
    mov es:[di], al
    inc di
    jmp restore_line
skipPayload:
    mov temp16, 1234h
    lea si, temp8
    xor cx, cx
    inc bx
    cmp byte ptr [bx], 0
    je bye
    cmp byte ptr [bx-1], 09h
    je loadReady_relay
    jmp skipPayload
bye:
    inc di
    mov cx, di
    mov si, 0
    mov byte ptr es:[di-2], 0dh
    mov byte ptr es:[di-1], 0ah
printLoop:
    mov dl, es:[si]
    inc si
    mov ah, 2h
    int 21h
    loop printLoop
    mov ax, 4C00h
    int 21h
end start