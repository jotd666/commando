from PIL import Image,ImageOps
import os,sys,bitplanelib,subprocess,json,pathlib

this_dir = pathlib.Path(__file__).absolute().parent

data_dir = this_dir / ".." / ".."


src_dir = this_dir / ".." / ".." / "src" / "amiga"


sheets_path = this_dir / ".." / "sheets"
dump_dir = this_dir / "dumps"

used_sprite_cluts_file = this_dir / "used_sprite_cluts.json"
fg_used_tile_cluts_file = this_dir / "fg_used_tile_cluts.json"
used_graphics_dir = this_dir / "used_graphics"

SPRITE_NB_TILES = 0x300
FG_NB_TILES = 0x400
FG_NB_CLUTS = 16
BG_NB_TILES = 0x400
BG_NB_CLUTS = 16
SPRITE_NB_CLUTS = 4


def palette_pad(palette,pad_nb):
    palette += (pad_nb-len(palette)) * [(0x10,0x20,0x30)]

def ensure_empty(d):
    if os.path.exists(d):
        for f in os.listdir(d):
            x = os.path.join(d,f)
            if os.path.isfile(x):
                os.remove(x)
    else:
        os.makedirs(d)

def ensure_exists(d):
    if os.path.exists(d):
        pass
    else:
        os.makedirs(d)

sr = lambda a,b : set(range(a,b))
sr2 = lambda a,b : set(range(a,b,2))
sr3 = lambda a,b : set(range(a,b,3))
sr4 = lambda a,b : set(range(a,b,4))

group_sprite_pairs ={0X282,0xD6,0x21E,0x2EE,0x202,0x210,0x180,0x182,0x188,0x190,
0x192,0X21A,0x20A,0x17E,0x21E,0x20C,0x204,0X28E,0x23A,0x23C,0X2E8,0x290,0x292,
0x198,0x212,0x218,0x26e,0x27e,0x1A4,0x1AC,0x2C6,0x2C4,0x9A,0x10D,0x18A,0X1B4,
0X2F8,0x2F4,0x2F2,0x2F0,0x280,0x294,0x2EC,0X76,0x35,0x18,0X24C,0x1F0,0x2E4,
0x2E2,
0x1F8,0x246,0x278,
0x2FA,0x2FC,0xC9,0xC2,0x204,0x206,0x70,0x92,0x1A,0x1D,0x166,0x8,0x16E,0x19A,0x48,0x168,0x30,0x38,0x10,0x15A,0x1F2,0x1FA,0X232,0x234,0x238}

group_sprite_triplets = {0x1A0,0x1A8,0x1B0,0X2D8,0X2B3,0x161,0x2B0,0x284,0x1C0}

group_sprite_quadruplets = {0x1E8,0X18C,0x19C,0x194,0x1E0,}



def add_tile(table,index,cluts=[0],merge_cluts=True):
    if isinstance(index,range):
        pass
    elif not isinstance(index,(list,tuple)):
        index = [index]
    for idx in index:
        cluts = list(cluts)
        if idx in table and merge_cluts:
            cluts += table[idx]
        table[idx] = sorted(set(cluts))



def read_used_tiles(used_tiles_name,tile_cluts,nb_tiles,nb_cluts):
    with open(used_graphics_dir / used_tiles_name,"rb") as f:
        for index in range(nb_tiles):
            d = f.read(nb_cluts)
            cluts = [i for i,c in enumerate(d) if c]
            if cluts:
                add_tile(tile_cluts,index,cluts=cluts)


def get_sprite_names():

    rval = {i:"prisoner" for i in range(0xE0,0xF0)}
    rval.update({i:"door" for i in range(0x1A0,0x1BE)})
    rval.update({i:"jeep" for i in range(0x1F0,0x1FC)})
    rval.update({i:"blade" for i in range(0x2C0,0x2E0)})
    rval.update({i:"flames" for i in range(0x232,0x23E)})
    rval.update({i:"palm_tree" for i in [0X202,0x203,0x20A,0x20B,0x210,0X211,0x212,0x213,0x21A,0x21B,0x218,0x219]})
    rval.update({i:"grenade" for i in range(0xB2,0xB5)})
    rval.update({i:"bunker" for i in range(0x2A1,0x2B4)})
    rval.update({i:"heli" for i in range(0x2E0,0x2FE)})
    rval.update({i:"player" for i in range(0,0xF)})
    rval.update({i:"turret" for i in range(0x140,0x143)})
    rval[0xB5] = "bullet"
    rval.update({i:"masonry" for i in [0x20F,0x21E,0x20C,0x217,0x204,0x206,0x216,0x143,0x144,0x145]})
    return rval

def get_mirror_sprites():
    """ return the index of the sprites that need mirroring
as opposed to Gyruss, most of the sprites don't

"""
    rval = {}
    return rval



alphanum_tile_codes = set(range(0,16)) | set(range(0x40,0XA0))

##import json
##
##with open("sprites_per_level.json","r") as f:
##    spl = json.load(f)
##sn = get_sprite_names()
##snv = {k:{"pre_mirror":None,"levels":spl.get(k)} for k in set(sn.values())}
##for k,v in snv.items():
##    if v and v["levels"]=="*":
##        v["levels"] = None
##        v["on_last_level"] = False
##
##with open("sprites_per_level_all.json","w") as f:
##    json.dump(snv,f,indent=2)

if __name__ == "__main__":
    raise Exception("no main!")