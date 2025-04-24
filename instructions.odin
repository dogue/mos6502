package mos6502

// Instruction set implementation
// procs prefixed with `_` are helpers defined in `instruction_helpers.odin`

// $08
php :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1: _write_stack(cpu, bus, u8(cpu.p))
    case 2: _sync(cpu, bus)
    case: unreachable()
    }
}

// $18
clc :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.p.carry = false
        _sync(cpu, bus)
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
        cpu.p = Status_Flags(bus.data)
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $38
sec :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.p.carry = true
        _sync(cpu, bus)
    case: unreachable()
    }
}

// $46
lsr_zp :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2:
        cpu.addr = u16(bus.data)
        _set_write(bus)
    case 3:
        data := u8(cpu.addr)
        cpu.p.carry = data & 1 == 1
        data >>= 1
        set_nz(cpu, data)
        bus.data = data
        _set_write(bus)
    case 4: _sync(cpu, bus)
    case: unreachable()
    }
}

// $4A
lsr_acc :: proc(cpu :^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.p.carry = cpu.a & 1 == 1
        cpu.a >>= 1
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
    case 3:
        cpu.addr = u16(bus.data)
        bus.ctrl -= {.RW}
    case 4:
        cpu.p.carry = cpu.addr & 1 == 1
        cpu.addr >>= 1
        set_nz(cpu, u8(cpu.addr))
    case 5: _sync(cpu, bus)
    case: unreachable()
    }
}

// $56
lsr_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1: _fetch_zp_addr(cpu, bus)
    case 2: _fetch_zp_addr(cpu, bus, cpu.x)
    case 3:
        cpu.addr = u16(bus.data)
        _set_write(bus)
    case 4:
        cpu.p.carry = cpu.addr & 1 == 1
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
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.p.interrupt_disable = false
        _sync(cpu, bus)
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

// $78
sei :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch(cpu, bus)
    case 1:
        cpu.p.interrupt_disable = true
        _sync(cpu, bus)
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

// $EA
nop :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _read(cpu, bus)
    case 1: _sync(cpu, bus)
    }
}
