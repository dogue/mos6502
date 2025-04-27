package mos6502

// Instruction set implementation
// procs prefixed with `_` are helpers defined in `*_helpers.odin`

// $01
ora_indx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_indx_ptr_lo(cpu, bus)
    case 3: _fetch_indx_ptr_hi(cpu, bus)
    case 4: _compute_indx_addr(cpu, bus)
    case 5:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $05
ora_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $06
asl_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _begin_rmw(cpu, bus)
    case 3:
        data := u8(cpu.addr)
        set_flag(cpu, .Carry, (data & 0x80) != 0)
        data <<= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 4: _sync(cpu, bus)
    case: unreachable()
    }
}

// $08
php :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1: _write_stack(cpu, bus, transmute(u8)(cpu.p))
    case 2: _sync(cpu, bus)
    case: unreachable()
    }
}

// $09
ora_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $OA
asl_acc :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        set_flag(cpu, .Carry, (cpu.a & 0x80) != 0)
        cpu.a <<= 1
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $0D
ora_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $0E
asl_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        set_flag(cpu, .Carry, (data & 0x80) != 0)
        data <<= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $11
ora_indy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_indy_ptr_lo(cpu, bus)
    case 2: _fetch_indy_ptr_hi(cpu, bus)
    case 3:
        page_crossed := _compute_indy_addr(cpu, bus)
        if !page_crossed do cpu.cycle += 1
    case 4: _adjust_addr(cpu, bus, cpu.y)
    case 5:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $15
ora_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $16
asl_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        set_flag(cpu, .Carry, (data & 0x80) != 0)
        data <<= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $18
clc :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        clear_flag(cpu, .Carry)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $19
ora_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        page_crossed := _fetch_abs_hi(cpu, bus, cpu.y)
        if !page_crossed do cpu.cycle += 1
    case 3: _adjust_addr(cpu, bus, cpu.y)
    case 4:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $1D
ora_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        page_crossed := _fetch_abs_hi(cpu, bus, cpu.x)
        if !page_crossed do cpu.cycle += 1
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4:
        cpu.a |= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $1E
asl_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus, cpu.x)
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4: _begin_rmw(cpu, bus)
    case 5:
        data := u8(cpu.addr)
        set_flag(cpu, .Carry, (data & 0x80) != 0)
        data <<= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 6: _sync(cpu, bus)
    case: unreachable()
    }
}

// $21
and_indx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_indx_ptr_lo(cpu, bus)
    case 3: _fetch_indx_ptr_hi(cpu, bus)
    case 4: _compute_indx_addr(cpu, bus)
    case 5:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $24
bit_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2:
        set_flag(cpu, .Zero, (cpu.a & bus.data) == 0)
        set_flag(cpu, .Overflow, (bus.data & (1 << 6)) != 0)
        set_flag(cpu, .Negative, (bus.data & (1 << 7)) != 0)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $25
and_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $26
rol_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _begin_rmw(cpu, bus)
    case 3:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _rol(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 4: _sync(cpu, bus)
    case: unreachable()
    }
}

// $28
plp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1: _pull_stack(cpu, bus)
    case 2: _read_stack(cpu, bus)
    case 3:
        cpu.p = transmute(Status_Flags)(bus.data)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $29
and_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $2A
rol_acc :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        data := cpu.a
        carry := .Carry in cpu.p
        data, carry = _rol(data, carry)
        cpu.a = data
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $2C
bit_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3:
        set_flag(cpu, .Zero, (cpu.a & bus.data) == 0)
        set_flag(cpu, .Overflow, (bus.data & (1 << 6)) != 0)
        set_flag(cpu, .Negative, (bus.data & (1 << 7)) != 0)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $2D
and_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $2E
rol_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _rol(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $31
and_indy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_indy_ptr_lo(cpu, bus)
    case 2: _fetch_indy_ptr_hi(cpu, bus)
    case 3:
        page_crossed := _compute_indy_addr(cpu, bus)
        if !page_crossed do cpu.cycle += 1
    case 4: _adjust_addr(cpu, bus, cpu.y)
    case 5:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $35
and_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $36
rol_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _rol(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $38
sec :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        set_flag(cpu, .Carry)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $39
and_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        page_crossed := _fetch_abs_hi(cpu, bus, cpu.y)
        if !page_crossed do cpu.cycle += 1
    case 3: _adjust_addr(cpu, bus, cpu.y)
    case 4:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $3D
and_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        page_crossed := _fetch_abs_hi(cpu, bus, cpu.x)
        if !page_crossed do cpu.cycle += 1
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4:
        cpu.a &= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $3E
rol_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus, cpu.x)
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4: _begin_rmw(cpu, bus)
    case 5:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _rol(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 6: _sync(cpu, bus)
    case: unreachable()
    }
}

// $41
eor_indx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_indx_ptr_lo(cpu, bus)
    case 3: _fetch_indx_ptr_hi(cpu, bus)
    case 4: _compute_indx_addr(cpu, bus)
    case 5:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $45
eor_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $46
lsr_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _begin_rmw(cpu, bus)
    case 3:
        data := u8(cpu.addr)
        set_flag(cpu, .Carry, (data & 1) == 1)
        data >>= 1
        set_nz(cpu, data)
        bus.data = data
        _set_write(bus)
    case 4: _sync(cpu, bus)
    case: unreachable()
    }
}

// $48
pha :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1: _write_stack(cpu, bus, cpu.a)
    case 2: _sync(cpu, bus)
    case: unreachable()
    }
}

// $49
eor_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $4A
lsr_acc :: proc(cpu :^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        set_flag(cpu, .Carry, (cpu.a & 1) == 1)
        cpu.a >>= 1
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $4D
eor_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $4E
lsr_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        set_flag(cpu, .Carry, (cpu.addr & 1) == 1)
        cpu.addr >>= 1
        set_nz(cpu, u8(cpu.addr))
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $51
eor_indy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_indy_ptr_lo(cpu, bus)
    case 2: _fetch_indy_ptr_hi(cpu, bus)
    case 3:
        page_crossed := _compute_indy_addr(cpu, bus)
        if !page_crossed do cpu.cycle += 1
    case 4: _adjust_addr(cpu, bus, cpu.y)
    case 5:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $55
eor_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $56
lsr_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        set_flag(cpu, .Carry, (cpu.addr & 1) == 1)
        cpu.addr >>= 1
        set_nz(cpu, u8(cpu.addr))
        _write(bus, u8(cpu.addr))
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $58
cli :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        clear_flag(cpu, .Interrupt_Disable)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $59
eor_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        page_crossed := _fetch_abs_hi(cpu, bus, cpu.y)
        if !page_crossed do cpu.cycle += 1
    case 3: _adjust_addr(cpu, bus, cpu.y)
    case 4:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $5D
eor_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2:
        page_crossed := _fetch_abs_hi(cpu, bus, cpu.x)
        if !page_crossed do cpu.cycle += 1
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4:
        cpu.a ~= bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $66
ror_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _begin_rmw(cpu, bus)
    case 3:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _ror(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 4: _sync(cpu, bus)
    case: unreachable()
    }
}

// $68
pla :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1: _pull_stack(cpu, bus)
    case 2: _read_stack(cpu, bus)
    case 3:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $6A
ror_acc :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        data := cpu.a
        carry := .Carry in cpu.p
        data, carry = _ror(data, carry)
        cpu.a = data
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $6E
ror_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _ror(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $76
ror_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _ror(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $78
sei :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        set_flag(cpu, .Interrupt_Disable)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $7E
ror_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus, cpu.x)
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4: _begin_rmw(cpu, bus)
    case 5:
        data := u8(cpu.addr)
        carry := .Carry in cpu.p
        data, carry = _ror(data, carry)
        set_flag(cpu, .Carry, carry)
        set_nz(cpu, data)
        _write(bus, data)
    case 6: _sync(cpu, bus)
    case: unreachable()
    }
}

// $81 - STA (zp,X)
sta_indx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_indx_ptr_lo(cpu, bus)
    case 3: _fetch_indx_ptr_hi(cpu, bus)
    case 4:
        _compute_indx_addr(cpu, bus)
        _write(bus, cpu.a)
    case 5: _sync(cpu, bus)
    case: unreachable()
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

// $88
dey :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        cpu.y -= 1
        set_nz(cpu, cpu.y)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $8A
txa :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _transfer_reg(cpu, bus, cpu.x, &cpu.a)
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
    case 0: _fetch(cpu, bus)
    case 1: _fetch_indy_ptr_lo(cpu, bus)
    case 2: _fetch_indy_ptr_hi(cpu, bus)
    case 3: _compute_indy_addr(cpu, bus)
    case 4:
        _adjust_addr(cpu, bus, cpu.y)
        _write(bus, cpu.a)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $94
sty_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp(cpu, bus, cpu.y, cpu.x)
}

// $95
sta_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp(cpu, bus, cpu.a, cpu.x)
}

// $96
stx_zpy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_zp(cpu, bus, cpu.x, cpu.y)
}

// $98
tya :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _transfer_reg(cpu, bus, cpu.y, &cpu.a)
}

// $99
sta_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_abs(cpu, bus, cpu.a, cpu.y)
}

// $9A
txs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _transfer_reg(cpu, bus, cpu.x, &cpu.sp)
}

// $9D
sta_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _store_reg_abs(cpu, bus, cpu.a, cpu.x)
}

// $A0
ldy_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_imm(cpu, bus, &cpu.y)
}

// $A1
lda_indx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_indx_ptr_lo(cpu, bus)
    case 3: _fetch_indx_ptr_hi(cpu, bus)
    case 4: _compute_indx_addr(cpu, bus)
    case 5:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
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

// $A8
tay :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _transfer_reg(cpu, bus, cpu.a, &cpu.y)
}

// $A9
lda_imm :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_imm(cpu, bus, &cpu.a)
}

// $AA
tax :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _transfer_reg(cpu, bus, cpu.a, &cpu.x)
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
    case 0: _fetch(cpu, bus)
    case 1: _fetch_indy_ptr_lo(cpu, bus)
    case 2: _fetch_indy_ptr_hi(cpu, bus)
    case 3:
        page_crossed := _compute_indy_addr(cpu, bus)
        if !page_crossed do cpu.cycle += 1
    case 4: _adjust_addr(cpu, bus, cpu.y)
    case 5:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $B4
ldy_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp(cpu, bus, &cpu.y, cpu.x)
}

// $B5
lda_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp(cpu, bus, &cpu.a, cpu.x)
}

// $B6
ldx_zpy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_zp(cpu, bus, &cpu.x, cpu.y)
}

// $B8
clv :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        clear_flag(cpu, .Overflow)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $B9
lda_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs(cpu, bus, &cpu.a, cpu.y)
}

// $BA
tsx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _transfer_reg(cpu, bus, cpu.sp, &cpu.x)
}

// $BC
ldy_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs(cpu, bus, &cpu.y, cpu.x)
}

// $BD
lda_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs(cpu, bus, &cpu.a, cpu.x)
}

// $BE
ldx_absy :: proc(cpu: ^MOS6502, bus: ^Bus) {
    _load_reg_abs(cpu, bus, &cpu.x, cpu.y)
}

// $C6
dec_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _begin_rmw(cpu, bus)
    case 3:
        data := u8(cpu.addr)
        data -= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 4: _sync(cpu, bus)
    case: unreachable()
    }
}

// $C8
iny :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        cpu.y += 1
        set_nz(cpu, cpu.y)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $CA
dex :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        cpu.x -= 1
        set_nz(cpu, cpu.x)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $CE
dec_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        data -= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $D6
dec_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        data -= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $D8
cld :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        clear_flag(cpu, .Decimal)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $DE
dec_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus, cpu.x)
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4: _begin_rmw(cpu, bus)
    case 5:
        data := u8(cpu.addr)
        data -= 1
        set_nz(cpu, data)
        _write(bus, data)
    case 6: _sync(cpu, bus)
    case: unreachable()
    }
}

// $E6
inc_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _begin_rmw(cpu, bus)
    case 3:
        data := u8(cpu.addr)
        data += 1
        set_nz(cpu, data)
        _write(bus, data)
    case 4: _sync(cpu, bus)
    case: unreachable()
    }
}

// $E8
inx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        cpu.x += 1
        set_nz(cpu, cpu.x)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $EA
nop :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1: _sync(cpu, bus)
    }
}

// $EE
inc_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        data += 1
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $F6
inc_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3: _begin_rmw(cpu, bus)
    case 4:
        data := u8(cpu.addr)
        data += 1
        set_nz(cpu, data)
        _write(bus, data)
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $F8
sed :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1:
        set_flag(cpu, .Decimal)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $FE
inc_absx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_abs_lo(cpu, bus)
    case 2: _fetch_abs_hi(cpu, bus, cpu.x)
    case 3: _adjust_addr(cpu, bus, cpu.x)
    case 4: _begin_rmw(cpu, bus)
    case 5:
        data := u8(cpu.addr)
        data += 1
        set_nz(cpu, data)
        _write(bus, data)
    case 6: _sync(cpu, bus)
    case: unreachable()
    }
}
