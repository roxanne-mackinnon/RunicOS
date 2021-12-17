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


%define VIDEO_MODE 0x3
%define VIDEO_WIDTH 25
%define VIDEO_HEIGHT 80
	
%define ptable_start 446
	org 0x0
	bits 16
	jmp 0x7c0:start 	; set (cs,ip) = (0x7c0, start)
	
	;; prepare to copy sector at 0x7c0:0x0000 to 0x060:0x0000
start:
	
	;; set data segment to point to code segment 0x7c0:0x0
	mov bx, 0x7c0
	mov ds, bx
	;;  store drive number (in dl) at the last byte of the 512 byte segment
	mov [ds:511], dl

	;; clear interrupt and direction flags
	cli
	cld
	
	;; set video mode
	mov ah, 0x0 		; int 0 -> set video mode
	mov al, VIDEO_MODE      ; 40 x 25 16 color text
	int 0x10
	
	;; clear screen
	mov ah, 0x6 		; int 0x6 -> scroll window
	mov al, 0 		; al=0 means blank the region
	xor ch, ch		; leftmost column = 0
	xor cl, 0
	mov dh, VIDEO_HEIGHT-1 	; account for zero indexing with -1
	mov dl, VIDEO_WIDTH-1 
	int 0x10 		; clear window

	
	;; set up segment (es) where MBR will be copied to (0x060:0x0)
	mov bx, 0x060
	mov es, bx
	

	;; set bx to point to start of sector, to start copying
	xor bx, bx	

	;; copy 512 byte MBR from initial 0x7c0:0x0 location to new location at 0x060:0x0
	;; this is so that we may read in a VBR to 0x7c0:0x0
	
copy_sector:
	;; finish copying if we've copied 512 bytes
	cmp bx, 512
	je relocate

	;; copy one byte from ds sector to es sector
	mov ah, [ds:bx]
	mov [es:bx], ah

	;; move bx to point to the next byte, and loop
	inc bx
	jmp copy_sector
	

	;; set code segment and data segment to point to freshly copied segment 0x060:0x0
relocate:
	
	;; set the data segment
	mov bx, 0x060
	mov ds, bx
	mov sp, 446

	;; (implicitly) set code segment through this jump	
	jmp 0x060:find_active_partition

	;; find first active entry in partition table and interpret it
find_active_partition:
	;; set up bx for looping through each of 4 entries
	mov bx, ptable_start - 16
	jmp find_active_partition0

find_active_partition0:
	;; go to next part table entry (or zeroeth one on first iteration)
	add bx, 16

	;; if we've gone past the end of the table, exit with error
	cmp bx, 510
	jge no_active_partition

	;; if the part. table entry is not active, go to the next entry
	mov ah, [bx]
	and ah,0x80
	jz find_active_partition0
	jmp load_part_parameters

	;; print 'n' (used if there is no active partiion)
no_active_partition:	
	mov si, no_active_partition_message
	call print_message
	jmp prompt_reboot
	
	;; load partition parameters from active part. table entry to prepare
	;; for a disk read BIOS call
load_part_parameters:
	add bx,1  		;set bx to point to chs address of VBR sector
	mov dh, [ds:bx] 	;set head number
	mov cl, [ds:bx + 1] 	;set sector number + upper bits cylinder number
	mov ch, [ds:bx + 2] 	;set lower bits of cylinder number
	mov dl, [ds:511] 	;set drive type (dl was stored at ds:511 at start of bootloader program)
	
	mov bx, 0x7c0 		;set up location to which VBR should be read
	mov es, bx
	
try_read_sector:
	xor bx, bx
	mov ah, 0x2		;set bios call to DISK BIOS: READ DISK SECTORS
	mov al, 1 		;set num sectors to read = 1
	int 0x13 		;read sector (BIOS call 0x13)

	;; if carry flag is set (indicating error), print error message
	adc bh, bh
	jnz status_error
	
	;; otherwise, print success message
	jmp status_success

	
	;; print 'b' to the screen and halt(used on bad disk read)
status_error:
	mov si, disk_failure_message
	call print_message
	jmp prompt_reboot
	
print_message:	
	lodsb
	and al, al
	jnz print_message0
	ret
print_message0:	
	mov ah, 0x0e
	mov bx, 7
	int 0x10
	jmp print_message

	
status_success:
	mov si, welcome_message
	call print_message
	
prompt_reboot:
	mov si, reboot_prompt_message
	call print_message
	jmp reboot_on_keypress
	
reboot_on_keypress:
	mov ah, 0x0
	int 0x16
	int 0x19
	
die:
	hlt
	


no_active_partition_message:
	db `No active partition found...\n\r\0`
disk_failure_message:
	db `Disk read failure...\n\r\0`
welcome_message:	
	db `Welcome to RunicOS!\n\rDisk read success...\n\r\0`	
reboot_prompt_message:	
	db `Press any key to reboot: \0`
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
