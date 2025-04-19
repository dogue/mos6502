package mos6502

import "core:testing"

@(test)
test_lda_imm :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := default_bus()
    bus->write(0, 0xA9)
    bus->write(1, 0x42)
    fetch(&cpu, &bus)
    tick(&cpu, &bus)
    tick(&cpu, &bus)

    testing.expect_value(t, cpu.a, 0x42)
    testing.expect_value(t, cpu.pc, 3)
    free(bus.data)
}

@(test)
test_lda_zp :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := default_bus()
    bus->write(0, 0xA5)
    bus->write(1, 0x69)
    bus->write(0x69, 0x42)
    fetch(&cpu, &bus)
    for _ in 0..<3 do tick(&cpu, &bus)

    testing.expect_value(t, cpu.a, 0x42)
    testing.expect_value(t, cpu.pc, 3)
    free(bus.data)
}

@(test)
test_lda_zpx :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := default_bus()
    bus->write(0, 0xB5)
    bus->write(1, 0x60)
    bus->write(0x69, 0x42)
    cpu.x = 0x09
    fetch(&cpu, &bus)
    for _ in 0..<4 do tick(&cpu, &bus)

    testing.expect_value(t, cpu.a, 0x42)
    free(bus.data)
}

@(test)
test_lda_abs :: proc(t: ^testing.T) {
    cpu: MOS6502
    bus := default_bus()
    bus->write(0, 0xAD)
    bus->write(1, 0x37)
    bus->write(2, 0x13)
    bus->write(0x1337, 0x42)
    fetch(&cpu, &bus)
    for _ in 0..<4 do tick(&cpu, &bus)

    testing.expect_value(t, cpu.a, 0x42)
    testing.expect_value(t, cpu.pc, 4)
    free(bus.data)
}
