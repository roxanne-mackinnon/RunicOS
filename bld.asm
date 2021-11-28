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
start:	
	mov bx, 0x7c0
	mov ds, bx
	
set_video_mode:	
	mov ah, 0x0 		; int 0 -> set video mode
	mov al, VIDEO_MODE      ; 40 x 25 16 color text
	int 0x10
	
clear_screen:
	mov ah, 0x6 		; int 0x6 -> scroll window
	mov al, 0 		; al=0 means blank the region
	xor ch, ch 		; upper left row = 0
	xor cl, 0		; leftmost column = 0
	mov dh, VIDEO_HEIGHT-1 	; account for zero indexing with -1
	mov dl, VIDEO_WIDTH-1 
	int 0x10 		; clear window
	
prepare_message:	
	mov bx, message
	mov ah, 0x0e 		; ah 0xe -> print char to screen

printstring:
	mov al, [bx]		; get char
	and al, al 		; if its zero, exit
	jz wait_keypress
	add bx, 1 		; incr string
	int 0x10 		; print char
	jmp printstring
	
wait_keypress: 			; wait for user to press 'r', then reboot
	mov ah, 0x00
	int 0x16
	cmp al, 'r'
	jne wait_keypress
	
reboot:
	int 0x19
	hlt
	
message:
	db `Welcome to RunicOS!\n\rI haven't been implemented yet...\n\rPress 'r' to reboot: `
	times 510-($-$$) db 0 
	dw 0xaa55 		; magic numbers for boot segment
 
