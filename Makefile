AS=nasm -fbin -Wall

bld.bin: bld.asm
	$(AS) bld.asm -o bld.bin

ready: bld.bin
	test -e bld.bin && qemu-img dd -f raw -O qcow if=bld.bin of=runic.img count=1

clean:
	rm -f bld.bin 
