# Boot and Runtime Initialization

## Boot Stages
1. Hardware Reset
2. Bootstrap loader
3. JIT Runtime Initialization
4. Load and execute IR OS

## Memory Map
- ROM: JIT loader
- RAM: IR OS + heap
- MMIO: Device regions

## Responsibilities
- Setup stack and heap
- Load IR binary
- Start JIT loop or entrypoint
