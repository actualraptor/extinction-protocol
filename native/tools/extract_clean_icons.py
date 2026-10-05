"""Deterministic sprite extraction from existing authored RGBA sheets.

Assign connected alpha components to their authored grid position before cropping.
This retains art crossing a cell edge while excluding fragments from its neighbor.
Original paintings remain unchanged. Pillow/NumPy only; no model regeneration.
"""
from collections import deque
from pathlib import Path
import json
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ASSETS = Path(__file__).resolve().parents[1]/"assets"
OUT = ASSETS/"clean-icons"
OUT.mkdir(exist_ok=True)
ANALYZED = {}
WEAPONS = "revolver club frost fire lightning shotgun orbital mortar spear pyre winter miasma dread aegis stasis thunderstorm whiteout supernova lastword earthshaker bastion ricochet return compass tablet".split()
UPGRADES = "luck damage haste area count crit armor speed pickup regen velocity pierce homing bounce reach echo conductor fork pulse linger ward eternity sorcery winterbite combustion".split()
RELICS = "ember storm blood glass clock magnet frost boots crown shell volley branch cyclone shatter wildfire garden reaper laststand momentum apex flint wrap coil lens prism chronicle portal chest camp meteor".split()

def components(image, columns, rows):
    rgba = np.array(image.convert("RGBA"))
    h,w = rgba.shape[:2]
    # Core connectivity prevents very faint glows joining unrelated paintings.
    solid = rgba[:,:,3]>=64
    labels = np.full((h,w),-1,np.int32)
    stats = []
    for y,x in zip(*np.nonzero(solid)):
        if labels[y,x]>=0: continue
        number = len(stats)
        labels[y,x] = number
        queue = deque([(int(x),int(y))])
        count = 0; sx = 0; sy = 0
        left=right=int(x);top=bottom=int(y)
        while queue:
            px,py = queue.popleft();count+=1;sx+=px;sy+=py
            left=min(left,px);right=max(right,px);top=min(top,py);bottom=max(bottom,py)
            for nx,ny in ((px-1,py),(px+1,py),(px,py-1),(px,py+1)):
                if 0<=nx<w and 0<=ny<h and solid[ny,nx] and labels[ny,nx]<0:
                    labels[ny,nx]=number;queue.append((nx,ny))
        cx=sx/count;cy=sy/count
        owner=min(rows-1,int(cy*rows/h))*columns+min(columns-1,int(cx*columns/w))
        stats.append({"count":count,"owner":owner,"bounds":[left,top,right+1,bottom+1]})
    # Restore soft antialiased edges/glow around classified cores while keeping
    # ownership stable. Disconnected shards retain their own component ownership.
    for _ in range(8):
        vacant=(labels<0)&(rgba[:,:,3]>2)
        previous=labels.copy()
        for dy,dx in ((0,-1),(0,1),(-1,0),(1,0)):
            shifted=np.roll(previous,(dy,dx),(0,1))
            if dy<0:shifted[-1,:]=-1
            if dy>0:shifted[0,:]=-1
            if dx<0:shifted[:,-1]=-1
            if dx>0:shifted[:,0]=-1
            take=vacant&(shifted>=0)&(labels<0)
            labels[take]=shifted[take]
    owner_lut=np.array([s["owner"] if s["count"]>=5 else -1 for s in stats],np.int32)
    ownership=np.full(labels.shape,-1,np.int32)
    marked=labels>=0
    ownership[marked]=owner_lut[labels[marked]]
    return rgba,ownership,stats

def export(sheet,columns,rows,names,prefix="",selection=None,size=320):
    key=(sheet,columns,rows)
    if key not in ANALYZED: ANALYZED[key]=components(Image.open(ASSETS/sheet),columns,rows)
    rgba,owners,stats=ANALYZED[key]
    records=[]
    for i,name in enumerate(names):
        index=selection[i] if selection is not None else i
        mask=owners==index
        yy,xx=np.nonzero(mask)
        if len(xx)==0:raise ValueError(f"No authored sprite {sheet}:{index}")
        box=(int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1)
        selected=rgba.copy();selected[~mask]=0
        sprite=Image.fromarray(selected).crop(box)
        available=size-32
        factor=available/max(sprite.size)
        sprite=sprite.resize((max(1,round(sprite.width*factor)),max(1,round(sprite.height*factor))),Image.Resampling.LANCZOS)
        canvas=Image.new("RGBA",(size,size))
        canvas.alpha_composite(sprite,((size-sprite.width)//2,(size-sprite.height)//2))
        filename=prefix+name+".png"
        canvas.save(OUT/filename)
        records.append({"file":filename,"source":sheet,"grid_index":index,"bounds":box,"component_count":sum(s["owner"]==index and s["count"]>=5 for s in stats)})
    return records

def main():
    records=[]
    for family,names,columns in [("weapons",WEAPONS,5),("upgrades",UPGRADES,5),("relics",RELICS,6)]:
        records+=export(f"icons-{family}-06.png",columns,5,names,family+"-")
    records+=export("thorns-breakables-08.png",2,2,["thorns","urn","crate","stump"],"field-")
    records+=export("frontiers-07.png",4,3,[str(i) for i in range(12)],"frontier-")
    for seasonal in [False,True]:
        variant="halloween-" if seasonal else ""
        base="hollow-harvest-creatures.png" if seasonal else "characters-v2.png"
        extra="hollow-harvest-monsters.png" if seasonal else "monsters-04.png"
        frontier="hollow-harvest-frontiers.png" if seasonal else "frontiers-07.png"
        records+=export(base,3,3,["thorn","meteor"],"boss-"+variant,[4,8],384)
        records+=export(extra,3,3,["basalt"],"boss-"+variant,[6],384)
        records+=export(frontier,4,3,["hunt","aurora","warden","bloom"],"boss-"+variant,[4,5,6,7],384)
    portraits=export("harvest-portraits-011.png",5,1,["kael","voss","vesper","iona","orin"],"portrait-halloween-",size=640)
    records+=portraits
    (ASSETS/"harvest-portrait-regions-011.json").write_text(json.dumps([list(r["bounds"][:2])+[r["bounds"][2]-r["bounds"][0],r["bounds"][3]-r["bounds"][1]] for r in portraits],indent=2),encoding="utf8")
    records+=export("iona-walk.png",4,3,["iona-normal"],"portrait-",[1],640)
    (OUT/"manifest.json").write_text(json.dumps(records,indent=2),encoding="utf8")
    contact_sheets()
    print(f"Extracted {len(records)} clean icons and 10 light/dark/checker HUD/reel contact sheets.")

def contact_sheets():
    # Evidence at actual HUD and chest/reel sizes, including translucent edges.
    bosses=["thorn","basalt","hunt","aurora","warden","bloom","meteor"]
    for family,names in [("relics",RELICS),("weapons",WEAPONS),("upgrades",UPGRADES),("boss",bosses),("boss-halloween",bosses)]:
        for size in [40,160]:
            width=6*(size+30);height=((len(names)+5)//6)*(size+44)
            contact=Image.new("RGB",(width,height),"#11191c")
            draw=ImageDraw.Draw(contact)
            for index,name in enumerate(names):
                x=(index%6)*(size+30);y=(index//6)*(size+44)
                dark=index%3==0
                draw.rectangle((x,y,x+size+29,y+size+43),fill="#11191c" if dark else "#ccd2cf")
                if index%3==2:
                    for cy in range(0,size,12):
                        for cx in range(0,size,12):
                            if (cx//12+cy//12)%2==0:
                                draw.rectangle((x+15+cx,y+cy,x+15+min(size,cx+11),y+min(size,cy+11)),fill="#a1aaa6")
                sprite=Image.open(OUT/f"{family}-{name}.png").resize((size,size),Image.Resampling.LANCZOS)
                contact.paste(sprite,(x+15,y),sprite)
                draw.text((x+3,y+size+4),name,fill="white" if dark else "black")
            contact.save(ASSETS.parent/"build"/f"clean-icons-{family}-{size}.png")

if __name__=="__main__":
    if "--contact-only" in sys.argv:contact_sheets()
    else:main()
