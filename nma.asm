.model tiny
.data
    templen db 8 dup(?)
    len dw 0    ; lentght of drum
    dlen dw 0   ; len of a drum
    file db 12 dup(?)       ; stores the name of a file that our batch script gave us. 11 because DOS allows only 8 sumbols+.nma
    drum db 32769 dup (0)
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
    jo exit ; overflow check
readLine:
    sub ax, 2
    mov cx, ax
    mov len, ax
    mov ah, 3Fh
    lea dx, drum
    int 21h
    mov cx, len
    mov si, 0
    lea di, drum
    rep movsb
loadAmmoSpecs:
    lea di, drum
    lea dx, temp8
    mov cx, 6
    mov ah, 3Fh
    int 21h
    mov cx, 1
    mov si, 0   ; I'm so sorry for using si as just a flag for cycle. I don't know why but it feels dirthy
    mov bx, 0
loadAmmo:
    inc bx
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
    mov dlen, bx
    mov byte ptr [di], '$'
    mov ah, 3Eh
    int 21h






exit:
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