# SDC — Additionneur 4-bit combinatoire (pas d'horloge)
# Horloge virtuelle pour contraindre les chemins combinatoires
create_clock -name vclk -period 10.0

# Contraintes I/O
set_input_delay  2.0 -clock vclk [all_inputs]
set_output_delay 2.0 -clock vclk [all_outputs]

# Max transition / fanout
set_max_transition 1.5 [current_design]
set_max_fanout 8 [current_design]
