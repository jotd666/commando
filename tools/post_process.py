import re,pathlib

gamename = "main_"
# post-conversion automatic patches, allowing not to change the asm file by hand
tablere = re.compile("move.w\t#(\w*table_....),d(.)")
jmpre = re.compile("(j..)\s+\[a,(.)\]")

def remove_instruction(lines,i):
    return change_instruction("",lines,i)

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

def change_instruction(code,lines,i):
    line = lines[i]
    toks = line.split("|")
    if len(toks)==2:
        toks[0] = f"\t{code}"
        remove_continuing_lines(lines,i)
        return " | ".join(toks)
    return line

def remove_code(pattern,lines,i):
    if pattern in lines[i]:
        lines[i] = remove_instruction(lines,i)
        remove_continuing_lines(lines,i)
    return lines[i]

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

this_dir = pathlib.Path(__file__).absolute().parent

source_dir = this_dir / "../src"

# game_specific: replace or remove I/O addresses
input_dict = {
#"sh_irqtrigger_w_1481":"",
}

store_to_video = re.compile("GET_ADDRESS\s+0x2")   # game_specific

# various dirty but at least automatic patches applying on the converted code
with open(source_dir / "{gamename}.s") as f:
    lines = list(f)

    for i,line in enumerate(lines):
        if " = " in line:
            equates.append(line)
            line = ""


        elif "review stray daa" in line:
            line = """\tCLR_XC_FLAGS
\tmove.b\t(a0),d6
\tabcd\td6,d0
"""

        address = get_line_address(line)

        ###############################################
        # game_specific




        # end game_specific
        ###############################################

with open(source_dir / "data.inc","w") as fw:
    fw.writelines(equates)

with open(source_dir / f"{gamename}.68k","w") as fw:
    # game_specific: fill global symbols
    fw.write(f"""\t.include {gamename}'.inc"
.include "data.inc"
\t.global\tirq_xxxx
\t.global\treset_yyyy
""")
    fw.writelines(lines)