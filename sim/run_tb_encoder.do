# Simula el circuito completo con todas las letras
# desde sim/:  vsim -do run_tb_encoder.do   (con -c para correrlo sin ventana)
if {[file exists work]} { vdel -lib work -all }
vlib work
vcom -93 ../src/morse_rom.vhd
vcom -93 ../src/morse_shift_reg.vhd
vcom -93 ../src/morse_len_counter.vhd
vcom -93 ../src/half_sec_counter.vhd
vcom -93 ../src/morse_fsm.vhd
vcom -93 ../src/morse_encoder.vhd
vcom -93 ../tb/tb_morse_encoder.vhd

vsim -t ns work.tb_morse_encoder

if {![batch_mode]} {
    add wave -divider "Entradas"
    add wave /tb_morse_encoder/CLOCK_50
    add wave -radix binary /tb_morse_encoder/KEY
    add wave -radix unsigned /tb_morse_encoder/SW
    add wave -divider "Ruta de datos"
    add wave /tb_morse_encoder/dut/start
    add wave /tb_morse_encoder/dut/tick
    add wave /tb_morse_encoder/dut/shift_reg/q
    add wave -radix unsigned /tb_morse_encoder/dut/len_counter/count
    add wave /tb_morse_encoder/dut/code_bit
    add wave /tb_morse_encoder/dut/last
    add wave -divider "FSM"
    add wave /tb_morse_encoder/dut/fsm/state
    add wave -divider "Salida"
    add wave /tb_morse_encoder/LEDR
}

# apaga el warning de numeric_std en t=0 (antes del reset todo esta en U)
set NumericStdNoWarnings 1
run 0 ns
set NumericStdNoWarnings 0
run -all

if {[batch_mode]} { quit -f } else { wave zoom full }
