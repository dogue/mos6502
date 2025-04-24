package mos6502

import "core:fmt"

RESET_VECTOR :: 0xFFFC

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
	ir: Instruction,
	in_reset: bool,
}

init :: proc(cpu: ^MOS6502) -> Bus {
    cpu.in_reset = true
    return Bus {
        ctrl = {.RW, .RUN}
    }
}

fetch :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = cpu.pc
    bus.ctrl += {.SYNC, .RW}
}

tick :: proc(cpu: ^MOS6502, bus: ^Bus) {
    if .RUN not_in bus.ctrl do return
    defer cpu.cycle += 1

    if cpu.in_reset {
        reset(cpu, bus)
        return
    }

    if .SYNC in bus.ctrl {
        cpu.cycle = 0
        cpu.ir = OP[bus.data]
        bus.ctrl -= {.SYNC}
        cpu.pc += 1
    }


	if cpu.ir == nil {
		fmt.panicf("unhandled opcode: $%2X at $%4X", bus.data, bus.addr)
	}

	cpu->ir(bus)
}

set_nz :: proc(cpu: ^MOS6502, val: u8) {
    set_flag(cpu, .Zero, val == 0)
    set_flag(cpu, .Negative, val & 0x80 != 0)
}

reset :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = 0x00FF
    case 1: bus.addr = 0x0100; cpu.sp -= 1
    case 2: cpu.sp -= 1
    case 3: bus.addr = RESET_VECTOR; cpu.sp -= 1
    case 4: cpu.pc = u16(bus.data); bus.addr += 1
    case 5: cpu.pc |= u16(bus.data) << 8
    case 6: cpu.in_reset = false; fetch(cpu, bus)
    }
}

set_flag :: proc {
    set_flag_,
    set_flag_cond,
}

set_flag_ :: proc(cpu: ^MOS6502, flag: Status_Flag) {
    cpu.p += {flag}
}

set_flag_cond :: proc(cpu: ^MOS6502, flag: Status_Flag, cond: bool) {
    if cond {
        cpu.p += {flag}
    } else {
        cpu.p -= {flag}
    }
}

clear_flag :: proc(cpu: ^MOS6502, flag: Status_Flag) {
    cpu.p -= {flag}
}

Instruction :: #type proc(cpu: ^MOS6502, bus: ^Bus)
OP: [256]Instruction
@(init)
init_instruction_table :: proc() {
    OP[0x18] = clc
    OP[0x38] = sec
    OP[0x46] = lsr_zp
    OP[0x4A] = lsr_acc
    OP[0x56] = lsr_zpx
    OP[0x58] = cli
    OP[0x78] = sei
    OP[0x81] = sta_indx
    OP[0x84] = sty_zp
    OP[0x85] = sta_zp
    OP[0x86] = stx_zp
    OP[0x8C] = sty_abs
    OP[0x8D] = sta_abs
    OP[0x8E] = stx_abs
    OP[0x91] = sta_indy
    OP[0x94] = sty_zpx
    OP[0x95] = sta_zpx
    OP[0x96] = stx_zpy
    OP[0x99] = sta_absy
    OP[0x9D] = sta_absx
    OP[0xA0] = ldy_imm
    OP[0xA1] = lda_indx
    OP[0xA2] = ldx_imm
    OP[0xA4] = ldy_zp
    OP[0xA5] = lda_zp
    OP[0xA6] = ldx_zp
    OP[0xA9] = lda_imm
    OP[0xAC] = ldy_abs
    OP[0xAD] = lda_abs
    OP[0xAE] = ldx_abs
    OP[0xB1] = lda_indy
    OP[0xB4] = ldy_zpx
    OP[0xB5] = lda_zpx
    OP[0xB6] = ldx_zpy
    OP[0xB9] = lda_absy
    OP[0xBC] = ldy_absx
    OP[0xBD] = lda_absx
    OP[0xBE] = ldx_absy
    OP[0xEA] = nop
}
