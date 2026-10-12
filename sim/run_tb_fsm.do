# Simula el testbench de la FSM
# desde sim/:  vsim -do run_tb_fsm.do   (con -c para correrlo sin ventana)
if {[file exists work]} { vdel -lib work -all }
vlib work
vcom -93 ../src/morse_fsm.vhd
vcom -93 ../tb/tb_morse_fsm.vhd

vsim -t ns work.tb_morse_fsm

if {![batch_mode]} {
    add wave -divider "Entradas"
    add wave /tb_morse_fsm/clk
    add wave /tb_morse_fsm/reset_n
    add wave /tb_morse_fsm/start
    add wave /tb_morse_fsm/tick
    add wave /tb_morse_fsm/code_bit
    add wave /tb_morse_fsm/last
    add wave -divider "Estado"
    add wave /tb_morse_fsm/dut/state
    add wave -radix binary /tb_morse_fsm/state_dbg
    add wave -divider "Salidas"
    add wave /tb_morse_fsm/load
    add wave /tb_morse_fsm/timer_clr
    add wave /tb_morse_fsm/shift_en
    add wave /tb_morse_fsm/len_dec
    add wave /tb_morse_fsm/led
}

run -all

if {[batch_mode]} { quit -f } else { wave zoom full }
