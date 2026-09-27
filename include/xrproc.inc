
;*******************************************************************************
proc API_Init                                                                   ; ������������� ���� api �������
iglobal
        xrCPU_Pipe               db 'xrCPU_Pipe.dll',0
        xrCPU_Pipe.dll           dd xrCPU_Pipe

        API_GetClientByNum       db 'GetClientByNum',0
        API_GetClientByID        db 'GetClientID',0
        API_GetClientByName      db 'GetClientByName',0
        API_GetClientCount       db 'GetClientCount',0
        API_SpawnObjectClient    db 'SpawnObjectClient',0
        API_xrCoreMsg            db 'xrCore.msg',0
        API_GetSection           db 'GetSection',0
        API_SendTo               db 'SendTo',0
        API__lstrlen             db '_lstrlen',0
        API_GetRandomNumber      db 'GetRandomNumber',0
        API_CopyPacket           db 'CopyPacket',0
        API_timeSetEvent         db 'timeSetEvent',0
        API_ConsoleExecute       db 'ConsoleExecute',0
        API_GetLocalClient       db 'GetLocalClient',0

api_cpu_start_ptr_addr:
                                        GetClientByNum           dd API_GetClientByNum
                                        GetClientByID            dd API_GetClientByID
                                        GetClientByName          dd API_GetClientByName
                                        GetClientCount           dd API_GetClientCount
                                        SpawnObjectClient        dd API_SpawnObjectClient
                                        GetSection               dd API_GetSection
                                        SendTo                   dd API_SendTo
                                        _lstrlen                 dd API__lstrlen
                                        GetRandomNumber          dd API_GetRandomNumber
                                        CopyPacket               dd API_CopyPacket
                                        ConsoleExecute           dd API_ConsoleExecute
                                        GetLocalClient           dd API_GetLocalClient
api_cpu_start_xrmsgs_addr:
                                        xrCore.msg               dd API_xrCoreMsg
                                        timeSetEvent             dd API_timeSetEvent
api_cpu_start_end_addr:
        PluginInitializing       db '- [XRAY] Plugin API resolved successfully!',0

        format_hex      db '%X',0
        format_dec      db '%d',0
        format_str      db '%s',0

        Buff            rb 500h
endg
        push    esi edi ebx ecx edx
        invoke  GetModuleHandle,xrCPU_Pipe
        mov     [xrCPU_Pipe.dll],eax
        mov     esi, api_cpu_start_ptr_addr
.get_proc_addr_loop:
        invoke  GetProcAddress,[xrCPU_Pipe.dll],dword[esi]
        or      eax,eax
        je      .loaded_ret
        cmp     esi,api_cpu_start_xrmsgs_addr
        jb      @f
        mov     eax, [eax]
@@:
        mov     [esi],eax
        add     esi, 4
        cmp     esi, api_cpu_start_end_addr
        jne     .get_proc_addr_loop
        cinvoke xrCore.msg,PluginInitializing
.loaded_ret:
        pop     edx ecx ebx edi esi
        ret
endp
;*******************************************************************************









struct  CLIENTCLASS
        ;-------------ID_ADDR----------
        ID                                      dd 0
        ADDR                                    dd 0
        NETADDR                                 dd 0
        BLOCKPACKET                             dd 0
        IP                                      dd 0
        PORT                                    dd 0
        ADM                                     dd 0
        ;------------NetwotrkGame------
        pConnectOK                              dd 0
        pPING                                   dd 0
        pRECIVE                                 dd 0
        pRECIVE_MAX                             dd 0
        HitStart                                dd 0
        CamOffset                               dd 0
        CamOffsetCnt                            dd 0
        ;-------------addr-------------                         
        addr_buff                               dd 0
        addr_message_buff                       dd 0
        addr_player_name                        dd 0
        addr_player_str_ip                      dd 0
        ;-------------Packet_ADD-------
        DamagePacketADD                         dd 0
        WeaponADD                               dd 0
        ClickADD                                dd 0
        RadminAuthADD                           dd 0
        FragsADD                                dd 0
        TakeADD                                 dd 0
        ActorADD                                dd 0
        WeaponByADD                             dd 0
        DropADD                                 dd 0
        PacketADD                               dd 0
        MedikADD                                dd 0
        BulletADD                               dd 0
        ActorUpdateADD                          dd 0
        CamOffsetADD                            dd 0
        TeleportTimeADD                         dd 0
        ActorReSpawnADD                         dd 0
        ActorReSpawnCountItemADD                dd 0


        DamagePacketOffset                      dd 0
        DamageAddBullet                         dd 0
        DamageBlockedHit                        dd 0

        HitClientADD                            dd 0
        HitLocalADD                             dd 0
        DamageMultiX2ADD                        dd 0
        ;-------------NetControlHit----
        HitFireStateADD                         dd 0
        HitFakeDetectADD                        dd 0
        HitOffsetYADD                           dd 0
        HitFireTimeADD                          dd 0
        FireTimeADD                             dd 0
        MultiBulletADD                          dd 0
        DamagePacketSize                        dd 0
        DamagePacketDamage                      dd 0
        HitDoublePacketADD                      dd 0
        ;-------------AntiCheat -------
        BlockHit                                dd 0
        BulletOld                               dd 0
        ClientSprint                            dd 0
        ClientTime                              dd 0
        actor_camera_y                          dd 0
        actor_update                            dd 0
        actor_state                             dd 0
        actor_pos_x                             dd 0
        actor_pos_z                             dd 0
        actor_pos_y                             dd 0
        savefrom_x                              dd 0
        savefrom_y                              dd 0
        savefrom_z                              dd 0
        detect_count                            dd 0
        jump_count                              dd 0
        KickBug                                 dd 0
        PlayerMoney                             dd 0

        ActorFrameADD                           dd 0
        FrameLagADD                             dd 0
        snap_pos_x                              dd 0
        snap_pos_z                              dd 0
        KillActorCount                          dd 0
        ;--------------Vote------------
        VoteCount                               dd 0
        VoteBlock                               dd 0
        ;------------AI learning-------
        AIModuleADD                             dd 0
        AIModuleKickADD                         dd 0
        AIModuleCountADD                        dd 0
        ;-------------Fire-------------
        FireTime                                dd 0
        FireTimeCount                           dd 0
        ;-------------Actor------------
        ActorTime                               dd 0
        ActorTeam                               dd 0
        ;-------------Time-------------
        wSecond                                 dd 0
        wMinute                                 dd 0
        wHour                                   dd 0
        CHEATERCNT                              dd 0
        ;------------------------------
        GamedataCRC                             dd 0
        ;----------AntiCheat-----------
        DamageLoop                              dd 0
        DamageBagLoop                           dd 0
        ;ControlHit                              dd 0
        AddBullet                               dd 0
        RadioCount                              dd 0
        RadioBlock                              dd 0
        ChatBlock                               dd 0
        TakeItemADD                             dd 0
        TakeArtefact                            dd 0
        DropArtefactCnt                         dd 0
        ;----------Survival------------
        SurvivalCalcArtefacts                   dd 0
        SurvivalArtefactEnter                   dd 0
        SurvivalArtefactCapturedIdx             dd 0
        ;-------------STR--------------
        StrNAME                                 rb 30h
        StrUserPass                             rb 30h
        StrID                                   rb 20h
        StrIP                                   rb 20h
        StrPort                                 rb 20h
        StrHASH                                 rb 20h+1
        StrCountry                              rb 20h
        ActorReSpawnCountSectionItemADD         rb 30h
        MessageBuff                             rb 250h
        Buff                                    rb 500h
        ;------------------------------
        Reserved                                dd 0

ends