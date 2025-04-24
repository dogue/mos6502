package mos6502

main :: proc() {
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
}
