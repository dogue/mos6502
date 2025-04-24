package mos6502

/*** Zero Page addressing - <OP> zp ***/

_set_zp_addr :: proc {
    _set_zp_addr_base,
    _set_zp_addr_offset,
}

// caches the read zero page address and sets the address bus to it
_set_zp_addr_base :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr = u16(bus.data)
    bus.addr = cpu.addr
}

// same as _set_zp_addr_base but with an offset value
_set_zp_addr_offset :: proc(cpu: ^MOS6502, bus: ^Bus, offset: u8) {
    cpu.addr = u16(u8(cpu.addr) + offset)
    bus.addr = cpu.addr
}


/*** Absolute addressing - <OP> abs ***/

_fetch_abs_lo :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _next_pc(cpu, bus)
    cpu.addr = u16(bus.data)
}

_fetch_abs_hi :: proc {
    _fetch_abs_hi_base,
    _fetch_abs_hi_offset,
}

_fetch_abs_hi_base :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr |= u16(bus.data) << 8
    bus.addr = cpu.addr
}

_fetch_abs_hi_offset :: proc(cpu: ^MOS6502, bus: ^Bus, offset: u8) -> (page_crossed: bool) {
    cpu.addr |= u16(bus.data) << 8
    base_lo := u8(cpu.addr)
    al := base_lo + offset
    ah := u8(cpu.addr >> 8)
    bus.addr = u16(ah) << 8 | u16(al)

    return al < base_lo
}


/*** Indirect Indexed addressing - <OP> (zp,x) ***/

_fetch_indx_lo :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _set_zp_addr(cpu, bus, cpu.x)
}

_fetch_indx_hi :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = (cpu.addr + 1) & 0x00FF
    cpu.addr = u16(bus.data)
}

_set_indx_addr :: proc(cpu: ^MOS6502, bus: ^Bus) {
    cpu.addr |= u16(bus.data) << 8
    bus.addr = cpu.addr
}

_fetch_indy_lo :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _set_zp_addr(cpu, bus)
}

_fetch_indy_hi :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = (cpu.addr + 1) & 0xFF
    cpu.addr = u16(bus.data)
}

_set_indy_addr :: proc(cpu: ^MOS6502, bus: ^Bus) -> (page_crossed: bool) {
    cpu.addr |= u16(bus.data) << 8
    base_lo := u8(cpu.addr)
    al := base_lo + cpu.y
    ah := u8(cpu.addr >> 8)
    bus.addr = u16(ah) << 8 | u16(al)

    // true if page crossed
    return al < base_lo
}

_fix_addr :: proc(cpu: ^MOS6502, bus: ^Bus, offset: u8) {
    bus.addr = cpu.addr + u16(offset)
}
