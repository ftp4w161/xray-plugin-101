# Local REST bridge client-validation specification

## Purpose

Define the first validation protocol between a local client tool and the ACh 7.51 server plugin. It proves that the HTTP response comes from a loaded plugin that can query live server state through `GetClientCount`.

The protocol is loopback-only in version 1. The validation client runs on the same machine as the server and uses `http://127.0.0.1:18081`.

## Plugin requirements

- Bind only to `127.0.0.1:18081`.
- Resolve `xrCore.msg` and `GetClientCount` from the loaded `xrCPU_Pipe.dll`.
- Write all startup and request/error markers using `xrCore.msg` with the `[plugin-rest]` prefix.
- Do not return player names, IP addresses, credentials, or raw game memory.
- Enforce bounded printable-ASCII input. Version 1 limits the nonce to 79 bytes.

## Endpoint

```text
GET /validation?nonce=<client-generated-ascii>
```

Success response:

```json
{
  "protocol": 1,
  "plugin": "cpp-rest-bridge",
  "nonce": "<exact client nonce>",
  "clients": 0
}
```

## Validation-client algorithm

1. Generate a random ASCII nonce of 16–32 characters.
2. Request `/health`; require HTTP 200 and `status == "ok"`.
3. Request `/validation?nonce=<nonce>`; require HTTP 200.
4. Require `protocol == 1`, `plugin == "cpp-rest-bridge"`, and an exact nonce match.
5. Require `clients` to be a non-negative integer.
6. Request `/server`; require HTTP 200 and a non-negative integer `clients` field.
7. Record endpoint output, time, plugin artifact SHA-256, server build, and matching `[plugin-rest]` server-log entries in the experiment journal.

An exact nonce echo prevents confusing an old cached response or another local program with this running plugin. It is not authentication.

## Console-message test

```text
POST /message?text=validation-ok
```

The client accepts the action only when HTTP returns `{"accepted":true}` and the server output contains:

```text
- [plugin-rest] validation-ok
```

## Security boundary and future versions

Version 1 must never be exposed beyond loopback. Before any LAN, hosting, website, or group integration, add TLS termination, authentication, request limits, an allowlist, audit logging, a deployment rollback plan, and a versioned machine-to-machine authentication protocol. A nonce alone is not authorization.
