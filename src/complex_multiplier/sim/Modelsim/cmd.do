## part 1: new lib
vlib work
vmap work work


## part 2: load design
vlog -sv  ../../tb/prim_sim.v
vlog -sv ../../complex_multiplier.vo
vlog -sv ../../tb/Complex_Multiplier_tb.v

## part 3: sim design
vsim -novopt work.tb

## part 4: show ui 
view transcript

##part 5:add wave
add wave -noupdate /tb/real1
add wave -noupdate /tb/real2
add wave -noupdate /tb/imag1
add wave -noupdate /tb/imag2
add wave -noupdate /tb/clk
add wave -noupdate /tb/rst
add wave -noupdate /tb/ce
add wave -noupdate /tb/golden_realo
add wave -noupdate /tb/golden_imago
add wave -noupdate /tb/golden_realo_T
add wave -noupdate /tb/golden_imago_T
add wave -noupdate /tb/golden_realo_2T
add wave -noupdate /tb/golden_imago_2T
add wave -noupdate /tb/golden_realo_3T
add wave -noupdate /tb/golden_imago_3T
add wave -noupdate /tb/realo
add wave -noupdate /tb/imago
add wave -noupdate /tb/result

## part 6: run 
run -all


