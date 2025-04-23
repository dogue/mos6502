package mos6502

// Instruction set implementation
// procs prefixed with `_` are helpers defined in `instruction_helpers.odin`

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
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _set_zp_addr(cpu, bus)
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
    case 1:
        set_nz(cpu, cpu.a)
        fetch(cpu, bus)
    }
}

// $4E
lsr_abs :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch_abs_lo(cpu, bus)
    case 1: _fetch_abs_hi(cpu, bus)
    case 2: _set_abs_addr(cpu, bus)
    case 3: bus.ctrl -= {.RW}
    case 4:
        set_flag(cpu, .Carry, bus.data & 1 == 1)
        bus.data >>= 1
        set_nz(cpu, bus.data)
    case 5: fetch(cpu, bus)
    }
}

// $56
lsr_zpx :: proc(cpu: ^MOS6502, bus: ^Bus) {
    switch cpu.cycle {
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _set_zp_addr(cpu, bus)
    case 2: _set_zp_offset(cpu, bus, cpu.x)
    case 3: bus.ctrl -= {.RW}
    case 4:
        set_flag(cpu, .Carry, bus.data & 1 == 1)
        bus.data >>= 1
        set_nz(cpu, bus.data)
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
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _set_zp_addr(cpu, bus)
    case 2: _fetch_indx_lo(cpu, bus)
    case 3: _fetch_indx_hi(cpu, bus)
    case 4:
        _set_indx_addr(cpu, bus)
        _write(bus, cpu.a)
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
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _fetch_indy_lo(cpu, bus)
    case 2: _fetch_indy_hi(cpu, bus)
    case 3: _set_indy_addr(cpu, bus)
    case 4: _write(bus, cpu.a)
    case 5: fetch(cpu, bus)
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
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _set_zp_addr(cpu, bus)
    case 2: _fetch_indx_lo(cpu, bus)
    case 3: _fetch_indx_hi(cpu, bus)
    case 4: _set_indx_addr(cpu, bus)
    case 5:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        fetch(cpu, bus)
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
    case 0: _fetch_zp_byte(cpu, bus)
    case 1: _fetch_indy_lo(cpu, bus)
    case 2: _fetch_indy_hi(cpu, bus)
    case 3:
        page_crossed := _set_indy_addr(cpu, bus)
        if !page_crossed do cpu.cycle += 1
    case 4: _fix_addr(cpu, bus, cpu.y)
    case 5:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        fetch(cpu, bus)
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
    case 0: bus.addr = cpu.pc; cpu.pc += 1
    case 1: fetch(cpu, bus)
    }
}
