package mos6502

Control_Pin :: enum {
    RW,
    SYNC,
    RUN,
}
Control_Pins :: bit_set[Control_Pin]

Bus :: struct {
    addr: u16,
    data: u8,
    ctrl: Control_Pins,
}
