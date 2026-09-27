
        ; _welcome_v1.asm
        ; -----------------------------------------------------------------------
        ; Welcome message: sent to each player 90 seconds after connecting.
        ; One-time per connection.
        ;
        ; HOW IT WORKS:
        ;   Timer fires every 5 seconds.
        ;   Per slot: seen_id[64] — last seen client ID (0 = slot was empty).
        ;   When a client appears in a slot with a new ID:
        ;     countdown[slot] = 18  (18 * 5s = 90s)
        ;   Each tick: if countdown[slot] > 0, decrement.
        ;   When countdown reaches 0: send welcome message via CopyPacket+SendTo.
        ;
        ; MESSAGE (in-game colored text):
        ;   '%c[1,100,220,255]Welcome to the server! Have fun.'
        ;   Edit s_welcome to change text.
        ;
        ; DebugView filter: [welcome]
        ;   [welcome] new: NAME (id=X) cd=18
        ;   [welcome] sent: NAME
        ;
        ; OUTPUT: _welcome_v1.plugin
        ; -----------------------------------------------------------------------

        format PE GUI 4.0 DLL
        include '../../FASM/INCLUDE/WIN32AX.INC'
        include '../include/kglobals.inc'
        include '../include/macro.inc'
        include '../include/xrproc.inc'

section '.code' code readable writable executable
main:
        mov eax,[DllEntryPoint]

proc DllEntryPoint hinstDLL,fdwReason,lpvReserved
iglobal
        s_init  db '- [welcome] welcome_v1 loaded. delay=90s',0
endg
        mov eax,[fdwReason]
        .if eax = DLL_PROCESS_ATTACH
                stdcall API_Init
                invoke  timeSetEvent,5000,0x1000000,Welcome_Timer,NULL,1
                cinvoke xrCore.msg,s_init
        .endif
        mov eax,TRUE
        ret
endp

WELCOME_TICKS   = 18        ; 18 * 5s = 90 seconds
MAX_SLOTS       = 64

proc Welcome_Timer,uTimerID,uMsg,dwUser,dw1,dww
iglobal
        ; per-slot tracking
        seen_id     dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

        countdown   dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

        ; welcome message — color format: %c[alpha,R,G,B]
        s_welcome   db '%c[1,100,220,255]Welcome to the server! Good luck.',0
        local_buff  rb 512

        s_new       db '[welcome] new: %s (id=%d) cd=%d',0
        s_sent      db '[welcome] sent: %s',0
endg
        pushad

        xor     esi, esi
        dec     esi

.next_slot:
        inc     esi
        cmp     esi, MAX_SLOTS
        jge     .done

        stdcall [GetClientByNum], esi
        or      eax, eax
        je      .slot_empty
        mov     edi, eax

        ; client present — check if it's a new connection
        mov     eax, [edi + CLIENTCLASS.ID]
        cmp     eax, dword[seen_id + esi*4]
        je      .same_client

        ; new client in this slot
        mov     dword[seen_id + esi*4], eax
        mov     dword[countdown + esi*4], WELCOME_TICKS
        cinvoke xrCore.msg, s_new, [edi+CLIENTCLASS.addr_player_name], eax, WELCOME_TICKS
        jmp     .next_slot

.same_client:
        ; check countdown
        cmp     dword[countdown + esi*4], 0
        je      .next_slot          ; already sent or not pending

        dec     dword[countdown + esi*4]
        cmp     dword[countdown + esi*4], 0
        jne     .next_slot          ; not yet

        ; countdown hit 0 — send welcome
        cinvoke xrCore.msg, s_sent, [edi+CLIENTCLASS.addr_player_name]

        stdcall [GetClientByNum], esi
        or      eax, eax
        je      .next_slot
        mov     edi, eax

        stdcall [CopyPacket], local_buff, s_welcome
        mov     ebx, eax
        stdcall [SendTo], local_buff, ebx, [edi+CLIENTCLASS.ID]
        jmp     .next_slot

.slot_empty:
        ; clear state when slot empties (player left)
        mov     dword[seen_id + esi*4], 0
        mov     dword[countdown + esi*4], 0
        jmp     .next_slot

.done:
        popad
        ret
endp

.end main
IncludeAllGlobals
section '.reloc' fixups data writable discardable
