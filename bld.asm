;; bld.asm - Bootloader for the Runic operating system
;; 
;; Copyright (C) 2021 Roxanne MacKinnon
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;; <rdm3@williams.edu> Roxanne MacKinnon

;; ptable entry format
;; byte 0: 0x80 if good, else bad
;; bytes 1-3: CHS address of first sector in partition
;; byte 4: partition type
;; bytes 5-7: CHS address of last sector in partition
;; byte 8: LBA of first absoute sector in partition
;; byte 0x0c: number of sectors in partition

;;CHS addresses:
;; byte 0: head number (from 0)
;; byte 1: [c9, c8] s5-s0 (c9, c8 high bits of cylinder, s5-0 sector bits, indexed from 1)
;; byte 2: c7-c0 (i think) low bits of cylinder address (from 0)

;; int 0x13 call params:
	; ah: function number
	; al: num sects
	; ch: cylinder number
	; cl: sector number
	; dh: head number
	; dl: drive number
	; es:bx: address of user buffer
	; returns cf = 0 on success, cf = 1 on failure (carry flag)
	
%define ptable_start 446
	org 0x0
	bits 16
	jmp 0x7c0:start 	; set (cs,ip) = (0x7c0, start)
	
	;; prepare to copy sector at 0x7c0:0x0000 to 0x060:0x0000
start:
	;; set data segment to 0x7c0:0x0
	mov bx, 0x7c0
	mov ds, bx
	mov [ds:511], dl
	;; set es segment to 0x060:0x0
	mov bx, 0x060
	mov es, bx
	xor bx, bx
	;; clear some flags
	cli
	cld
	jmp copy_sector
	
	;; copy sector
	
copy_sector:
	;; copy 512 bytes from 0x7c0:0x0 to 0x060:0x0
	cmp bx, 512
	je relocate
	mov ah, [ds:bx]
	mov [es:bx], ah
	inc bx
	jmp copy_sector
	
	;; begin executing from 'new' sector
relocate:	
	mov bx, 0x060
	mov ds, bx 		;set data segment to 0x060
	jmp 0x060:find_active_partition

	;; determine which of the 4 possible partitions is active, and
	;; store result (0,1,2,3) in ax, or -1 if no active partition
find_active_partition:
	mov bx, ptable_start - 16
	jmp find_active_partition0
	
find_active_partition0:
	add bx, 16
	cmp bx, 510
	jge no_active_partition
	mov ah, [bx]
	and ah,0x80
	jz find_active_partition0
	jmp load_part_parameters
	
no_active_partition:	
	mov ah, 0x0e
	mov al, 'n'
	int 0x10
	hlt
	
	;; load parameters from partition table entry into dh, cx, al, ah, and es.
	;; dh: chd address
load_part_parameters:
	add bx,1
	mov dh, [ds:bx] 		;set head number
	mov cl, [ds:bx + 1] 	;set sector number + upper bits cylinder number
	mov ch, [ds:bx + 2] 	;set lower bits of cylinder number
	mov dl, [ds:511] 		;set drive type from where it was set initially
	mov bx, 0x7c0 		;initialize sector where VBR will be read into
	mov es, bx 		;  ^^
try_read_sector:
	xor bx, bx 		;  ^^	
	mov ah, 0x2		;set bios call to DISK BIOS: READ DISK SECTORS
	mov al, 1 		;set num sectors to read = 1 (is this reliable?)
	int 0x13 		;read sector
	adc bh, bh
	jnz status_error
	jmp status_success

	
status_error:
	mov ah, 0x0e
	mov al,'b'
	cli
	int 0x10
	hlt
	
status_success:
	mov ah, 0x0e
	mov al, 'g'
	cli
	int 0x10
	hlt

	
	
	db `Welcome to RunicOS!\n\rI haven't been implemented yet...\n\rPress 'r' to reboot: `
	times 446-($-$$) db 0
	db 0x80,0x00,0x02,0x00,   0x02,  0x00,0x02,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	db 0x00,0x00,0x01,0x00,   0x00,  0x00,0x01,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	db 0x00,0x00,0x01,0x00,   0x00,  0x00,0x01,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	db 0x00,0x00,0x01,0x00,   0x00,  0x00,0x01,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	times 510-($-$$) db 0 
	dw 0xaa55 		; magic numbers for boot segment
othersector:	
	mov ah, 0x0e
	mov al, 'n'
	int 0x10
	jmp othersector
	times 1023-($-$$) db 0
