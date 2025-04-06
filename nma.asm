.model tiny
.data
    stack_counter dw 0
    templen db 8 dup(0)
    len dw 0    ; lentght of drum
    drum db 32769 dup (0)
    temp16 dw 0
    temp8 db ?  ; used for temp data
.code
; this is just a note to self to remember where which variable is
; stack_counter = 02B2
; templen       = 02B4
; len           = 02BC
; drum          = 02BE
; temp16        = 82BF
; temp8         = 82C1
org 100h
start:
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
    cmp ax, 2
    je loadAmmoSpecs
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
    je loadAmmoSpecs
    dec cx
    jmp clearDrum
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
    lea bx, drum
loadReady:
    xor cx, cx
    lea si, temp8
    mov di, len     ; starting from end
    cmp di, 0
    je selectAmmo
loadStack:          ; loads es to the stack. Uses twice as much memory but I don't care
    dec di
    mov al, byte ptr es:[di]
    push ax
    inc stack_counter
    mov byte ptr es:[di], 0
    cmp di, 0
    jne loadStack
    cmp temp16, 1234h   ; this is a switch so we can skip startOver
    jne startOver
    jmp selectAmmo
startOver:
    lea bx, drum    ; points at position in the drum
    lea si, temp8   ; points at where the ammo is loaded
    xor cx, cx
selectAmmo:         ; bx is taken up as pointer to where the ammo is. cx is len of bullet. All stored in temp8, si is free
    mov temp16, 0000h
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
    cmp di, len
    jge skipPayload
    lea si, temp8
    pop ax
    dec stack_counter
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
    cmp temp16, 'tr'
    je bye
    jmp loadReady
reWrite:
    pop di
    pop cx
    sub di, cx
writing_cycle:      ; time to switch to snake_case. Just for the hell of it
    cmp byte ptr [bx], 2eh
    jne continue
    mov temp16, 'tr'
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
    mov len, di
    cmp stack_counter, 0
    je loadReady_relay
    pop ax
    dec stack_counter
    mov es:[di], al
    inc di
    mov byte ptr es:[di], 0
    jmp restore_line
skipPayload:
    mov temp16, 1234h
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