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


	org 0x7c00
	bits 16
	jmp 0x0000:start 	; set (cs,ip) = (0, start)
start:	

	xor bx, bx 		;
	mov ds, bx 		; set ds = 0 in absolute memory
	mov ah, 0x0e 		; prepare to print the char 'B'
	mov al, 'B'
	mov [ds:0], BYTE 0xcd 	; at the absolute start of mem, 
	mov [ds:1], BYTE 0x10 	; write the instructions "int 0x10, hlt"
	mov [ds:2], BYTE 0xf4 	; this will print a character and then halt
	jmp 0x0000:0 		; execute instruction at memory address 0
				
	times 510-($-$$) db 0 
	dw 0xaa55 		; magic numbers for boot segment
 
