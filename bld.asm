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
%define ptable_start 446
	org 0x0
	bits 16
	jmp 0x7c0:start 	; set (cs,ip) = (0x7c0, start)
	
	;; prepare to copy sector at 0x7c0:0x0000 to 0x060:0x0000
start:
	;; set data segment to 0x7c0:0x0
	mov bx, 0x7c0
	mov ds, bx
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
	mov ax, bx
	jmp load_part_parameters
	
no_active_partition:	
	mov ah, 0x0e
	mov al, 'n'
	int 0x10
	hlt
	
	;; load active partition into memory
load_part_parameters:
	add bx,1
	mov dh, [bx]
	;;  dont change dl!
	add bx, 1
	mov cx, [bx]
	ror cx, 8
	mov al, 0x01
	mov ah, 0x02
	;; set segmentation
	mov bx, 0x7c0
	mov es, bx
	xor bx, bx
	int 0x13
	jmp see_status
	
see_status:
	mov ah, 0x0e
	adc bh,bh
	jz status_success
	jmp status_error
	
status_error:	
	mov al,'b'
	int 0x10
	hlt
	
status_success:
	mov al, 'g'
	int 0x10
	hlt

	
	
	db `Welcome to RunicOS!\n\rI haven't been implemented yet...\n\rPress 'r' to reboot: `
	times 446-($-$$) db 0
	db 0x80,0x00,0x01,0x00,   0x00,  0x00,0x01,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	db 0x00,0x00,0x01,0x00,   0x00,  0x00,0x01,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	db 0x00,0x00,0x01,0x00,   0x00,  0x00,0x01,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	db 0x00,0x00,0x01,0x00,   0x00,  0x00,0x01,0x00, 0x00,0x00,0x00,0x00, 0x01,0x00,0x00,0x00
	times 510-($-$$) db 0 
	dw 0xaa55 		; magic numbers for boot segment
 
