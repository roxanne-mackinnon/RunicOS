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

%define VIDEO_MODE 0x3
%define VIDEO_WIDTH 25
%define VIDEO_HEIGHT 80
	
	org 0x0
	bits 16
	jmp 0x7c0:start 	; set (cs,ip) = (0x7c0, start)
	
	;; prepare to copy sector at 0x7c0:0x0000 to 0x060:0x0000
start:
	mov bx, 0x7c0
	mov ds, bx
	xor bx, bx
	jmp copy_sector
	
	;; copy sector
copy_sector:
	cmp bx, 512
	je prepare_to_load
	mov ah, [0x7c0:bx]
	mov [0x060:bx], ah
	incr bx
	jmp copy_sector
	
	;; begin executing from 'new' sector
prepare_to_load:	
	mov bx, 0x060
	mov ds, bx
	jmp 0x060:newstart
	
newstart:
	mov bx, 451
	jmp findpart
	
	;; find active partition
findpart:
	add bx, 16
	cmp bx, 510
	jge no_active_part
	mov ah, [bx]
	and ah,0x80
	jz findpart
	jmp found_part

	;; stop the system
found_part:		
	hlt
	jmp found_part

	
	db `Welcome to RunicOS!\n\rI haven't been implemented yet...\n\rPress 'r' to reboot: `
	times 510-($-$$) db 0 
	dw 0xaa55 		; magic numbers for boot segment
 
