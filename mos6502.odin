package mos6502

import "core:fmt"

RESET_VECTOR :: 0xFFFC
RESET_ACTIVE: bool

Status_Flag :: enum {
    Carry,
    Zero,
    Interrupt_Disable,
    Decimal_Mode,
    Break,
    Overflow,
    Negative,
}
Status_Flags :: bit_set[Status_Flag]

MOS6502 :: struct {
	a, x, y, sp: u8,
	p: Status_Flags,
	pc: u16,
	cycle: int,
	addr: u16,
	ir: proc(^MOS6502, ^Bus)
}

init :: proc(cpu: ^MOS6502) -> Bus {
    RESET_ACTIVE = true
    return Bus {
        ctrl = {.RW, .RUN}
    }
}

fetch :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = cpu.pc
    cpu.pc += 1
    bus.ctrl += {.SYNC, .RW}
}

tick :: proc(cpu: ^MOS6502, bus: ^Bus) {
    if .RUN not_in bus.ctrl do return
    defer cpu.cycle += 1

    if RESET_ACTIVE {
        reset(cpu, bus)
        return
    }

    if .SYNC in bus.ctrl {
        cpu.cycle = 0
        cpu.ir = OP[bus.data]
        bus.ctrl -= {.SYNC}
    }

	if cpu.ir == nil {
		fmt.panicf("unhandled opcode: $%2X at $%4X", bus.data, bus.addr)
	}

	cpu->ir(bus)
}

set_nz :: proc(cpu: ^MOS6502, val: u8) {
    if val == 0 {
        cpu.p += {.Zero}
    } else {
        cpu.p -= {.Zero}
    }

    if val & 0x80 != 0 {
        cpu.p += {.Negative}
    } else {
        cpu.p -= {.Negative}
    }
}

reset :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = 0x00FF
    case 1: bus.addr = 0x0100; cpu.sp -= 1
    case 2: cpu.sp -= 1
    case 3: bus.addr = RESET_VECTOR; cpu.sp -= 1
    case 4: cpu.pc = u16(bus.data); bus.addr += 1
    case 5: cpu.pc |= u16(bus.data) << 8
    case 6: RESET_ACTIVE = false; fetch(cpu, bus)
    }
}

// $A5
lda_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = 0 | u16(bus.data)
    case 2: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $A9
lda_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $AD
lda_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = cpu.pc; cpu.pc += 1; cpu.addr = u16(bus.data)
    case 2: bus.addr = u16(bus.data) << 8 | cpu.addr
    case 3: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $B5
lda_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = u16(bus.data)
    case 2: addr := u8(bus.addr) + cpu.x; bus.addr = u16(addr)
    case 3: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $B9
lda_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = cpu.pc; cpu.pc += 1; cpu.addr = u16(bus.data)
    case 2:
        cpu.addr |= u16(bus.data) << 8
        al := u8(cpu.addr) + cpu.y
        ah := u8(cpu.addr >> 8)
        bus.addr = u16(ah) << 8 | u16(al)
        if al >= u8(cpu.addr) do cpu.cycle += 1 // skip cycle 3 if page not crossed
    case 3: bus.addr = cpu.addr + u16(cpu.y) // fix target addr if page was crossed
    case 4: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $BD
lda_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = cpu.pc; cpu.pc += 1; cpu.addr = u16(bus.data)
    case 2:
        cpu.addr |= u16(bus.data) << 8
        al := u8(cpu.addr) + cpu.x
        ah := u8(cpu.addr >> 8)
        bus.addr = u16(ah) << 8 | u16(al)
        if al >= u8(cpu.addr) do cpu.cycle += 1 // skip cycle 3 if page not crossed
    case 3: bus.addr = cpu.addr + u16(cpu.x) // fix target addr if page was crossed
    case 4: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $EA
nop :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: fetch(cpu, bus)
    }
}

OP: [256]proc(^MOS6502, ^Bus)
@(init)
init_instruction_table :: proc() {
    OP[0xA5] = lda_zp
    OP[0xA9] = lda_imm
    OP[0xAD] = lda_abs
    OP[0xB5] = lda_zpx
    OP[0xB9] = lda_absy
    OP[0xBD] = lda_absx
    OP[0xEA] = nop
}
