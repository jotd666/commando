import re,collections,os

src = "../src/commando_z80.asm"

def is_hex(x):
    try:
        int(x,16)
        return True
    except ValueError:
        return False

with open(src) as f:
    lines = f.readlines()

def f_name_hex(m):
    g = m.group(1)
    return equates.get(int(g[1:],16),g)
# read equates

labels = dict()
equates = dict()

hex_re = re.compile("(\$\w{4})")
# collect labels
for i,line in enumerate(lines):
    m = re.match("(\w+)\s+=\s+\$(\w+)(.*)",line)
    if m:
        name,address,rest = m.groups()
        equates[int(address,16)] = name.lower()
        lines[i] = f"{name.lower()} = ${address}{rest}\n"
    lines[i] = hex_re.sub(f_name_hex,line)

with open(os.path.basename(src),"w") as f:
    f.writelines(lines)
