.model tiny
.data
    temp8 db ?  ; used for temp data
    templen db 8 dup(?)
    line db 32768 dup (0)
    drum db 31986 dup (0)   ; it's called drum, inspired by revolver drums. Used to store the commands. 31986 is the biggest possible size rules can have in NMA file
    file db 11 dup(?)       ; stores the name of a file that our batch script gave us. 11 because DOS allows only 8 sumbols+.nma
    len dw 0    ; lentght of line
.code

org 100h

start:
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
    lea dx, line
    int 21h
loadAmmoSpecs:
    lea di, drum
    lea dx, temp8
    mov cx, 6
    mov ah, 3Fh
    int 21h
    mov cx, 1
    mov si, 0   ; I'm so sorry for using si as just a flag for cycle. I son't know why but it feels dirthy
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
    mov ah, 3Eh
    int 21h
exit:
    ;lea si, drum
    mov byte ptr [di], '$'
    ;lea di, line
    ;mov [line+24], '$'
    ;lea si, file
    ;call print_message
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