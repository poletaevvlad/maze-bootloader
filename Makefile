build:
	nasm -f bin maze.asm -o maze

floppy: build
	dd if=/dev/zero of=maze.img bs=1024 count=1440
	dd if=maze of=maze.img seek=0 count=1 conv=notrunc


vdi: floppy
	rm -f maze.vdi
	VBoxManage convertfromraw ./maze.img ./maze.vdi --format vdi
