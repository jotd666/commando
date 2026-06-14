import os,struct,re

# log has the registers, then "DEAD" in hex then ram and rom base addresses
round_values_mask = 0xFF

with open(r"..\cpu_log","rb") as f:
    contents = f.read()
    ram_base,rom_base = struct.unpack(">II",contents[-8:])
    dead_marker, = struct.unpack(">H",contents[-10:-8])
    print(hex(ram_base),hex(rom_base))
    contents = contents[:-8]
    if dead_marker != 0xDEAD:
        raise Exception("Corrupt CPU log, should end by 0xDEAD at offset -8")

pcs = set()
# generated using LOG_REGS
macro = """
    .macro    LOG_REGS    z80pc
    move.w    sr,-(a7)
    move.l    a6,-(a7)
    move.l    log_ptr,a6
    move.w    #0x\z80pc,(a6)+
    move.b    d0,(a6)+
    move.b    d1,(a6)+
    move.b    d2,(a6)+
    move.b    d3,(a6)+
    move.b    d4,(a6)+
    move.b    d5,(a6)+
    move.b    d6,(a6)+
    sub.l     a6,a2
    move.w    a2,(a6)+
    sub.l     a6,a3
    move.w    a3,(a6)+
    move.w    #0xDEAD,(a6)+
    move.l    a6,log_ptr
    move.l    (a7)+,a6
    move.w    (a7)+,sr
    .endm
"""
len_block = 0

def decode_address(address):
    if rom_base < address < rom_base+0x6000:
        return address-rom_base
    if ram_base < address < ram_base+0x2800:
        return (address-ram_base)+0x8000
    return 0xDEAD

size = {"b":1,"w":2,"l":4}

for line in macro.splitlines():
    m = re.search ("move.([bwl]).*,\(a6\)",line)
    if m:
        s = m.group(1)
        len_block += size[s]

print("Block size = ",hex(len_block))

sorted_cmp = False
avoid_regs = []
regslist = list("abcdehl")+["ix","iy","hl","de"]



lst = []


for i in range(0,len(contents),len_block):
    chunk = contents[i:i+len_block]
    if len(chunk)<len_block:
        break
    regs=dict()
    regs["pc"],regs["a"],regs["b"],regs["c"],regs["d"],regs["e"],regs["h"],regs["l"],regs["ix"],regs["iy"],end = struct.unpack_from(">HBBBBBBBHHH",chunk)
    if end==0xCCCC:
        break
    if end != 0xDEAD:
        raise Exception("Wrong frame")
    pcs.add(regs["pc"])



    regs["hl"] = (regs["h"]<<8) + regs["l"]
    regs["de"] = (regs["d"]<<8) + regs["e"]
    regs["bc"] = (regs["b"]<<8) + regs["c"]


    regstr = ["{}={:0{}X}".format(reg.upper(),regs[reg],len(reg)*2) for reg in regslist if reg not in avoid_regs]
    rest = ", ".join(regstr)

    out = f"{regs['pc']:04X}: {rest}\n"

    lst.append(out)

if sorted_cmp:
    lst.sort()


with open("amiga.tr","w") as f:
    f.writelines(lst)

# generated using log:     trace mame.tr,,,{tracelog "A=%02X, B=%02X, C=%02X, D=%02X, E=%02X, H=%02X, L=%02X, IX=%04X, IY=%04X ",a,b,c,d,e,h,l,ix,iy}
lst = []
pc_list = set()
print("reading MAME trace file...")
with open(r"K:\Emulation\MAME\mame.tr","r") as f:
    l = len("A=01, B=00, C=3F, D=93, E=81, H=93, L=01, IX=XXXX, IY=XXXX ")
    for line in f:
        m = re.match("A=(..), B=(..), C=(..), D=(..), E=(..), H=(..), L=(..), IX=(....), IY=(....) ",line)
        if m:
            pc = line[l:l+4]
            regs = dict()
            if int(pc,16) in pcs:
                regs["a"],regs["b"],regs["c"],regs["d"],regs["e"],regs["h"],regs["l"],regs["ix"],regs["iy"] = m.groups()
                regs["hl"] = "{:04X}".format((int(regs["h"],16)<<8)+int(regs["l"],16))
                regs["de"] = "{:04X}".format((int(regs["d"],16)<<8)+int(regs["e"],16))

                # convert to integer and round it if needed
                for rn in "abcdehl":
                    regs[rn] = "{:02X}".format(int(regs[rn],16) & round_values_mask)

                regstr = ["{}={}".format(reg.upper(),regs[reg]) for reg in regslist if reg not in avoid_regs]
                rest = ", ".join(regstr)
                lst.append(f"{pc}: {rest}\n")
                pc_list.add(pc)

if sorted_cmp:
    lst.sort()
print("writing filtered MAME trace file with {} addresses...".format(len(pc_list)))
with open("mame.tr","w") as fw:
    fw.writelines(lst)
