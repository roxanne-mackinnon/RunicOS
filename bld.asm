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


	org 0x0
	bits 16
	jmp 0x7c0:start 	; set (cs,ip) = (0x7c0, start)
start:	
	mov bx, 0x7c0
	mov ds, bx
	mov bx, message
	mov ah, 0x0e 		; prepare to print the char 'B'
loop:
	mov al, [bx]
	and al, al
	jz end
	add bx, 1
	int 0x10
	jmp loop
end:
	hlt
message:
	db `hello, roxanne!\n\r`
	times 510-($-$$) db 0 
	dw 0xaa55 		; magic numbers for boot segment
 
