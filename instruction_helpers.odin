package mos6502

_write :: proc(bus: ^Bus, data: u8) {
    bus.data = data
    bus.ctrl -= {.RW}
}

_fetch_imm_byte :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = cpu.pc
    cpu.pc += 1
}

// Zero page addressing helpers
_fetch_zp_byte :: _fetch_imm_byte

_set_zp_addr :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr = u16(bus.data)
    bus.addr = cpu.addr
}

_set_zp_offset :: proc(cpu: ^MOS6502, bus: ^Bus, offset: u8) {
    cpu.addr = u16(u8(cpu.addr) + offset)
    bus.addr = cpu.addr
}

// Absolute addressing helpers
_fetch_abs_lo :: _fetch_imm_byte

_fetch_abs_hi :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _fetch_imm_byte(cpu, bus)
    cpu.addr = u16(bus.data)
}

_set_abs_addr :: proc {
    _set_abs_addr_no_offset,
    _set_abs_addr_offset,
}

_set_abs_addr_no_offset :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr |= u16(bus.data) << 8
    bus.addr = cpu.addr
}

_set_abs_addr_offset :: proc(cpu: ^MOS6502, bus: ^Bus, offset: u8) -> (page_crossed: bool) {
    cpu.addr |= u16(bus.data) << 8
    base_lo := u8(cpu.addr)
    al := base_lo + offset
    ah := u8(cpu.addr >> 8)
    bus.addr = u16(ah) << 8 | u16(al)

    // true if page crossed
    return al < base_lo
}

_fix_addr :: proc(cpu: ^MOS6502, bus: ^Bus, offset: u8) {
    bus.addr = cpu.addr + u16(offset)
}

_fetch_indx_lo :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _set_zp_offset(cpu, bus, cpu.x)
}

_fetch_indx_hi :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr = u16(bus.data)
    bus.addr = (bus.addr + 1) & 0x00FF
}

_set_indx_addr :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr |= u16(bus.data) << 8
    bus.addr = cpu.addr
}

_fetch_indy_lo :: _set_zp_addr

_fetch_indy_hi :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr = u16(bus.data)
    bus.addr = (bus.addr + 1) & 0x00FF
}

_set_indy_addr :: proc(cpu: ^MOS6502, bus: ^Bus) -> (page_crossed: bool) {
    return _set_abs_addr_offset(cpu, bus, cpu.y)
}

// loads a register with an immediate value
_load_reg_imm :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _fetch_imm_byte(cpu, bus)
    case 1:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    }
}

_load_reg_zp :: proc {
    _load_reg_zp_no_offset,
    _load_reg_zp_offset,
}

// loads a register from a zero page address
_load_reg_zp_no_offset :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _set_zp_addr(cpu, bus)
    case 2:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    }
}

// loads a register from a zero page address with offset
_load_reg_zp_offset :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _set_zp_addr(cpu, bus)
    case 2: _set_zp_offset(cpu, bus, offset)
    case 3:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    }
}

_load_reg_abs :: proc {
    _load_reg_abs_base,
    _load_reg_abs_offset,
}

// loads a register from an absolute address
_load_reg_abs_base :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _fetch_abs_lo(cpu, bus)
    case 1: _fetch_abs_hi(cpu, bus)
    case 2: _set_abs_addr(cpu, bus)
    case 3:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    }
}

// loads a register from an indexed absolute address
_load_reg_abs_offset :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: _fetch_abs_lo(cpu, bus)
    case 1: _fetch_abs_hi(cpu, bus)
    case 2:
        page_crossed := _set_abs_addr(cpu, bus, offset)
        if !page_crossed do cpu.cycle += 1 // skip extra cycle if page not crossed
    case 3: _fix_addr(cpu, bus, offset) // fix target addr if page was crossed
    case 4:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    }
}

_store_reg_zp :: proc {
    _store_reg_zp_base,
    _store_reg_zp_offset,
}

// stores a register to a zero page address
_store_reg_zp_base :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8) {
    switch cpu.cycle {
    case 0: _fetch_zp_byte(cpu, bus)
    case 1:
        _set_zp_addr(cpu, bus)
        _write(bus, reg)
    case 2: fetch(cpu, bus)
    }
}

// stores a register to an indexed zero page address
_store_reg_zp_offset :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8, offset: u8) {
    switch cpu.cycle {
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _set_zp_addr(cpu, bus)
    case 2:
        _set_zp_offset(cpu, bus, offset)
        _write(bus, reg)
    case 3: fetch(cpu, bus)
    }
}

_store_reg_abs :: proc {
    _store_reg_abs_base,
    _store_reg_abs_offset,
}

// stores a register to an absolute address
_store_reg_abs_base :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8) {
    switch cpu.cycle {
    case 0: _fetch_abs_lo(cpu, bus)
    case 1: _fetch_abs_hi(cpu, bus)
    case 2:
        _set_abs_addr(cpu, bus)
        _write(bus, reg)
    case 3: fetch(cpu, bus)
    }
}

_store_reg_abs_offset :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8, offset: u8) {
    switch cpu.cycle {
    case 0: _fetch_abs_lo(cpu, bus)
    case 1: _fetch_abs_hi(cpu, bus)
    case 2: _set_abs_addr(cpu, bus, offset)
    case 3: _write(bus, reg)
    case 4: fetch(cpu, bus)
    }
}

_transfer_reg :: proc(cpu: ^MOS6502, bus: ^Bus, src: u8, dest: ^u8) {
    switch cpu.cycle {
    case 0: dest^ = src
    case 1: fetch(cpu, bus)
    }
}
