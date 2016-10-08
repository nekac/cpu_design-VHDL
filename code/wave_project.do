onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /project/cpu/if_phase/clk
add wave -noupdate -radix hexadecimal /project/cpu/if_phase/reset
add wave -noupdate /project/halt
add wave -noupdate /project/data_mem_rd
add wave -noupdate /project/data_mem_word_out
add wave -noupdate /project/data_mem_wr
add wave -noupdate /project/data_mem_word_in
add wave -noupdate /project/data_mem_addr
add wave -noupdate /project/instr_mem_addr
add wave -noupdate /project/instr_mem_word
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {565054 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 166
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {534545 ps} {621480 ps}
