
        ; _spawn_v6_sanitized - SAME group/odds/dispatch logic as the live _spawn_v6,
        ; with every real player nickname replaced by an obviously-fake placeholder.
        ; No behavior is changed. See _spawn_v6_spec.md alongside this file for a
        ; full walkthrough, including two known open questions this sanitized copy
        ; deliberately did NOT resolve (see spec: "Open questions").
        ;
        ; _spawn_v6 - full player group system, all suits, all players
        ; _spawn_v6 - полная система групп игроков, все костюмы, все игроки
        ; -----------------------------------------------------------------------
        ; Groups (checked in this order each spawn):
        ; Группы (проверяются в этом порядке при каждом спавне):
        ;   premium_tg_list   -> 100% TIER_HEAVY (60-65) + medkit_sci + kolbasa/conserva
        ;   patrony_list      -> 12% TIER_HEAVY / rest regular + medkit_sci
        ;   tentacle_bot_list -> bandit_outfit + 14x vodka (the bot/laptop account)
        ;   admin_list        -> bandit_outfit (the server admin account)
        ;   tester_list       -> 14x vodka_fsk [UNCONFIRMED]
        ;   special_guest_list-> gar_quest_novice_outfit + esc_quest_akm47 + kolbasa
        ;   cheater_list      -> TIER_LIGHT only / только TIER_LIGHT
        ;   spec_bf_list      -> 10% mp_exo / 45% Bulat(60) / 45% mp_mil + medkit_sci + kolbasa/conserva
        ;   wola_list         -> regular tiers + medkit_army + bread
        ;   solo_light_list       -> cs_light_outfit only / только cs_light_outfit
        ;   pro_tg_list       -> Pro armor + kolbasa/conserva
        ;   pro_list          -> Pro armor only / только Pro броня
        ;   pro_regular_list  -> Pro armor + medkit_army + bread
        ;   regular_list      -> 35/25/20/20% tiers + medkit_army + bread
        ;   default           -> 55%LIGHT/30%MID/9%mp_mil/6%mp_exo
        ;
        ; Pro armor roll (1-100): 1-6=mp_exo(40) 7-26=mp_military_stalker(30) 27-100=LIGHT
        ; Ролл брони для ПРО (1-100): 1-6=экзо(40) 7-26=военный(30) 27-100=ЛЕГКАЯ
        ;
        ; Suit pools:
        ; Пулы костюмов:
        ;   TIER_LIGHT   (7): novice, bandit, stalker, dolg, cs_light, svb_light, scientific
        ;   TIER_MID     (3): cs_heavy, specops, svb_heavy
        ;   TIER_FLICKER (2): mp_military_stalker(30,NVG), mp_exo(40,no sprint)
        ;   TIER_HEAVY   (4): dolg_heavy(60,NVG), military/Bulat(60), svoboda_exo(65), exo(65)
        ;
        ; Regular tier table (1-100 roll):
        ; Таблица тиров для обычных (ролл 1-100):
        ;    1-35  TIER_LIGHT
        ;   36-60  TIER_MID
        ;   61-80  TIER_FLICKER
        ;   81-100 TIER_HEAVY
        ;
        ; Cyrillic names stored as Win-1251 hex bytes (file-encoding-safe)
        ; Кириллические имена хранятся в hex-байтах Win-1251 (безопасно для кодировки файла)
        ;
        ; OUTPUT: _spawn_v6_sanitized.plugin
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
        mov eax,[fdwReason]
.if eax = DLL_PROCESS_ATTACH
        stdcall API_Init
        invoke timeSetEvent,500,0x1000000,Spawn_Timer,NULL,1
.endif
        mov eax,TRUE
        ret
endp

; -----------------------------------------------------------------------
; IsNameInList - exact byte match (case-sensitive)
; in:  pName = ptr to player name, pList = ptr to double-null list
; out: eax = 1 found, 0 not found
; -----------------------------------------------------------------------
proc IsNameInList, pName, pList
        push ebx ecx edi esi
        mov  esi,[pList]
.check:
        cmp  byte[esi],0
        je   .no
        mov  edi,[pName]
.cmp:
        mov  al,byte[esi]
        mov  bl,byte[edi]
        cmp  al,bl
        jne  .skip
        or   al,al
        je   .yes
        inc  esi
        inc  edi
        jmp  .cmp
.skip:
        mov  al,byte[esi]
        or   al,al
        je   .next
        inc  esi
        jmp  .skip
.next:
        inc  esi
        jmp  .check
.yes:
        pop  esi edi ecx ebx
        mov  eax,1
        ret
.no:
        pop  esi edi ecx ebx
        xor  eax,eax
        ret
endp

; -----------------------------------------------------------------------
; PickLightSuit - random from TIER_LIGHT pool (7 suits)
; out: eax = ptr to suit section string
; -----------------------------------------------------------------------
proc PickLightSuit
iglobal
        suit_novice     db 'novice_outfit',0
        suit_bandit     db 'bandit_outfit',0
        suit_stalker    db 'stalker_outfit',0
        suit_dolg       db 'dolg_outfit',0
        suit_cs_light   db 'cs_light_outfit',0
        suit_svb_light  db 'svoboda_light_outfit',0
        suit_scientific db 'scientific_outfit',0     ; NVG
endg
        stdcall [GetRandomNumber],1,7
        cmp eax,1
        je  .novice
        cmp eax,2
        je  .bandit
        cmp eax,3
        je  .stalker
        cmp eax,4
        je  .dolg
        cmp eax,5
        je  .cs_light
        cmp eax,6
        je  .svb_light
        ; 7 - scientific
        mov eax,suit_scientific
        ret
.novice:   mov eax,suit_novice
           ret
.bandit:   mov eax,suit_bandit
           ret
.stalker:  mov eax,suit_stalker
           ret
.dolg:     mov eax,suit_dolg
           ret
.cs_light: mov eax,suit_cs_light
           ret
.svb_light:mov eax,suit_svb_light
           ret
endp

; -----------------------------------------------------------------------
; PickMidSuit - random from TIER_MID pool (3 suits)
; -----------------------------------------------------------------------
proc PickMidSuit
iglobal
        suit_cs_heavy   db 'cs_heavy_outfit',0
        suit_specops    db 'specops_outfit',0
        suit_svb_heavy  db 'svoboda_heavy_outfit',0
endg
        stdcall [GetRandomNumber],1,3
        cmp eax,1
        je  .cs_heavy
        cmp eax,2
        je  .specops
        mov eax,suit_svb_heavy
        ret
.cs_heavy: mov eax,suit_cs_heavy
           ret
.specops:  mov eax,suit_specops
           ret
endp

; -----------------------------------------------------------------------
; PickFlickerSuit - random from TIER_FLICKER (2 suits)
; mp_military = NVG + flicker  |  mp_exo = flicker + NO sprint 35 armor
; -----------------------------------------------------------------------
proc PickFlickerSuit
iglobal
        suit_mp_mil     db 'mp_military_stalker_outfit',0   ; NVG
        suit_mp_exo     db 'mp_exo_outfit',0                ; no sprint - 35 armor
endg
        stdcall [GetRandomNumber],1,2
        cmp eax,1
        je  .mil
        mov eax,suit_mp_exo
        ret
.mil:   mov eax,suit_mp_mil
        ret
endp

; -----------------------------------------------------------------------
; PickHeavySuit - random from TIER_HEAVY (4 suits, equal 1/4 chance each)
;   dolg_heavy_outfit    - NVG 60 armor
;   military_outfit      - Bulat 60 armor
;   svoboda_exo_outfit   - 65 armor (SP - may fail silently in MP)
;   exo_outfit           - 65 armor (SP - may fail silently in MP)
; -----------------------------------------------------------------------
proc PickHeavySuit
iglobal
        suit_dolg_heavy db 'dolg_heavy_outfit',0
        suit_military   db 'military_outfit',0
        suit_svb_exo_h  db 'svoboda_exo_outfit',0
        suit_exo        db 'exo_outfit',0
endg
        stdcall [GetRandomNumber],1,4
        cmp eax,1
        je  .dolg
        cmp eax,2
        je  .military
        cmp eax,3
        je  .svb_exo
        mov eax,suit_exo
        ret
.dolg:    mov eax,suit_dolg_heavy
          ret
.military:mov eax,suit_military
          ret
.svb_exo: mov eax,suit_svb_exo_h
          ret
endp

; -----------------------------------------------------------------------
; StrContains - case-sensitive substring search
; in:  pHay = ptr to player name (haystack), pNeedle = ptr to keyword
; out: eax = 1 found, 0 not found
; -----------------------------------------------------------------------
proc StrContains, pHay, pNeedle
        push ebx ecx edi esi
        mov  esi,[pHay]
.outer:
        cmp  byte[esi],0
        je   .no
        mov  edi,[pNeedle]
        mov  ebx,esi
.inner:
        mov  al,byte[edi]
        or   al,al
        je   .yes          ; reached end of needle = found
        mov  cl,byte[ebx]
        or   cl,cl
        je   .next_pos     ; haystack ended before needle
        cmp  al,cl
        jne  .next_pos
        inc  edi
        inc  ebx
        jmp  .inner
.next_pos:
        inc  esi
        jmp  .outer
.yes:
        pop  esi edi ecx ebx
        mov  eax,1
        ret
.no:
        pop  esi edi ecx ebx
        xor  eax,eax
        ret
endp

; -----------------------------------------------------------------------
; GetFactionSuit - check player nick for faction keyword substrings
; Keywords (case-sensitive): [dolg]/долг, [svoboda]/свобода,
;   [ученые]/ecolog, [merc]/наемник, [bandit]/бандит,
;   [stalker]/stalker/сталкер/стрелок
; in:  pName = ptr to player name
; out: eax = ptr to suit section string, or 0 if no faction found
; -----------------------------------------------------------------------
proc GetFactionSuit, pName
iglobal
        ; Duty / Долг
        fac_kw_dolg_1    db '[dolg]',0
        fac_kw_dolg_2    db 0xE4,0xEE,0xEB,0xE3,0                           ; долг

        ; Freedom / Свобода
        fac_kw_svb_1     db '[svoboda]',0
        fac_kw_svb_2     db 0xF1,0xE2,0xEE,0xE1,0xEE,0xE4,0xE0,0           ; свобода

        ; Ecologists / Учёные  ([ученые] = 0x5B + Win-1251 cyrillic + 0x5D)
        fac_kw_sci_1     db 0x5B,0xF3,0xF7,0xE5,0xED,0xFB,0xE5,0x5D,0      ; [ученые]
        fac_kw_sci_2     db 'ecolog',0

        ; Mercenaries / Наёмники
        fac_kw_merc_1    db '[merc]',0
        fac_kw_merc_2    db 0xED,0xE0,0xE5,0xEC,0xED,0xE8,0xEA,0           ; наемник

        ; Bandits / Бандиты
        fac_kw_ban_1     db '[bandit]',0
        fac_kw_ban_2     db 0xE1,0xE0,0xED,0xE4,0xE8,0xF2,0                ; бандит

        ; Stalkers / Сталкеры
        fac_kw_stk_1     db '[stalker]',0
        fac_kw_stk_2     db 'stalker',0
        fac_kw_stk_3     db 0xF1,0xF2,0xE0,0xEB,0xEA,0xE5,0xF0,0          ; сталкер
        fac_kw_stk_4     db 0xF1,0xF2,0xF0,0xE5,0xEB,0xEE,0xEA,0          ; стрелок
endg
        ; Duty
        stdcall StrContains,[pName],fac_kw_dolg_1
        or  eax,eax
        jnz .ret_dolg
        stdcall StrContains,[pName],fac_kw_dolg_2
        or  eax,eax
        jnz .ret_dolg
        ; Freedom
        stdcall StrContains,[pName],fac_kw_svb_1
        or  eax,eax
        jnz .ret_svb
        stdcall StrContains,[pName],fac_kw_svb_2
        or  eax,eax
        jnz .ret_svb
        ; Ecologists
        stdcall StrContains,[pName],fac_kw_sci_1
        or  eax,eax
        jnz .ret_sci
        stdcall StrContains,[pName],fac_kw_sci_2
        or  eax,eax
        jnz .ret_sci
        ; Mercenaries
        stdcall StrContains,[pName],fac_kw_merc_1
        or  eax,eax
        jnz .ret_merc
        stdcall StrContains,[pName],fac_kw_merc_2
        or  eax,eax
        jnz .ret_merc
        ; Bandits
        stdcall StrContains,[pName],fac_kw_ban_1
        or  eax,eax
        jnz .ret_bandit
        stdcall StrContains,[pName],fac_kw_ban_2
        or  eax,eax
        jnz .ret_bandit
        ; Stalkers
        stdcall StrContains,[pName],fac_kw_stk_1
        or  eax,eax
        jnz .ret_stalker
        stdcall StrContains,[pName],fac_kw_stk_2
        or  eax,eax
        jnz .ret_stalker
        stdcall StrContains,[pName],fac_kw_stk_3
        or  eax,eax
        jnz .ret_stalker
        stdcall StrContains,[pName],fac_kw_stk_4
        or  eax,eax
        jnz .ret_stalker
        ; no faction found
        xor eax,eax
        ret
.ret_dolg:    mov eax,suit_dolg       ; dolg_outfit (~20 armor)
              ret
.ret_svb:     mov eax,suit_svb_light  ; svoboda_light_outfit (~25 armor)
              ret
.ret_sci:     mov eax,suit_scientific ; scientific_outfit (~15 armor, NVG)
              ret
.ret_merc:    mov eax,suit_cs_heavy   ; cs_heavy_outfit (~35 armor)
              ret
.ret_bandit:  mov eax,suit_bandit     ; bandit_outfit (~10 armor)
              ret
.ret_stalker: mov eax,suit_stalker    ; stalker_outfit (~15 armor)
              ret
endp

; -----------------------------------------------------------------------
proc Spawn_Timer,uTimerID,uMsg,dwUser,dw1,dww
iglobal
        msg_spawn   db '[v5] spawn: %s -> %s',0
        msg_bonus   db '[v5] bonus: %s -> %s',0
        msg_spec    db '[v5] spec: %s',0
        msg_addr    db '[v5] ADDR null slot %d',0

        ; VIP suit (separate label from heavy pool)
        suit_svb_exo    db 'svoboda_exo_outfit',0

        ; bonus items
        item_medkit_army    db 'medkit_army',0
        item_medkit_sci     db 'medkit_scientic',0   ; typo intentional
        item_kolbasa        db 'kolbasa',0
        item_conserva       db 'conserva',0
        item_bread          db 'bread',0
        item_energy_drink   db 'energy_drink',0

        ; special guest items [UNCONFIRMED in MP - may silently fail]
        item_quest_outfit   db 'gar_quest_novice_outfit',0
        item_quest_ak       db 'esc_quest_akm47',0

        ; tester vodka [section name UNCONFIRMED - verify in gamedata]
        item_vodka          db 'vodka',0

        ; --- Tester accounts: 14x vodka on spawn ---
        tester_list:
                db 'ExampleTester1',0
                db 'ExampleTester2',0
                db 0

        ; --- Premium+TG: 100% TIER_HEAVY (60-65) + medkit_sci + kolbasa/conserva ---
        premium_tg_list:
                db 'ExamplePremium1',0
                db 'ExamplePremium2',0
                db 0

        ; --- Patrony: 12% TIER_HEAVY / 88% regular distribution + medkit_sci ---
        ; "патроны" ~ "patrons/donaters" in the live list; placeholders here only
        patrony_list:
                db 'ExamplePatron1',0
                db 'ExamplePatron2',0
                db 0

        ; --- Wola faction lovers: regular tiers + medkit_army + bread ---
        wola_list:
                db 'ExampleWola1',0
                db 'ExampleWola2',0
                db 0

        ; --- VIP: merged into premium_tg (empty, disabled) ---
        ; vip_list:
        ;         db 0

        ; --- Server-controlled account / laptop user: bandit + 14x vodka ---
        tentacle_bot_list:
                db '@ExampleServerAccount',0
                db 0

        ; --- Admin: always bandit ---
        admin_list:
                db 'ExampleAdmin',0
                db 0

        ; --- Special Guest: quest outfit + AK [UNCONFIRMED items] ---
        special_guest_list:
                db 'ExampleGuest',0
                db 0

        ; --- Cheater: TIER_LIGHT only ---
        ; Kept ONE Cyrillic entry, hex-encoded, to illustrate the Win-1251
        ; technique the live list actually uses for non-Latin nicknames — the
        ; string itself is a generic placeholder word, not anyone's real name.
        ; Пример_Читера (Example_Cheater): П=CF р=F0 и=E8 м=EC е=E5 р=F0 _=5F
        ;   Ч=D7 и=E8 т=F2 е=E5 р=F0 а=E0
        cheater_list:
                db 'ExampleCheater1',0
                db 0xCF,0xF0,0xE8,0xEC,0xE5,0xF0,0x5F,0xD7,0xE8,0xF2,0xE5,0xF0,0xE0,0  ; Пример_Читера
                db 0

        ; --- Spec BF: Bulat(60) + Flicker only (1/3 each) ---
        spec_bf_list:
                db 'ExampleSpecBF1',0
                db 'ExampleSpecBF2',0
                db 0

        ; --- Hodaki: cs_light_outfit only ---
        solo_light_list:
                db 'ExampleHodaki',0
                db 0

        ; --- Pro+TG: Pro armor + kolbasa/conserva ---
        pro_tg_list:
                db 'ExampleProTG1',0
                db 'ExampleProTG2',0
                db 0

        ; --- Pro: Pro armor only, no bonus ---
        pro_list:
                db 'ExamplePro',0
                db 0

        ; --- Pro+Regular: Pro armor + medkit_army + bread ---
        pro_regular_list:
                db 'ExampleProRegular1',0
                db 'ExampleProRegular2',0
                db 0

        ; --- Regular+TG: Regular armor + medkit_army + bread + kolbasa ---
        regular_tg_list:
                db 'ExampleRegularTG1',0
                db 'ExampleRegularTG2',0
                db 0

        ; --- Energy: regular tiers + 10x energy_drink ---
        vodka_list:
                db 'ExampleVodka1',0
                db 'ExampleVodka2',0
                db 0

        ; --- DUO (was two friends' nicknames in the live plugin): 12% HEAVY-odds template + medkit_army + bread ---
        duo_list:
                db 'ExampleDuo1',0
                db 'ExampleDuo2',0
                db 0

        ; --- Regular: all tiers + medkit_army + bread (non-TG) ---
        ; Trimmed to 3 placeholders (live list runs to ~50 names) — the point
        ; here is the dispatch mechanism, not a full roster. One entry kept
        ; Cyrillic/hex-encoded to show that names in this list can be either.
        ; Пример_Игрок (Example_Player): П=CF р=F0 и=E8 м=EC е=E5 р=F0 _=5F
        ;   И=C8 г=E3 р=F0 о=EE к=EA
        regular_list:
                db 'ExampleRegular1',0
                db 'ExampleRegular2',0
                db 0xCF,0xF0,0xE8,0xEC,0xE5,0xF0,0x5F,0xC8,0xE3,0xF0,0xEE,0xEA,0  ; Пример_Игрок
                db 0

        ; alive flag per slot (50 slots)
        was_alive   db 0,0,0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0,0,0

        tick_count  dd 0
        pSuit       dd 0    ; temp ptr for suit to give
endg
        pushad
        inc dword[tick_count]

        mov esi,1
        dec esi

.next:
        inc esi
        stdcall [GetClientByNum],esi
        or  eax,eax
        je  .done
        mov edi,eax

        mov eax,[edi+CLIENTCLASS.ADDR]
        or  eax,eax
        je  .addr_null

        mov eax,dword[eax+0x8170]
        or  eax,eax
        je  .was_dead
        cmp byte[eax+0x63],4
        je  .was_dead
        cmp byte[eax+0x63],0x0C
        je  .was_dead

        cmp byte[was_alive+esi],1
        je  .next

        ; --- group checks in priority order ---

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],premium_tg_list
        or  eax,eax
        jne .give_premium_tg

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],patrony_list
        or  eax,eax
        jne .give_patrony

        ; vip_list disabled - merged into premium_tg

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],tentacle_bot_list
        or  eax,eax
        jne .give_tentacle_bot

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],admin_list
        or  eax,eax
        jne .give_admin

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],tester_list
        or  eax,eax
        jne .give_tester

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],special_guest_list
        or  eax,eax
        jne .give_special_guest

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],cheater_list
        or  eax,eax
        jne .give_cheater

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],spec_bf_list
        or  eax,eax
        jne .give_spec_bf

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],wola_list
        or  eax,eax
        jne .give_wola

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],solo_light_list
        or  eax,eax
        jne .give_solo_light

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],pro_tg_list
        or  eax,eax
        jne .give_pro_tg

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],pro_list
        or  eax,eax
        jne .give_pro

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],pro_regular_list
        or  eax,eax
        jne .give_pro_regular

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],regular_tg_list
        or  eax,eax
        jne .give_regular_tg

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],vodka_list
        or  eax,eax
        jne .give_vodka

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],duo_list
        or  eax,eax
        jne .give_duo

        stdcall IsNameInList,[edi+CLIENTCLASS.addr_player_name],regular_list
        or  eax,eax
        jne .give_regular

        jmp .give_default

; --- PREMIUM+TG: 100% TIER_HEAVY (dolg_heavy/Bulat/svoboda_exo/exo) + medkit_sci + kolbasa/conserva ---
.give_premium_tg:
        stdcall PickHeavySuit
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_sci
        stdcall [SpawnObjectClient],edi,item_medkit_sci
        stdcall [GetRandomNumber],1,2
        cmp eax,1
        je  .ptg_kolbasa
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_conserva
        stdcall [SpawnObjectClient],edi,item_conserva
        jmp .mark_done
.ptg_kolbasa:
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_kolbasa
        stdcall [SpawnObjectClient],edi,item_kolbasa
        jmp .mark_done

; --- PATRONY: 12% TIER_HEAVY / 35% LIGHT / 25% MID / 28% FLICKER + medkit_sci ---
; Roll 1-100: 1-35 LIGHT, 36-60 MID, 61-88 FLICKER, 89-100 HEAVY (12%)
.give_patrony:
        stdcall [GetRandomNumber],1,100
        cmp eax,35
        jbe .pat_light
        cmp eax,60
        jbe .pat_mid
        cmp eax,88
        jbe .pat_flicker
        ; 89-100 = TIER_HEAVY (12%)
        stdcall PickHeavySuit
        jmp .pat_give
.pat_light:
        stdcall PickLightSuit
        jmp .pat_give
.pat_mid:
        stdcall PickMidSuit
        jmp .pat_give
.pat_flicker:
        stdcall PickFlickerSuit
.pat_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_sci
        stdcall [SpawnObjectClient],edi,item_medkit_sci
        jmp .mark_done

; --- VIP: disabled, merged into premium_tg ---
; .give_vip: (removed)

; --- TESTER: 14x vodka_fsk [item name UNCONFIRMED] ---
.give_tester:
        cinvoke xrCore.msg,msg_spec,[edi+CLIENTCLASS.addr_player_name]
        push 14
.tester_loop:
        stdcall [SpawnObjectClient],edi,item_vodka
        dec dword[esp]
        jnz .tester_loop
        add esp,4
        jmp .mark_done

; --- SPECIAL GUEST: quest outfit + AK [UNCONFIRMED items in MP] ---
.give_special_guest:
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],item_quest_outfit
        stdcall [SpawnObjectClient],edi,item_quest_outfit
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_quest_ak
        stdcall [SpawnObjectClient],edi,item_quest_ak
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_kolbasa
        stdcall [SpawnObjectClient],edi,item_kolbasa
        jmp .mark_done

; --- TENTACLE BOT / LAPTOP: bandit + 14x vodka ---
.give_tentacle_bot:
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],suit_bandit
        stdcall [SpawnObjectClient],edi,suit_bandit
        push 14
.tbot_vodka_loop:
        stdcall [SpawnObjectClient],edi,item_vodka
        dec dword[esp]
        jnz .tbot_vodka_loop
        add esp,4
        jmp .mark_done

; --- ADMIN ---
.give_admin:
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],suit_bandit
        stdcall [SpawnObjectClient],edi,suit_bandit
        jmp .mark_done

; --- CHEATER: TIER_LIGHT only ---
.give_cheater:
        stdcall PickLightSuit
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        jmp .mark_done

; --- SPEC BF: 10% mp_exo / 45% Bulat(60) / 45% mp_mil + medkit_sci + kolbasa/conserva ---
.give_spec_bf:
        stdcall [GetRandomNumber],1,100
        cmp eax,10
        jbe .sbf_exo
        cmp eax,55
        jbe .sbf_bulat
        ; 56-100 = mp_military_stalker (45%)
        mov eax,suit_mp_mil
        jmp .sbf_give
.sbf_exo:
        mov eax,suit_mp_exo
        jmp .sbf_give
.sbf_bulat:
        mov eax,suit_military
.sbf_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_sci
        stdcall [SpawnObjectClient],edi,item_medkit_sci
        stdcall [GetRandomNumber],1,2
        cmp eax,1
        je  .sbf_kolbasa
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_conserva
        stdcall [SpawnObjectClient],edi,item_conserva
        jmp .mark_done
.sbf_kolbasa:
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_kolbasa
        stdcall [SpawnObjectClient],edi,item_kolbasa
        jmp .mark_done

; --- WOLA: regular tiers + medkit_army + bread ---
.give_wola:
        stdcall GetFactionSuit,[edi+CLIENTCLASS.addr_player_name]
        or  eax,eax
        je  .wola_roll
        mov [pSuit],eax
        jmp .wola_give
.wola_roll:
        stdcall [GetRandomNumber],1,100
        cmp eax,35
        jbe .wola_light
        cmp eax,60
        jbe .wola_mid
        cmp eax,80
        jbe .wola_flicker
        stdcall PickHeavySuit
        jmp .wola_give
.wola_light:
        stdcall PickLightSuit
        jmp .wola_give
.wola_mid:
        stdcall PickMidSuit
        jmp .wola_give
.wola_flicker:
        stdcall PickFlickerSuit
.wola_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_army
        stdcall [SpawnObjectClient],edi,item_medkit_army
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_bread
        stdcall [SpawnObjectClient],edi,item_bread
        jmp .mark_done

; --- SOLO_LIGHT (was a single-nickname group in the live plugin): cs_light_outfit only ---
.give_solo_light:
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],suit_cs_light
        stdcall [SpawnObjectClient],edi,suit_cs_light
        jmp .mark_done

; --- PRO+TG: Pro armor + kolbasa/conserva ---
; 74% LIGHT / 20% mp_military_stalker(30) / 6% mp_exo(40)
.give_pro_tg:
        stdcall [GetRandomNumber],1,100
        cmp eax,6
        jbe .pro_tg_exo
        cmp eax,26
        jbe .pro_tg_mp_mil
        ; 27-100 LIGHT (74%)
        stdcall PickLightSuit
        jmp .pro_tg_give
.pro_tg_exo:
        mov eax,suit_mp_exo
        jmp .pro_tg_give
.pro_tg_mp_mil:
        mov eax,suit_mp_mil
.pro_tg_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        stdcall [GetRandomNumber],1,2
        cmp eax,1
        je  .pro_tg_kolbasa
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_conserva
        stdcall [SpawnObjectClient],edi,item_conserva
        jmp .mark_done
.pro_tg_kolbasa:
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_kolbasa
        stdcall [SpawnObjectClient],edi,item_kolbasa
        jmp .mark_done

; --- PRO: 74% LIGHT / 20% mp_military_stalker(30) / 6% mp_exo(40) ---
.give_pro:
        stdcall [GetRandomNumber],1,100
        cmp eax,6
        jbe .pro_exo
        cmp eax,26
        jbe .pro_mp_mil
        ; 27-100 LIGHT (74%)
        stdcall PickLightSuit
        jmp .pro_give
.pro_exo:
        mov eax,suit_mp_exo
        jmp .pro_give
.pro_mp_mil:
        mov eax,suit_mp_mil
.pro_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        jmp .mark_done

; --- PRO+REGULAR: Pro armor + medkit_army + bread ---
; 74% LIGHT / 20% mp_military_stalker(30) / 6% mp_exo(40)
.give_pro_regular:
        stdcall [GetRandomNumber],1,100
        cmp eax,6
        jbe .prr_exo
        cmp eax,26
        jbe .prr_mp_mil
        ; 27-100 LIGHT (74%)
        stdcall PickLightSuit
        jmp .prr_give
.prr_exo:
        mov eax,suit_mp_exo
        jmp .prr_give
.prr_mp_mil:
        mov eax,suit_mp_mil
.prr_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_army
        stdcall [SpawnObjectClient],edi,item_medkit_army
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_bread
        stdcall [SpawnObjectClient],edi,item_bread
        jmp .mark_done

; --- REGULAR+TG: Regular armor + medkit_army + bread + kolbasa ---
.give_regular_tg:
        stdcall GetFactionSuit,[edi+CLIENTCLASS.addr_player_name]
        or  eax,eax
        je  .rtg_roll
        mov [pSuit],eax
        jmp .rtg_give
.rtg_roll:
        stdcall [GetRandomNumber],1,100
        cmp eax,35
        jbe .rtg_light
        cmp eax,60
        jbe .rtg_mid
        cmp eax,80
        jbe .rtg_flicker
        stdcall PickHeavySuit
        jmp .rtg_give
.rtg_light:
        stdcall PickLightSuit
        jmp .rtg_give
.rtg_mid:
        stdcall PickMidSuit
        jmp .rtg_give
.rtg_flicker:
        stdcall PickFlickerSuit
.rtg_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_sci
        stdcall [SpawnObjectClient],edi,item_medkit_sci
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_bread
        stdcall [SpawnObjectClient],edi,item_bread
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_kolbasa
        stdcall [SpawnObjectClient],edi,item_kolbasa
        jmp .mark_done

; --- ENERGY: regular tiers + 10x energy_drink ---
.give_vodka:
        stdcall [GetRandomNumber],1,100
        cmp eax,35
        jbe .vdk_light
        cmp eax,60
        jbe .vdk_mid
        cmp eax,80
        jbe .vdk_flicker
        stdcall PickHeavySuit
        jmp .vdk_give
.vdk_light:
        stdcall PickLightSuit
        jmp .vdk_give
.vdk_mid:
        stdcall PickMidSuit
        jmp .vdk_give
.vdk_flicker:
        stdcall PickFlickerSuit
.vdk_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        push 10
.vdk_loop:
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_energy_drink
        stdcall [SpawnObjectClient],edi,item_energy_drink
        dec dword[esp]
        jnz .vdk_loop
        add esp,4
        jmp .mark_done

; --- BIBA/BOBA: 35% LIGHT / 25% MID / 28% FLICKER / 12% HEAVY + medkit_army + bread ---
; Roll table: 1-35 LIGHT / 36-60 MID / 61-88 FLICKER / 89-100 HEAVY (12%)
.give_duo:
        stdcall GetFactionSuit,[edi+CLIENTCLASS.addr_player_name]
        or  eax,eax
        je  .bb_roll
        mov [pSuit],eax
        jmp .bb_give
.bb_roll:
        stdcall [GetRandomNumber],1,100
        cmp eax,35
        jbe .bb_light
        cmp eax,60
        jbe .bb_mid
        cmp eax,88
        jbe .bb_flicker
        ; 89-100 TIER_HEAVY (12%)
        stdcall PickHeavySuit
        jmp .bb_give
.bb_light:
        stdcall PickLightSuit
        jmp .bb_give
.bb_mid:
        stdcall PickMidSuit
        jmp .bb_give
.bb_flicker:
        stdcall PickFlickerSuit
.bb_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_army
        stdcall [SpawnObjectClient],edi,item_medkit_army
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_bread
        stdcall [SpawnObjectClient],edi,item_bread
        jmp .mark_done

; --- REGULAR: all tiers + medkit_army + bread ---
.give_regular:
        stdcall GetFactionSuit,[edi+CLIENTCLASS.addr_player_name]
        or  eax,eax
        je  .reg_roll
        mov [pSuit],eax
        jmp .reg_give
.reg_roll:
        stdcall [GetRandomNumber],1,100
        cmp eax,35
        jbe .reg_light
        cmp eax,60
        jbe .reg_mid
        cmp eax,80
        jbe .reg_flicker
        ; 81-100 TIER_HEAVY
        stdcall PickHeavySuit
        jmp .reg_give
.reg_light:
        stdcall PickLightSuit
        jmp .reg_give
.reg_mid:
        stdcall PickMidSuit
        jmp .reg_give
.reg_flicker:
        stdcall PickFlickerSuit
.reg_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_medkit_army
        stdcall [SpawnObjectClient],edi,item_medkit_army
        cinvoke xrCore.msg,msg_bonus,[edi+CLIENTCLASS.addr_player_name],item_bread
        stdcall [SpawnObjectClient],edi,item_bread
        jmp .mark_done

; --- DEFAULT: 55% LIGHT / 30% MID / 9% mp_military_stalker / 6% mp_exo ---
.give_default:
        stdcall [GetRandomNumber],1,100
        cmp eax,6
        jbe .def_exo
        cmp eax,61
        jbe .def_light
        cmp eax,91
        jbe .def_mid
        ; 92-100 mp_military_stalker (9%)
        mov eax,suit_mp_mil
        jmp .def_give
.def_exo:
        mov eax,suit_mp_exo
        jmp .def_give
.def_light:
        stdcall PickLightSuit
        jmp .def_give
.def_mid:
        stdcall PickMidSuit
.def_give:
        mov [pSuit],eax
        cinvoke xrCore.msg,msg_spawn,[edi+CLIENTCLASS.addr_player_name],[pSuit]
        stdcall [SpawnObjectClient],edi,[pSuit]

.mark_done:
        mov byte[was_alive+esi],1
        jmp .next

.was_dead:
        mov byte[was_alive+esi],0
        ; throttle spec log - every 200 ticks (~100 sec)
        mov eax,[tick_count]
        mov ecx,200
        xor edx,edx
        div ecx
        or  edx,edx
        jne .next
        cinvoke xrCore.msg,msg_spec,[edi+CLIENTCLASS.addr_player_name]
        jmp .next

.addr_null:
        cinvoke xrCore.msg,msg_addr,esi
        jmp .done

.done:
        popad
        ret
endp

.end main
IncludeAllGlobals
section '.reloc' fixups data writable discardable
