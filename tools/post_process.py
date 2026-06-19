import re,pathlib

gamename = "commando"

# game_specific: replace or remove I/O addresses
# if not done it will write in ROM here!!
input_dict = {

"sound_c800":"sound_start",

##"background_scroll_x_c808":"set_background_scroll_x_lsb",
##"background_scroll_x_c809":"set_background_scroll_x_msb",
##"background_scroll_y_c80a":"set_background_scroll_y_lsb",
##"background_scroll_y_c80b":"set_background_scroll_y_msb",
"sound_and_screen_orientation_c804":"",
"dma_trigger_c806":"",
}

single_line_to_cc_protect = {0x1a14,0x96ec}
remove_error_in_next_line = {0x1119,0x129d,0x1a17,0x96ef,0x96ea,0x96f8,0X8551,0x8553,0x6D21}
line_to_push_cc_protect = {0x8552,0x854d} | single_line_to_cc_protect
line_to_pull_cc_protect = {0x8551} | single_line_to_cc_protect

store_to_video = re.compile("GET_ADDRESS\s+(0xd\w\w\w|video_ram_d)",flags=re.I)   # game_specific


# post-conversion automatic patches, allowing not to change the asm file by hand
tablere = re.compile("move.w\t#(\w*table_....),d(.)")
jmpre = re.compile("(j..)\s+\[a,(.)\]")
dreg_dict = {'a':'d0','b':'d1'}
areg_dict = {'x':'a2','y':'a3','u':'a4'}



def remove_continuing_lines(lines,i):
    for j in range(i+1,i+4):
        if "[...]" in lines[j]:
            lines[j] = ""
        else:
            break


def get_line_address(line):
    try:
        toks = line.split("|")
        address = toks[1].strip(" [$").split(":")[0]
        return int(address,16)
    except (ValueError,IndexError):
        return None

def remove_continuing_lines(lines,i):
    for j in range(i+1,i+4):
        if "[...]" in lines[j]:
            lines[j] = ""
        else:
            break


def change_instruction(code,lines,i,continuing_lines=True):
    line = lines[i]
    toks = line.split("|")
    if len(toks)==2:
        toks[0] = f"\t{code}"
        if continuing_lines:
            remove_continuing_lines(lines,i)
        return " | ".join(toks)
    return line

def remove_error(line,ignore=False):
    if "ERROR" in line:
        return ""
    elif not ignore:
        raise Exception(f"No ERROR to remove in {line}")
    else:
        return line
def remove_instruction(lines,i,continuing_lines=True):
    return change_instruction("",lines,i,continuing_lines=continuing_lines)

def remove_continuing_lines(lines,i):
    for j in range(i+1,i+4):
        if "[...]" in lines[j]:
            lines[j] = ""
        else:
            break



def process_jump_table(line):

    m = re.search("\[nb_entries=(\d+)",line)
    if m:
        nb_entries = m.group(1)
        line = f"""\t.ifndef\tRELEASE
\tmove.w\t#{nb_entries},d7
\t.endif
"""+line

    return line

def get_original_instruction(line):
    toks = line.split("| [")
    if len(toks)==1:
        return ""
    inst = toks[1][7:].split("]")[0]
    return inst


def remove_code(pattern,lines,i):
    if pattern in lines[i]:
        lines[i] = remove_instruction(lines,i)
        remove_continuing_lines(lines,i)
    return lines[i]

def rebuild_lines(lines):
    return "".join(lines).splitlines(True)

def swap_lines(lines,i,j):
    lines[i],lines[j] = lines[j].rstrip()+ "| swapped\n",lines[i].rstrip()+ "| swapped\n"
    return lines[i]

def kill_code(lines,start_line,end_address):
    while True:
        address = get_line_address(lines[start_line])
        lines[start_line] = remove_instruction(lines,start_line)
        if "|" not in lines[start_line]:
            lines[start_line] = ""
        if address == end_address:
            break
        start_line+=1

def subt(m):
    tn = m.group(1)
    rn = m.group(2)
    offset = tn.split("_")[-1]
    rval = f"""
\t.ifndef\tRELEASE
\tmove.w\t#0x{offset},d{rn}
\t.endif
\tlea\t{tn},a{rn}"""
    return rval

equates = []
global_symbols = []
equates_re = re.compile("(\w+)\s*=(\$?\w+)")
this_dir = pathlib.Path(__file__).absolute().parent

source_dir = this_dir / "../src"

add_a_to_hl = """\tMAKE_HL_NO_AR
\tand.w #0xFF,d0
\tadd.w\td0,d6
\tmove.b\td6,d0   | so routine is equivalent to original
\tMAKE_H
"""

# various dirty but at least automatic patches applying on the converted code
with open(source_dir / "conv.s") as f:
    lines = list(f)

    for i,line in enumerate(lines):
        m = equates_re.match(line)
        if m:
            equates.append(line)
            line = ""


##        elif "review stray daa" in line:
##            line = """\tCLR_XC_FLAGS
##\tmove.b\t(a0),d6
##\tabcd\td6,d0
##"""
        address = get_line_address(line)

        if "[address_pop]" in line:
            if "MAKE_" in line:
                line = ""
            else:
                line = change_instruction("addq.w\t#4,sp",lines,i)

        elif "[return]" in line:
            if "MAKE_" in line:
                line = ""
            else:
                line = change_instruction("rts",lines,i)

        elif "[nop]" in line:
            line = remove_instruction(lines,i)

        elif "[breakpoint]" in line and address:
            line = f'\tBREAKPOINT "{address:04x}"\n{line}'

        elif "[cc_ok]" in line:
            if "rts" in line and "ret]" not in line: # conditional return
                lines[i-1] = remove_error(lines[i-1],True)
            else:
                lines[i+1] = remove_error(lines[i+1],True)


        line = process_jump_table(line)

        if "[push_function]" in line:
            toks = line.split()
            line = remove_instruction(lines,i)
            pa = toks[1].strip("#")
            lines[i+1] = change_instruction(f"pea\t{pa}",lines,i+1)

        # pre-add video_address tag if we find a store instruction to an explicit 3000-3FFF address
        m = store_to_video.search(line)
        if m:
            g = m.group(1)
            okay = True
            if g.startswith("0x"):
                address = int(g,16)
                line = line.rstrip() + " [video_address]\n"

        if "[video_address" in line or "[unchecked_address" in line:
            # give me the original instruction
            line = line.replace("_ADDRESS","_UNCHECKED_ADDRESS")
            if "MAKE" in line:
                line = re.sub(r"(MAKE_AR)",r"\1_UNCHECKED",line)
                line = re.sub(r"(MAKE_[HDB]\w)",r"\1_UNCHECKED",line)
            elif "MAKE" in lines[i-1] and "UNCHECKED" not in lines[i-1]:
                lines[i-1] = re.sub(r"(MAKE_AR)",r"\1_UNCHECKED",lines[i-1])
                lines[i-1] = re.sub(r"(MAKE_[HDB]\w)",r"\1_UNCHECKED",lines[i-1])
            elif "ldir" in line:
                line = line.replace("ldir","ldir_video" if "[video_address" in line else "ldir_unchecked")
            if "[video_address" in line:
                if ",(a0)" in line or ("(a0)" in line and "clr.b" in line):
                    line += "\tVIDEO_BYTE_DIRTY | [...]\n"
                elif (",(a0)" in lines[i+1] or ("(a0)" in  lines[i+1]  and "clr.b" in lines[i+1] )):
                    lines[i+1]  += "\tVIDEO_BYTE_DIRTY | [...]\n"

        if "[pop_stack]" in line:
            line = change_instruction("addq\t#4,sp",lines,i)

        ###############################################
        # game_specific

        if "replace by EXG_A_A_PRIME" in line:
            # no need to swap F with F', ever in this game
            lines[i-1] = "* just swap A/A'\n"+change_instruction("EXG_A_A_PRIME",lines,i-1)
            line = remove_error(line)
        elif "abcd/sbcd/subx/addx" in line:
            # those have been analyzed, no risk (worse case: score not working properly, easy to debug)
            line = remove_error(line)

        if address == 0x0018:
            # replace routine altogether
            line = add_a_to_hl+"\trts"
            kill_code(lines,i+1,0x1D)
        elif address == 0x0020:
            # replace routine altogether
            line = add_a_to_hl
            kill_code(lines,i+1,0x24)

        elif address == 0x0030:
            # jump table
            line = """\tmove.l\t(a7)+,a0   | get table address (just after rst instruction)
\t.ifndef\tRELEASE
\tcmp.b\td7,d0
\tjcs\t0f
\tmove.b\td0,d1
\tmove.b\td7,d6
\tjbsr\tosd_get_last_known_pc
\tBREAKPOINT\t"too many cases for jump table (D1 vs D6, rst called from D7)"
0:
\t.endif
\tadd.w\td0,d0
\tadd.w\td0,d0       | times 4
\tmove.l\t(a0,d0.w),a0
\tjmp\t(a0)
"""
            kill_code(lines,i+1,0x33)
        elif address == 0x004a:
            lines[i-1] = remove_error(lines[i-1])
            line = remove_instruction(lines,i)
        elif address == 0x1115:
            line = swap_lines(lines,i,i-1)  # preserve flag, independent operations
        elif address == 0x6d20:
            line = swap_lines(lines,i,i-1)  # preserve flag, independent operations

        elif address == 0x0a94:
            # useless test, we test d6.w afterwards
            lines[i-1] = ""  # no need for MAKE_H
            line = remove_instruction(lines,i)
            lines[i+1] = remove_instruction(lines,i+1)
        elif address == 0x0a99:
            lines[i+1] = remove_error(lines[i+1])  # flags are consistent
        elif address == 0xa770:
            # dirty if address matches
            line = """\tcmp.w\t#0xE000,d4
\tjcc\t0f
\tVIDEO_BYTE_DIRTY
0:
"""+line
        elif address == 0x3bd0:
            line = remove_instruction(lines,i)
            lines[i+1] = change_instruction("add.b\t#0x20,d4",lines,i+1)
            lines[i+2] = remove_instruction(lines,i+2,False)
            lines[i+4] = remove_error(lines[i+4])
        elif address == 0x92f4:
            line = change_instruction("moveq\t#1,d7",lines,i)+"\tCLR_XC_FLAGS\n"
        elif address == 0x92f5:
            line = change_instruction("sbcd\td7,d0",lines,i)
        elif address == 0x96f3:
            line = """\tmovem.w\td1/d2,-(a7)
\tjbsr\tl_970a\t| [$96f4: call $970a]
\tmovem.w\t(a7)+,d1/d2
\tjne\t0f\t| [ret  z]
"""
            kill_code(lines,i+1,0x96f8)
        elif address == 0x8553:
            lines[i-1] += "\tPOP_SR\n"
        # end game_specific
        ###############################################
        if address in line_to_pull_cc_protect:
            # protect the sub instructions
            line += "\tPOP_SR\n"
        elif address in line_to_push_cc_protect:
            # protect the sub instructions
            line = "\tPUSH_SR\n"+line
        elif address in remove_error_in_next_line:
            lines[i+1] = remove_error(lines[i+1])
        if "GET_ADDRESS" in line:
            val = line.split()[1].split(",")[0]
            osd_call = input_dict.get(val)
            if osd_call is not None:

                if osd_call:
                    line = change_instruction(f"jbsr\tosd_{osd_call}",lines,i)
                else:
                    line = remove_instruction(lines,i)
                lines[i+1] = remove_instruction(lines,i+1)

        if "[global]" in line:
            label = line.split(":")[0]
            global_symbols.append(label)

        lines[i] = line

    # remove duplicate VIDEO_BYTE_DIRTY
    lines = rebuild_lines(lines)
    new_lines = []
    prev_line = ""
    for line in lines:
        if "VIDEO_BYTE_DIRTY" in line and "VIDEO_BYTE_DIRTY" in prev_line:
            pass
        else:
            new_lines.append(line)
        prev_line = line

with open(source_dir / "data.inc","w") as fw:
    fw.writelines(equates)

with open(source_dir / f"{gamename}.68k","w") as fw:

    fw.write(f"""\t.include "data.inc"
""")
    for g in global_symbols:
        fw.write(f"\t.global\t{g}\n")

    fw.writelines(new_lines)
