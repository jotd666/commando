import subprocess,os,glob,shutil,pathlib,zipfile

progdir = pathlib.Path(__file__).parent.parent.absolute()

# paraj lha from https://github.com/mras0/plha.git
# gadf from https://github.com/sphair/gadf

gamename = "commando"
# JOTD path for cranker, adapt to whatever your path is :)
os.environ["PATH"] += os.pathsep+r"K:\progs\cli"

cmd_prefix = ["make","-f",os.path.join(progdir,"makefile.am")]

subprocess.check_call(cmd_prefix+["clean"],cwd=progdir /"src")

subprocess.check_call(cmd_prefix+["RELEASE_BUILD=1"],cwd=progdir /"src")
# create archive

outdir = progdir / "dist" / f"{gamename}_HD"

if os.path.isdir(outdir):
    shutil.rmtree(outdir)

outdir.mkdir(exist_ok=True,parents=True)

for file in ["readme.md",f"{gamename}.slave"]:
    shutil.copy(progdir / file,outdir)

assets = progdir /"assets"/"amiga"
shutil.copy(assets/"CommandoAGADual.info",outdir)





for ext in [""]:
    exename = f"{gamename}{ext}"
    shutil.copy(progdir/exename,outdir)
    # ATM both packers generate incorrect exe. propack seems to do better
    #subprocess.run(["cranker_windows.exe","-f",progdir/exename,"-o",progdir/f"{exename}.rnc"],check=True)
    #subprocess.run(["shrinkler","-p","-c",progdir/exename,progdir/f"{exename}.rnc"],check=True)
subprocess.run(cmd_prefix+["clean"],cwd=progdir/"src",check=True)

arcname = progdir / f"{gamename}_HD.lha"
arcname.unlink(missing_ok=True)
cmd = ["lha","-r","a",arcname,"*"]

subprocess.run(cmd,cwd=outdir.parent,check=True)

# create floppy
if False:
    for ext in [""]:
        exename = f"{gamename}{ext}"
        shutil.move(progdir/f"{exename}.rnc",progdir/exename)

    #shutil.copy(assets/"disk.info",progdir)
    adf_name = "Commando.adf"
    cmd = ["gadf","-i","commando","-a",adf_name,"-l","Commando","readme.md"]
    subprocess.run(cmd,cwd=progdir,check=True)

    # create a .zip for the floppy

    with zipfile.ZipFile(progdir / "Commando_adf.zip",mode="w",compression=zipfile.ZIP_DEFLATED) as zf:
        zf.write(progdir/adf_name,arcname=adf_name)
    os.remove(progdir/adf_name)