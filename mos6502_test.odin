package mos6502

import "core:testing"

@(test)
test_lda_imm :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xA9
    mem[1] = 0x42
    for _ in 0..<7+2 { // 7-cycle reset + 2 for LDA#
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
    testing.expect_value(t, cpu.pc, 3)
}

@(test)
test_lda_zp :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xA5
    mem[1] = 0x69
    mem[0x69] = 0x42
    for _ in 0..<7+3 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
    testing.expect_value(t, cpu.pc, 3)
}

@(test)
test_lda_zpx :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xB5
    mem[1] = 0x60
    mem[0x69] = 0x42
    cpu.x = 0x09
    for _ in 0..<7+4 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}

@(test)
test_lda_abs :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xAD
    mem[1] = 0x37
    mem[2] = 0x13
    mem[0x1337] = 0x42
    for _ in 0..<7+4 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}

@(test)
test_lda_absx_no_cross :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xBD
    mem[1] = 0x35
    mem[2] = 0x13
    mem[0x1337] = 0x42
    cpu.x = 2
    for _ in 0..<7+4 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}

@(test)
test_lda_absx_cross :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xBD
    mem[1] = 0xFF
    mem[2] = 0x13
    mem[0x1401] = 0x42
    cpu.x = 2
    for _ in 0..<7+5 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}

@(test)
test_lda_absy_no_cross :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xB9
    mem[1] = 0x35
    mem[2] = 0x13
    mem[0x1337] = 0x42
    cpu.y = 2
    for _ in 0..<7+4 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}

@(test)
test_lda_absy_cross :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xB9
    mem[1] = 0xFF
    mem[2] = 0x13
    mem[0x1401] = 0x42
    cpu.y = 2
    for _ in 0..<7+5 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}

@(test)
test_lda_indx :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xA1
    mem[1] = 0x67
    cpu.x = 2
    mem[0x69] = 0x37
    mem[0x6A] = 0x13
    mem[0x1337] = 0x42
    for _ in 0..<7+6 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}

@(test)
test_lda_indy :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := init(&cpu)
    mem: [0x10000]u8
    mem[0] = 0xB1
    mem[1] = 0x69
    mem[0x69] = 0x35
    mem[0x6A] = 0x13
    mem[0x1337] = 0x42
    cpu.y = 2
    for _ in 0..<7+5 {
        tick(&cpu, &bus)
        if .RW in bus.ctrl {
            bus.data = mem[bus.addr]
        }
    }

    testing.expect_value(t, cpu.a, 0x42)
}
