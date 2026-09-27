
        ; _teleport_v1.asm
        ; -----------------------------------------------------------------------
        ; Config teleport replication — zone trigger → position write.
        ; Mirrors [xray_teleport] two-point entries from xray.ini.
        ;
        ; ENTRIES:
        ;   TELE_1: from -7.22/-4.11/-93.11  →  to -2.46/-3.32/74.64
        ;
        ; NOTE: single-point entries (teleport_1_mp_*) NOT in v1.
        ;   Those have no trigger zone defined in the config format.
        ;   Add them in v2 once the trigger zone coords are known.
        ;
        ; AXIS MAPPING: NORMAL XYZ (same test as _zone_v3)
        ;   ini X → PointPosX / actor_pos_x
        ;   ini Y → PointPosY / actor_pos_y  (height)
        ;   ini Z → PointPosZ / actor_pos_z
        ;
        ; TELEPORT METHOD: writes actor_pos + savefrom [UNCONFIRMED]
        ;   Same as _spawn_dynamic_v2 — confirmed working in game.
        ;
        ; TRIGGER BOX:   box_half = 5.0m
        ; COOLDOWN:      TELEPORT_CD = 10 ticks (10 seconds per slot)
        ;                Prevents ping-pong if dest is inside another trigger.
        ; TIMER:         1000ms
        ;
        ; DebugView filter: [tele]
        ;   [tele] tick N
        ;   [tele] zone1 HIT: NAME → teleporting
        ;   [tele] zone1 CD: NAME (N left)
        ;   [tele] zone1 msg sent ID XXXX
        ;
        ; OUTPUT: _teleport_v1.plugin
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
        s_init  db '- [tele] teleport_v1 loaded. zones=1 cd=%d',0
endg
        mov eax,[fdwReason]
        .if eax = DLL_PROCESS_ATTACH
                stdcall API_Init
                invoke timeSetEvent,1000,0x1000000,Tele_Timer,NULL,1
                cinvoke xrCore.msg,s_init,10
        .endif
        mov eax,TRUE
        ret
endp

TELEPORT_CD = 10        ; ticks between triggers per slot (10 seconds)

proc Tele_Timer,uTimerID,uMsg,dwUser,dw1,dww
iglobal
        ; ---------------------------------------------------------------
        ; TELE_1:
        ;   from: ini X=-7.22   Y=-4.11(h)  Z=-93.11
        ;   to:   ini X=-2.46   Y=-3.32(h)  Z=74.64
        ;
        ; NORMAL XYZ: PointPosX=iniX, PointPosY=iniY, PointPosZ=iniZ
        ; ---------------------------------------------------------------
        tele1_from_px   dd  -7.22   ; PointPosX ← ini X
        tele1_from_py   dd  -4.11   ; PointPosY ← ini Y (height)
        tele1_from_pz   dd -93.11   ; PointPosZ ← ini Z

        ; destination: normal XYZ → actor_pos_x=iniX, actor_pos_y=iniY, actor_pos_z=iniZ
        tele1_to_ax     dd  -2.46   ; actor_pos_x ← ini X
        tele1_to_ay     dd  -3.32   ; actor_pos_y ← ini Y (height)
        tele1_to_az     dd  74.64   ; actor_pos_z ← ini Z

        ; per-slot cooldown (last tick when teleport fired)
        slot_cd         dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                        dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                        dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                        dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

        g_tick          dd 0

        ; personal message on teleport
        tele_msg        db '%c[1,255,200,50]Teleport!',0
        local_buff      rb 512

        ; log strings
        s_tick          db '[tele] tick %d',0
        s_hit           db '[tele] zone1 HIT: %s -> teleporting',0
        s_cd            db '[tele] zone1 CD: %s (%d left)',0
        s_msg_sent      db '[tele] zone1 msg sent ID %d',0
        s_out           db '[tele] out: %s',0

        tmp_slot        dd 0
endg
        pushad

        inc dword[g_tick]
        cinvoke xrCore.msg,s_tick,dword[g_tick]

        xor esi,esi
        dec esi

.next:
        inc esi
        cmp esi,64
        jge .done

        stdcall [GetClientByNum],esi
        or  eax,eax
        je  .next                       ; empty slot — keep scanning
        mov edi,eax                     ; edi = CLIENTCLASS*

        ; ADDR check — null means not spawned yet
        mov eax,[edi+CLIENTCLASS.ADDR]
        or  eax,eax
        je  .next

        ; alive check via 0x8170 + byte[+0x63]
        mov eax,dword[eax+0x8170]
        or  eax,eax
        je  .next
        cmp byte[eax+0x63],4
        je  .next
        cmp byte[eax+0x63],0x0C
        je  .next

        ; --- cooldown check ---
        mov eax,dword[g_tick]
        sub eax,dword[slot_cd+esi*4]
        cmp eax,TELEPORT_CD
        jl  .on_cooldown

        ; --- zone check: TELE_1 ---
        mov [tmp_slot],esi
        stdcall GetDistancePoint,edi,[tele1_from_px],[tele1_from_py],[tele1_from_pz]
        or  eax,eax
        jne .out_of_zone

        ; === INSIDE TRIGGER ZONE: teleport ===
        cinvoke xrCore.msg,s_hit,[edi+CLIENTCLASS.addr_player_name]

        stdcall [GetClientByNum],[tmp_slot]
        or  eax,eax
        je  .next
        mov edi,eax

        ; write actor_pos (destination)
        movss xmm0,dword[tele1_to_ax]
        movss dword[edi+CLIENTCLASS.actor_pos_x],xmm0
        movss xmm0,dword[tele1_to_ay]
        movss dword[edi+CLIENTCLASS.actor_pos_y],xmm0
        movss xmm0,dword[tele1_to_az]
        movss dword[edi+CLIENTCLASS.actor_pos_z],xmm0

        ; write savefrom (same destination)
        movss xmm0,dword[tele1_to_ax]
        movss dword[edi+CLIENTCLASS.savefrom_x],xmm0
        movss xmm0,dword[tele1_to_ay]
        movss dword[edi+CLIENTCLASS.savefrom_y],xmm0
        movss xmm0,dword[tele1_to_az]
        movss dword[edi+CLIENTCLASS.savefrom_z],xmm0

        ; update cooldown
        mov eax,dword[g_tick]
        mov dword[slot_cd+esi*4],eax

        ; personal message
        mov ecx,[edi+CLIENTCLASS.ID]
        cinvoke xrCore.msg,s_msg_sent,ecx

        stdcall [GetClientByNum],[tmp_slot]
        or  eax,eax
        je  .next
        mov edi,eax

        stdcall [CopyPacket],local_buff,tele_msg
        mov ebx,eax
        stdcall [SendTo],local_buff,ebx,[edi+CLIENTCLASS.ID]

        jmp .next

.out_of_zone:
        cinvoke xrCore.msg,s_out,[edi+CLIENTCLASS.addr_player_name]
        jmp .next

.on_cooldown:
        ; eax = ticks elapsed since last trigger
        mov ecx,TELEPORT_CD
        sub ecx,eax
        cinvoke xrCore.msg,s_cd,[edi+CLIENTCLASS.addr_player_name],ecx
        jmp .next

.done:
        popad
        ret
endp

; GetDistancePoint — NORMAL XYZ order, 5m box
; PointPosX ↔ actor_pos_x, PointPosY ↔ actor_pos_y, PointPosZ ↔ actor_pos_z
; Returns 0 = inside, 1 = outside
proc GetDistancePoint, pClass, PointPosX, PointPosY, PointPosZ
iglobal
        box_half    dd 5.00
        box_full    dd 10.00
endg
        push  ebx ecx edx esi edi
        mov   edi,[pClass]

.get_x:
        movss xmm0, dword[PointPosX]
        movss xmm1, [box_half]
        addps xmm0, xmm1
        comiss xmm0,dword[edi+CLIENTCLASS.actor_pos_x]
        jb    .outside
        movss xmm1, [box_full]
        subps xmm0, xmm1
        comiss xmm0,dword[edi+CLIENTCLASS.actor_pos_x]
        ja    .outside

.get_y:
        movss xmm0, dword[PointPosY]
        movss xmm1, [box_half]
        addps xmm0, xmm1
        comiss xmm0,dword[edi+CLIENTCLASS.actor_pos_y]
        jb    .outside
        movss xmm1, [box_full]
        subps xmm0, xmm1
        comiss xmm0,dword[edi+CLIENTCLASS.actor_pos_y]
        ja    .outside

.get_z:
        movss xmm0, dword[PointPosZ]
        movss xmm1, [box_half]
        addps xmm0, xmm1
        comiss xmm0,dword[edi+CLIENTCLASS.actor_pos_z]
        jb    .outside
        movss xmm1, [box_full]
        subps xmm0, xmm1
        comiss xmm0,dword[edi+CLIENTCLASS.actor_pos_z]
        ja    .outside

.inside:
        xor   eax, eax
        jmp   .ret
.outside:
        mov   eax, 1
.ret:
        pop   edi esi edx ecx ebx
        ret
endp

.end main
IncludeAllGlobals
section '.reloc' fixups data writable discardable
