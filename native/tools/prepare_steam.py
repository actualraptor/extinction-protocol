"""Prepare SteamPipe manifests only. Never uploads, logs in, or publishes a build."""
import argparse,json
from pathlib import Path

def stage(app_id,windows_depot,linux_depot,windows_dir,linux_dir,output):
    ids=[app_id,windows_depot,linux_depot]
    if any(i<=0 for i in ids) or len(set(ids))!=3:raise ValueError('Supply distinct real App/Windows depot/Linux depot IDs from Steamworks.')
    win=Path(windows_dir).resolve();linux=Path(linux_dir).resolve();out=Path(output).resolve()
    for folder,name in [(win,'Extinction Protocol.exe'),(linux,'Extinction Protocol.x86_64')]:
        if not (folder/name).is_file():raise ValueError(f'Missing release executable: {folder/name}')
    out.mkdir(parents=True,exist_ok=True)
    def q(value):return '"'+str(value).replace('\\','/').replace('"','')+'"'
    for depot,folder,name in [(windows_depot,win,'Extinction Protocol.exe'),(linux_depot,linux,'Extinction Protocol.x86_64')]:
        text='"DepotBuildConfig"\n{\n "DepotID" '+q(depot)+'\n "ContentRoot" '+q(folder)+'\n "FileMapping"\n {\n  "LocalPath" '+q(name)+'\n  "DepotPath" "."\n  "recursive" "0"\n }\n}\n'
        (out/f'depot_{depot}.vdf').write_text(text,encoding='utf-8')
    text='"AppBuild"\n{\n "AppID" '+q(app_id)+'\n "Desc" "Extinction Protocol private candidate"\n "BuildOutput" '+q(out/'cache')+'\n "Preview" "1"\n "Depots"\n {\n'
    for depot in [windows_depot,linux_depot]:text+='  '+q(depot)+' '+q(out/f'depot_{depot}.vdf')+'\n'
    text+=' }\n}\n'
    (out/'app_build.vdf').write_text(text,encoding='utf-8')
    return out/'app_build.vdf'
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for key in ['app-id','windows-depot','linux-depot']:p.add_argument('--'+key,required=True,type=int)
    for key in ['windows-dir','linux-dir','output']:p.add_argument('--'+key,required=True)
    args=vars(p.parse_args());print(stage(**args))
