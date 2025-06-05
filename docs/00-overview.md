# Project Overview

This project explores a novel operating system architecture where the core OS is compiled to an extended intermediate representation (IR), and executed by a bare-metal JIT (Just-In-Time) compiler.

## Goals
- Provide architecture abstraction via IR
- Execute on bare-metal with a lightweight JIT engine
- Enable OS portability and security

## Scope
- JIT runtime booted directly from firmware/ROM
- IR-based OS kernel and drivers
- Minimal or no reliance on traditional ISAs
For full details, see [`ir-spec.md`](ir-spec.md).
