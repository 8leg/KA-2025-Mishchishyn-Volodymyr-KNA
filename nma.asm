.model tiny
.code
; this is just a note to self to remember where which variable is
; stack_counter = 009Ch word
; templen       = 0090h
; len           = 0099h word
; drum          = 02BEh
; temp16        = 009Eh word
; temp8         = 82C1h
; small variables are stored in an empty space after the file's name
; huge drum and temp16 get themselves a big empty field at the start
org 100h
start:
    mov cx, 0B200h  ; arbitrary giant number :3
    mov di, 02BEh
    xor al, al
    rep stosb   ; clear room for a drum. Hope it doesn't break anything
    mov ax, 7001h   ; memory stuff
    mov es, ax
    mov ax, 7000h
    mov ss, ax      ; give stack enough room to wiggle
openFile:
    mov al, 0
    mov dx, 82h
    mov ah, 3Dh
    int 21h
    jc exit
readingSpecs:
    xchg bx, ax
    mov cx, 8
    mov dx, 0090h
    mov ah, 3Fh
readLen:
    int 21h
    mov al, ds:[0090h+4]
    cmp byte ptr ds:[0090h+5], 0
    je readLine
    mul byte ptr ds:[0090h+5]
    jo exit ; overflow check
readLine:
    cmp ax, 2
    je loadAmmoSpecs
    sub ax, 2
    mov cx, ax
    mov word ptr ds:[0099h], ax
    mov ah, 3Fh
    mov dx, 02BEh
    int 21h
    mov cx, word ptr ds:[0099h]
    mov si, 02BEh
    mov di, 0
    rep movsb
    mov cx, word ptr ds:[0099h]
clearDrum:
    dec si
    mov byte ptr [si], 0
    cmp cx, 0
    je loadAmmoSpecs
    dec cx
    jmp clearDrum
loadAmmoSpecs:
    mov di, 02BEh
    mov dx, 82C1h
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
    cmp byte ptr ds:[82C1h], 09h
    jne addAndGoBack
    inc si
addAndGoBack:
    mov al, byte ptr ds:[82C1h]
    mov [di], al
    inc di
    jmp loadAmmo
skipComment:
    cmp byte ptr ds:[82C1h], 0ah
    jne loadAmmo
    mov si, 0
    jmp loadAmmo
closeFile:
    mov byte ptr [di+bx], '$'
    mov ah, 3Eh
    int 21h
    mov bx, 02BEh
loadReady:
    xor cx, cx
    mov si, 82C1h
    mov di, word ptr ds:[0099h]     ; starting from end
    cmp di, 0
    je selectAmmo
loadStack:          ; loads es to the stack. Uses twice as much memory but I don't care
    dec di
    mov al, byte ptr es:[di]
    push ax
    inc word ptr ds:[009Ch]
    mov byte ptr es:[di], 0
    cmp di, 0
    jne loadStack
    cmp word ptr ds:[009Eh], 1234h   ; this is a switch so we can skip startOver
    jne startOver
    jmp selectAmmo
startOver:
    mov bx, 02BEh    ; points at position in the drum
    mov si, 82C1h   ; points at where the ammo is loaded
    xor cx, cx
selectAmmo:         ; bx is taken up as pointer to where the ammo is. cx is len of bullet. All stored in temp8, si is free
    mov word ptr ds:[009Eh], 0000h
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
    cmp cx, 0
    je writing_cycle
    cmp di, word ptr ds:[0099h]
    jge skipPayload
    mov si, 82C1h
    pop ax
    dec word ptr ds:[009Ch]
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
    cmp word ptr ds:[009Eh], 'tr'
    je bye
    jmp loadReady
reWrite:
    pop di
    pop cx
    sub di, cx
writing_cycle:      ; time to switch to snake_case. Just for the hell of it
    cmp byte ptr [bx], 2eh
    jne continue
    mov word ptr ds:[009Eh], 'tr'
    jmp restore_line
continue:
    cmp byte ptr [bx], 09h
    je restore_line
    mov ah, [bx]
    mov es:[di], ah
    inc di
    mov byte ptr es:[di], 0
    jo bye
    inc bx
    cmp byte ptr [bx], 09h
    je restore_line
    jmp writing_cycle
bye:
    mov si, 0
    jmp printLoop
restore_line:       ; restores line from the stack. At least it should. Then starts over
    mov word ptr ds:[0099h], di
    cmp word ptr ds:[009Ch], 0
    je loadReady_relay
    pop ax
    dec word ptr ds:[009Ch]
    mov es:[di], al
    inc di
    mov byte ptr es:[di], 0
    jmp restore_line
skipPayload:
    mov word ptr ds:[009Eh], 1234h
    inc bx
    cmp byte ptr [bx], 0
    je bye
    cmp byte ptr [bx-1], 09h
    je loadReady_relay
    jmp skipPayload
printLoop:
    cmp di, 0
    je exiiiiiiiiiiiiiit
    mov dl, es:[si]
    inc si
    dec di
    mov ah, 2h
    int 21h
    jmp printLoop
exiiiiiiiiiiiiiit:
    mov dl, 0dh
    mov ah, 2h
    int 21h
    mov dl, 0ah
    mov ah, 2h
    int 21h
    mov ax, 4C00h
    int 21h
end start