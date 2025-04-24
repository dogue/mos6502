package mos6502

// set a value on the data bus and pull the RW signal low
_write :: proc(bus: ^Bus, data: u8) {
    bus.data = data
    bus.ctrl -= {.RW}
}

// loads a register with an immediate value
_load_reg_imm :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    case: unreachable()
    }
}

_load_reg_zp :: proc {
    _load_reg_zp_base,
    _load_reg_zp_indexed,
}

// loads a register from a zero page address
_load_reg_zp_base :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    case: unreachable()
    }
}

// loads a register from a zero page address with offset
_load_reg_zp_indexed :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, offset)
    case 3:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    case: unreachable()
    }
}

_load_reg_abs :: proc {
    _load_reg_abs_base,
    _load_reg_abs_index,
}

// loads a register from an absolute address
_load_reg_abs_base :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    case: unreachable()
    }
}

// loads a register from an indexed absolute address
_load_reg_abs_index :: proc(cpu: ^MOS6502, bus: ^Bus, reg: ^u8, offset: u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        page_crossed := _fetch_abs_hi(cpu, bus, offset)
        if !page_crossed do cpu.cycle += 1 // skip extra cycle if page not crossed
    case 3: _adjust_addr(cpu, bus, offset) // fix target addr if page was crossed
    case 4:
        reg^ = bus.data
        set_nz(cpu, reg^)
        fetch(cpu, bus)
    case: unreachable()
    }
}

_store_reg_zp :: proc {
    _store_reg_zp_base,
    _store_reg_zp_indexed,
}

// stores a register to a zero page address
_store_reg_zp_base :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1:
        _fetch_zp_addr(cpu, bus)
        _write(bus, reg)
    case 2: fetch(cpu, bus)
    case: unreachable()
    }
}

// stores a register to an indexed zero page address
_store_reg_zp_indexed :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8, offset: u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2:
        _fetch_zp_addr(cpu, bus, offset)
        _write(bus, reg)
    case 3: fetch(cpu, bus)
    case: unreachable()
    }
}

_store_reg_abs :: proc {
    _store_reg_abs_base,
    _store_reg_abs_indexed,
}

// stores a register to an absolute address
_store_reg_abs_base :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        _fetch_abs_hi(cpu, bus)
        _write(bus, reg)
    case 3: fetch(cpu, bus)
    case: unreachable()
    }
}

_store_reg_abs_indexed :: proc(cpu: ^MOS6502, bus: ^Bus, reg: u8, offset: u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus, offset)
    case 3:
        _adjust_addr(cpu, bus, offset)
        _write(bus, reg)
    case 4: fetch(cpu, bus)
    case: unreachable()
    }
}

_transfer_reg :: proc(cpu: ^MOS6502, bus: ^Bus, src: u8, dest: ^u8) {
    switch cpu.cycle {
    case 0: _next_pc(cpu, bus)
    case 1:
        dest^ = src
        set_nz(cpu, dest^)
        fetch(cpu, bus)
    case: unreachable()
    }
}

_push_byte :: proc(cpu: ^MOS6502, bus: ^Bus, data: u8) {
    switch cpu.cycle {
    case 0: _dummy_read(cpu, bus)
    case 1:
        _set_sp_addr(cpu, bus)
        _write(bus, data)
    case 2: fetch(cpu, bus)
    case: unreachable()
    }
}

_set_sp_addr :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = 0x0100 + u16(cpu.sp)
}

_next_pc :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = cpu.pc
    cpu.pc += 1
}

_set_write :: proc(bus: ^Bus) {
    bus.ctrl -= {.RW}
}

_dummy_read :: proc(cpu: ^MOS6502, bus: ^Bus) {
    bus.addr = cpu.pc
}
