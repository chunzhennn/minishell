shellcode:
	nasm -fbin minishell.asm
	@python3 -c "a=open('./minishell','rb').read();print(f'len:{hex(len(a))}\n{str(a)}')"

test:
	nasm -felf64 minishell.asm
	ld --omagic minishell.o -o minishell.elf

run: test
	./minishell.elf

clean:
	-rm minishell.o
	-rm minishell.elf
	-rm minishell
