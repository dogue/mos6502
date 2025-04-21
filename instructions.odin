package mos6502

_load_reg_imm :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

_load_reg_zp :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = 0 | u16(bus.data)
    case 2: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

_load_reg_zp_offset :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = u16(bus.data)
    case 2: addr := u8(bus.addr) + offset; bus.addr = u16(addr)
    case 3: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

_load_reg_abs :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = cpu.pc; cpu.pc += 1; cpu.addr = u16(bus.data)
    case 2: bus.addr = u16(bus.data) << 8 | cpu.addr
    case 3: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
    }
}

_load_reg_abs_offset :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: bus.addr = cpu.pc; cpu.pc += 1; cpu.addr = u16(bus.data)
    case 2:
        cpu.addr |= u16(bus.data) << 8
        al := u8(cpu.addr) + offset
        ah := u8(cpu.addr >> 8)
        bus.addr = u16(ah) << 8 | u16(al)
        if al >= u8(cpu.addr) do cpu.cycle += 1 // skip cycle 3 if page not crossed
    case 3: bus.addr = cpu.addr + u16(offset) // fix target addr if page was crossed
    case 4: reg^ = bus.data; set_nz(cpu, reg^); fetch(cpu, bus)
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
    case 3: cpu.addr = u16(bus.data); bus.addr += 1
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
    _load_reg_zp_offset(cpu, bus, &cpu.y, cpu.x)
}

// $B5
lda_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp_offset(cpu, bus, &cpu.a, cpu.x)
}

// $B6
ldx_zpy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp_offset(cpu, bus, &cpu.x, cpu.y)
}

// $B9
lda_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_offset(cpu, bus, &cpu.a, cpu.y)
}

// $BC
ldy_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_offset(cpu, bus, &cpu.y, cpu.x)
}

// $BD
lda_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_offset(cpu, bus, &cpu.a, cpu.x)
}

// $BE
ldx_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs_offset(cpu, bus, &cpu.x, cpu.y)
}

// $EA
nop :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: fetch(cpu, bus)
    }
}
