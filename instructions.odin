package mos6502

import "core:fmt"

// panic helper for addressing mode helpers called outside their valid cycle window
_invalid_cycle :: proc(cpu: ^MOS6502, mode: string) {
    fmt.panicf("invalid cycle %d in %s at PC=$%4X", cpu.cycle, mode, cpu.pc)
}

// performs the first 2 cycles for zero page addressing
_addr_mode_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = u16(bus.data)
    case: _invalid_cycle(cpu, "_addr_mode_zp")
    }
}

// performs the first 3 cycles for indexed zero page addressing
_addr_mode_zp_idx :: proc(cpu: ^MOS6502, bus: ^Bus, idx: u8) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: cpu.addr = u16(bus.data); bus.addr = cpu.addr
    case 2: addr := u8(cpu.addr) + idx; bus.addr = u16(addr)
    case: _invalid_cycle(cpu, "_addr_mode_zp_idx")
    }
}

// performs the first 3 cycles for absolute addressing
_addr_mode_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = cpu.pc; cpu.pc += 1; cpu.addr = u16(bus.data)
    case 2: cpu.addr |= u16(bus.data) << 8; bus.addr = cpu.addr
    case: _invalid_cycle(cpu, "_addr_mode_abs")
    }
}

// performs the first 3 cycles for indexed absolute addressing
// returns true if the page boundary was crossed during the final cycle
_addr_mode_abs_idx :: proc(cpu: ^MOS6502, bus: ^Bus, idx: u8) -> (page_crossed: bool){
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = cpu.pc; cpu.pc += 1; cpu.addr = u16(bus.data)
    case 2:
        cpu.addr |= u16(bus.data) << 8
        base_lo := u8(cpu.addr)
        al := base_lo + idx
        ah := u8(cpu.addr >> 8)
        bus.addr = u16(ah) << 8 | u16(al)
        if al < base_lo do page_crossed = true
    case: _invalid_cycle(cpu, "_addr_mode_abs_idx")
    }

    return page_crossed
}

// loads a register with an immediate value
_load_reg_imm :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

// loads a register from a zero page address
_load_reg_zp :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _addr_mode_zp(cpu, bus)
    case 1: _addr_mode_zp(cpu, bus)
    case 2: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

// loads a register from an indexed zero page address
_load_reg_zp_idx :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: _addr_mode_zp_idx(cpu, bus, offset)
    case 1: _addr_mode_zp_idx(cpu, bus, offset)
    case 2: _addr_mode_zp_idx(cpu, bus, offset)
    case 3: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

// loads a register from an absolute address
_load_reg_abs :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _addr_mode_abs(cpu, bus)
    case 1: _addr_mode_abs(cpu, bus)
    case 2: _addr_mode_abs(cpu, bus)
    case 3: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

// loads a register from an indexed absolute address
_load_reg_abs_idx :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: _addr_mode_abs_idx(cpu, bus, offset)
    case 1: _addr_mode_abs_idx(cpu, bus, offset)
    case 2: page_crossed := _addr_mode_abs_idx(cpu, bus, offset); if !page_crossed do cpu.cycle += 1
    case 3: bus.addr = cpu.addr + u16(offset) // fix target addr if page was crossed
    case 4: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

// stores a register to a zero page address
_store_reg_zp :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8) {
    switch cpu.cycle {
    case 0: _addr_mode_zp(cpu, bus)
    case 1: _addr_mode_zp(cpu, bus); bus.data = reg; bus.ctrl -= {.RW}
    case 2: fetch(cpu, bus)
    }
}

// stores a register to an indexed zero page address
_store_reg_zp_idx :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8, offset: u8) {
    switch cpu.cycle {
    case 0: _addr_mode_zp_idx(cpu, bus, offset)
    case 1: _addr_mode_zp_idx(cpu, bus, offset)
    case 2: _addr_mode_zp_idx(cpu, bus, offset); bus.data = reg; bus.ctrl -= {.RW}
    case 3: fetch(cpu, bus)
    }
}

// stores a register to an absolute address
_store_reg_abs :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8) {
    switch cpu.cycle {
    case 0: _addr_mode_abs(cpu, bus)
    case 1: _addr_mode_abs(cpu, bus)
    case 2: _addr_mode_abs(cpu, bus); bus.data = reg; bus.ctrl -= {.RW}
    case 3: fetch(cpu, bus)
    }
}

// $18
clc :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: cpu.p -= {.Carry}
    case 1: fetch(cpu, bus)
    }
}

// $38
sec :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: cpu.p += {.Carry}
    case 1: fetch(cpu, bus)
    }
}

// $46
lsr_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _addr_mode_zp(cpu, bus)
    case 1: _addr_mode_zp(cpu, bus)
    case 2:
        bus.ctrl -= {.RW}
        set_flag(cpu, .Carry, bus.data & 1 == 1)
        bus.data >>= 1
    case 3: set_nz(cpu, bus.data)
    case 4: fetch(cpu, bus)
    }
}

// $4A
lsr_acc :: proc(cpu :^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0:
        set_flag(cpu, .Carry, cpu.a & 1 == 1)
        cpu.a >>= 1
    case 1: set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $4E
lsr_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _addr_mode_abs(cpu, bus)
    case 1: _addr_mode_abs(cpu, bus)
    case 2: _addr_mode_abs(cpu, bus)
    case 3: bus.ctrl -= {.RW}
    case 4: set_flag(cpu, .Carry, bus.data & 1 == 1); bus.data >>= 1; set_nz(cpu, bus.data)
    case 5: fetch(cpu, bus)
    }
}

// $56
lsr_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _addr_mode_zp_idx(cpu, bus, cpu.x)
    case 1: _addr_mode_zp_idx(cpu, bus, cpu.x)
    case 2: _addr_mode_zp_idx(cpu, bus, cpu.x)
    case 3: bus.ctrl -= {.RW}
    case 4: set_flag(cpu, .Carry, bus.data & 1 == 1); bus.data >>= 1; set_nz(cpu, bus.data)
    case 5: fetch(cpu, bus)
    }
}

// $58
cli :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: cpu.p -= {.Interrupt_Disable}
    case 1: fetch(cpu, bus)
    }
}

// $78
sei :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: cpu.p += {.Interrupt_Disable}
    case 1: fetch(cpu, bus)
    }
}

// $81
sta_indx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = u16(bus.data)
    case 2: addr := u8(bus.addr) + cpu.x; bus.addr = u16(addr)
    case 3: cpu.addr = u16(bus.data); bus.addr = (bus.addr + 1) & 0x00FF
    case 4: bus.addr = u16(bus.data) << 8 | cpu.addr; bus.data = cpu.a; bus.ctrl -= {.RW}
    case 5: fetch(cpu, bus)
    }
}

// $84
sty_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp(cpu, bus, cpu.y)
}

// $85
sta_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp(cpu, bus, cpu.a)
}

// $86
stx_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp(cpu, bus, cpu.x)
}

// $8C
sty_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_abs(cpu, bus, cpu.y)
}

// $8D
sta_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_abs(cpu, bus, cpu.a)
}

// $8E
stx_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_abs(cpu, bus, cpu.x)
}

// $91
sta_indy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = u16(bus.data)
    case 2: cpu.addr = u16(bus.data); bus.addr += 1
    case 3:
        cpu.addr |= u16(bus.data) << 8;
        al := u8(cpu.addr) + cpu.y
        ah := u8(cpu.addr >> 8)
        bus.addr = u16(ah) << 8 | u16(al)
        if al >= u8(cpu.addr) do cpu.cycle += 1
    case 4: bus.addr = cpu.addr + u16(cpu.y); bus.data = cpu.a; bus.ctrl -= {.RW}
    case 5: fetch(cpu, bus)
    }
}

// $94
sty_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp_idx(cpu, bus, cpu.y, cpu.x)
}

// $95
sta_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp_idx(cpu, bus, cpu.a, cpu.x)
}

// $96
stx_zpy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp_idx(cpu, bus, cpu.x, cpu.y)
}

// $99
sta_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _addr_mode_abs_idx(cpu, bus, cpu.y)
    case 1: _addr_mode_abs_idx(cpu, bus, cpu.y)
    case 2: _addr_mode_abs_idx(cpu, bus, cpu.y)
    case 3: bus.data = cpu.a; bus.ctrl -= {.RW}
    case 4: fetch(cpu, bus)
    }
}

// $9D
sta_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _addr_mode_abs_idx(cpu, bus, cpu.x)
    case 1: _addr_mode_abs_idx(cpu, bus, cpu.x)
    case 2: _addr_mode_abs_idx(cpu, bus, cpu.x)
    case 3: bus.data = cpu.a; bus.ctrl -= {.RW}
    case 4: fetch(cpu, bus)
    }
}

// $A0
ldy_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_imm(cpu, bus, &cpu.y)
}

// $A1
lda_indx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = u16(bus.data)
    case 2: addr := u8(bus.addr) + cpu.x; bus.addr = u16(addr)
    case 3: cpu.addr = u16(bus.data); bus.addr = (bus.addr + 1) & 0x00FF
    case 4: bus.addr = u16(bus.data) << 8 | cpu.addr
    case 5: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $A2
ldx_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_imm(cpu, bus, &cpu.x)
}

// $A4
ldy_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp(cpu, bus, &cpu.y)
}

// $A5
lda_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp(cpu, bus, &cpu.a)
}

// $A6
ldx_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp(cpu, bus, &cpu.x)
}

// $A9
lda_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_imm(cpu, bus, &cpu.a)
}

// $AC
ldy_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs(cpu, bus, &cpu.y)
}

// $AD
lda_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs(cpu, bus, &cpu.a)
}

// $AE
ldx_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs(cpu, bus, &cpu.x)
}

// $B1
lda_indy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = u16(bus.data)
    case 2: cpu.addr = u16(bus.data); bus.addr += 1
    case 3:
        cpu.addr |= u16(bus.data) << 8;
        al := u8(cpu.addr) + cpu.y
        ah := u8(cpu.addr >> 8)
        bus.addr = u16(ah) << 8 | u16(al)
        if al >= u8(cpu.addr) do cpu.cycle += 1
    case 4: bus.addr = cpu.addr + u16(cpu.y)
    case 5: cpu.a = bus.data; set_nz(cpu, cpu.a); fetch(cpu, bus)
    }
}

// $B4
ldy_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp_idx(cpu, bus, &cpu.y, cpu.x)
}

// $B5
lda_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp_idx(cpu, bus, &cpu.a, cpu.x)
}

// $B6
ldx_zpy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp_idx(cpu, bus, &cpu.x, cpu.y)
}

// $B9
lda_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_idx(cpu, bus, &cpu.a, cpu.y)
}

// $BC
ldy_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_idx(cpu, bus, &cpu.y, cpu.x)
}

// $BD
lda_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_idx(cpu, bus, &cpu.a, cpu.x)
}

// $BE
ldx_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_idx(cpu, bus, &cpu.x, cpu.y)
}

// $EA
nop :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: fetch(cpu, bus)
    }
}
