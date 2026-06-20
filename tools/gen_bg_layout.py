import bitplanelib,pathlib

# convert Commando screen addresses to
# Ghosts'N'Goblins screen addresses, so the layout matches the existing
# scrolling routines
this_dir = pathlib.Path(__file__).absolute().parent

dd_to_gng_table = []
gng_to_dd_table = [0]*0x400
for address in range(0,0x400):
    x = (address & 0x1F)
    y = (0x1F - (address // 0x20))

    # now create the gng address
    gng_address = y + 0x20*x
    dd_to_gng_table.append(gng_address)
    gng_to_dd_table[gng_address] = address

with open(this_dir / "../src/amiga/bg_conv_layout.68k","w") as f:
    f.write("dd2gng_table:\n")
    bitplanelib.dump_asm_bytes(dd_to_gng_table,f,True,0x20,2)
    f.write("gng2dd_table:\n")
    bitplanelib.dump_asm_bytes(gng_to_dd_table,f,True,0x20,2)
