# Proven ACh 7.51 plugin build recipe: FASM and C++

This note records only the plugin loading/build contract verified on the XRAY / ACh 7.51 Clear Sky multiplayer server (`xrCore build 3795`). It does not document game mechanics.

## Target constraints

- Output must be a **PE32 x86 DLL**.
- Deploy the output with a `.plugin` extension directly in the server's `bin` directory.
- The first marker must use the server API, not ordinary console `WriteFile` output.
- Resolve server symbols from the already-loaded `xrCPU_Pipe.dll`.
- `xrCore.msg` is exported as a pointer to the message function, so it requires one extra dereference after `GetProcAddress`.

## Proven FASM shape

The verified loader-compatible form is:

```asm
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
        ; cinvoke xrCore.msg,marker
.endif
        mov eax,TRUE
        ret
endp

.end main
IncludeAllGlobals
section '.reloc' fixups data writable discardable
```

Do not substitute `format PE console` or `entry DllEntryPoint` for this known-working layout when targeting this server.

## Proven C++ shape

Build a static-runtime x86 DLL:

```text
cl /MT /LD /MACHINE:X86 /SUBSYSTEM:WINDOWS plugin.cpp
```

At `DLL_PROCESS_ATTACH`:

1. Call `GetModuleHandleA("xrCPU_Pipe.dll")`.
2. Call `GetProcAddress(module, "xrCore.msg")`.
3. Dereference the returned address as a `__cdecl` message-function pointer.
4. Call the message function with a unique startup marker.

The first C++ marker was confirmed on ACh 7.51. The working C++ DLL imported `KERNEL32.dll` only. A Rust DLL that also imported `VCRUNTIME140.dll` and `api-ms-win-crt-runtime-l1-1-0.dll` did not load on the same server.

## Minimum validation sequence

1. Build one plugin.
2. Verify that it is x86 PE DLL.
3. Place only that new `.plugin` directly in `bin`.
4. Start the server.
5. Confirm the unique `xrCore.msg` marker in server output or DebugView.
6. Record the artifact hash, server build, result, and any error in the experiment log.

Do not infer compatibility with another ACh/XRAY build from this recipe alone.
