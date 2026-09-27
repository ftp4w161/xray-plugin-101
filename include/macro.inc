macro _invoke proc,[arg]
       { 
        common 
        stdcall [proc],arg 
       } 



struc db [data]
       {
         common
         label .data byte
         db data
         .size = $-1-.data
       }



struc rb [data]
       {
         common
         label .data byte
         rb data
         .size = $-.data
       } 






      macro push_all
      {
        pushad
      }

     ; на вершину стека запишем значение еах, после popad будет наше записанное значение
      macro pop_all
      {
        mov [esp+0x1C],eax
        popad
      }










macro proc [args]                       ; define procedure
 { common
    match name params, args>
    \{ define@proc name,<params \} }

prologue@proc equ prologuedef

macro prologuedef procname,flag,parmbytes,localbytes,reglist
 { local loc
   loc = (localbytes+3) and (not 3)
   parmbase@proc equ ebp+8
   localbase@proc equ ebp-loc
   if parmbytes | localbytes
   ;mov edi,edi
       ;db 0x8D,0x80,0x00,0x00,0x00,0x00   ;mov edi,edi
        ; db 0x05,0x00,0x00,0x00,0x00,0x90

    push ebp
    mov ebp,esp
    if localbytes
     sub esp,loc
    end if
   end if
   irps reg, reglist \{ push reg \} }

epilogue@proc equ epiloguedef








macro export1 dllname,[label,string]
{ common
    local module,addresses,names,ordinal,count
    count = 0
   forward
    count = count+1
   common
    dd 0,0,0,rva module,1
    dd count,count,rva addresses,rva names,rva ordinal
    addresses:
   forward
    dd rva label
   common
    names:
   forward
    local name
    dd rva name
   common
    ordinal: count = 0
   forward
    dw count
    count = count+1
   common
    module db dllname,0
   forward
    name db string,0}






macro exportByOrdinals dllname*,[label,string,ordinal]
{
    common
        local dllnameptr,functions,names,ordinals,NumberOfFunctions,NumberOfNames,\
                minOrdinal,maxOrdinal,buf
        NumberOfFunctions = 0
        NumberOfNames = 0
    forward
        NumberOfFunctions = NumberOfFunctions + 1
        if ~ string eq
            NumberOfNames = NumberOfNames+1
        end if
        if ~ ordinal eq
            if ~ defined maxOrdinal | defined @F
                @@:
                minOrdinal = ordinal
                maxOrdinal = ordinal
            else
                if ordinal<minOrdinal
                    minOrdinal = ordinal
                end if
                if ordinal>maxOrdinal
                    maxOrdinal = ordinal
                end if
            end if
        end if
    common
        if ~ defined maxOrdinal
            minOrdinal = 1
        else
            if maxOrdinal-minOrdinal+1 > NumberOfFunctions
                NumberOfFunctions = maxOrdinal-minOrdinal+1
            end if
        end if
       
        dd 0,0,0,RVA dllnameptr,minOrdinal
        dd NumberOfFunctions,NumberOfNames,RVA functions,RVA names,RVA ordinals
       
        functions: times NumberOfFunctions dd 0
    forward
        ;only functions with an explicitly specified ordinal are saved here
        if ~ ordinal eq
            load buf dword from functions+(ordinal-minOrdinal)*4
            if buf
                display 'Error: ordinal ' # `ordinal # ' redefinition',13,10
                err
            end if
            store dword RVA label at functions+(ordinal-minOrdinal)*4
        end if
    common
        names:
    forward
        local name
        if ~ string eq
            dd RVA name
        end if
    common
        ordinals:
    forward
        ;only functions without an explicitly specified ordinal are saved here
        if ordinal eq
            repeat NumberOfFunctions
                load buf dword from functions+(%-1)*4
                if ~ buf
                    store dword RVA label at functions+(%-1)*4
                    if ~ string eq
                        dw %-1
                    end if
                    break
                end if
            end repeat
        else
            if ~ string eq
                dw ordinal-minOrdinal
            end if
        end if
    common
        dllnameptr db dllname,0
    forward
        if ~ string eq
            name db string,0
        end if
    common
        local x,y,z,str1,str2,v1,v2
 
        x = NumberOfNames shr 1
        while x > 0
            y = x
            while y < NumberOfNames
                z = y
                while z-x >= 0
                    load v1 dword from names+z*4
                    str1=($-RVA $)+v1
                    load v2 dword from names+(z-x)*4
                    str2=($-RVA $)+v2
                    while v1 > 0
                        load v1 from str1+%-1
                        load v2 from str2+%-1
                        if v1 <> v2
                            break
                        end if
                    end while
                    if v1<v2
                        load v1 dword from names+z*4
                        load v2 dword from names+(z-x)*4
                        store dword v1 at names+(z-x)*4
                        store dword v2 at names+z*4
                        load v1 word from ordinals+z*2
                        load v2 word from ordinals+(z-x)*2
                        store word v1 at ordinals+(z-x)*2
                        store word v2 at ordinals+z*2
                    else
                        break
                    end if
                    z = z-x
                end while
                y = y+1
            end while
            x = x shr 1
        end while
}










