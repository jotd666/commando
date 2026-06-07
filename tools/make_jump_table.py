# TODO: detect LDx followed JMP, auto rename + lowercase
# count not found tables (because instruction in between)
# warn if still fake code not removed at table address
# create MAME disassemble script for first table address

# this script was used once to
# - tag the jump/jsr calls
# - name the jump tables and dump their contents as words in the end of the file

import pathlib,re,bisect


fake = {}

def process(asm_file,rom_file,offset,end_address):
    with open(asm_file) as f:
        asm_lines = f.readlines()

    with open(rom_file,"rb") as f:
        rom = f.read()



    size = 0x100

    known_tables = set()
    inst_addresses = dict()
    not_in_listing = set()
    # first pass: add "jump_table" tag, collect valid instruction addresses

    for i,line in enumerate(asm_lines):
        m = re.match("([0-9A-F]{4}):",line)
        if m:
            inst_addresses[int(m.group(1),16)] = line


    inst_addresses_list = sorted(inst_addresses)
    # second pass: find tag, then previous LDx instruction to get table address
    # create a label for table at the previous LDx instruction that matches the
    # index register (X,Y). Widely used in a lot of games, Konami but not just them.
    for j,line in enumerate(asm_lines):
        # table offset in lowercase
        m = re.match("([0-9A-F]{4}):",line)

        if m and "[jump_to_jump_table]" in line:
            # table address is right after that
            table_address = int(m.group(1),16)+1

            if table_address:
                data = rom
                sub = offset
                end = end_address


                block = data[table_address-sub:table_address-sub+size]
                label = f"jump_table_{table_address:04x}"

                known_tables.add(label)   # don't do it twice




                min_address = 0x10000
                nb_entries = 0
                first_entry = None
                table_block = [f"; {label}:\n"]
                for i in range(0,len(block),2):
                    a = block[i] + block[i+1]*256   # little endian!
                    if a not in fake and (sub > a or a >= end):
                        break
                    # most table first entries follow the table itself. This allows
                    # to stop and not declare bogus entries
                    # don't stop if the address is below table or too far
                    if a > table_address and min_address > a:
                        min_address = a

                    if table_address >= min_address:
                        # table points on code just after: stop
                        #print(f"STOP: {table_address:04x} >= {min_address:04x}")
                        break

                    if not first_entry:
                        first_entry = a

                    if a in fake:
                        a = 0xFFFF

                    table_block.append(f"\tdc.w\t${a:04x}\t; ${table_address:04x}\n")

                    if a != 0xFFFF and a != first_entry and a not in inst_addresses:
                        closest_idx = bisect.bisect(inst_addresses_list,a)
                        if closest_idx == len(inst_addresses_list):
                            closest_idx-=1
                        closest_address = inst_addresses_list[closest_idx]
                        print(f"{label}: table entry {a:04x} not in listing (closest: {closest_address:04x})")
                        not_in_listing.add((a,closest_address))

                    nb_entries += 1
                    table_address += 2

                if first_entry and first_entry not in inst_addresses:
                    closest_idx = bisect.bisect(inst_addresses_list,first_entry)
                    if closest_idx == len(inst_addresses_list):
                        closest_idx-=1
                    closest_address = inst_addresses_list[closest_idx]
                    print(f"{label}: first entry {first_entry:04x} not in listing (closest: {closest_address:04x})")
                    not_in_listing.add((first_entry,closest_address))

                asm_lines[j] += "".join(table_block)

                if nb_entries < 2:
                    print(f"{label}: no or not enough entries")

    # write mame debug script to find missing entrypoints
    # once run in MAME, use "type d-*asm > missing.asm 2>&1" to reunite the dumps
    with open("debug_script","w") as f:
        for n,c in sorted(not_in_listing):

            f.write(f"dasm d-{c:04x}.asm,{n:04x},20\n")

    with open(asm_file.stem + "_new.asm","w") as f:
        f.writelines(asm_lines)

process(pathlib.Path("../src/commando_z80.asm"),"rom.bin",offset=0x0000,end_address=0xC000)
