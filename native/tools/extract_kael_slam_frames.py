"""Isolate generated Kael slam poses; preserve real frame art and foot anchors.

The generated sheets contain complete authored bodies. Connected-alpha ownership
removes neighboring feet/club fragments before crops, including art crossing
grid boundaries. Manual foot markers keep crouch and overhead poses grounded.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw
from extract_clean_icons import components

ASSETS=Path(__file__).resolve().parents[1]/"assets"
OUT=ASSETS/"kael-slam-0111"
POSES=["anticipation","lift","overhead","downstroke","impact","recovery"]
PHASES=[0.0,.12,.30,.50,.62,.80]
# Source-pixel planted-feet midpoint and sole baseline, inspected in generated art.
ANCHORS=[(285,517),(791,518),(1296,518),(258,967),(759,966),(1292,968)]
SCALE=68/380

def main():
    variants={}
    for variant in ["normal","halloween"]:
        source=f"kael-ground-slam-{variant}-0111.png"
        sheet=Image.open(ASSETS/source)
        rgba,ownership,components_info=components(sheet,3,2)
        output=OUT/variant
        output.mkdir(parents=True,exist_ok=True)
        frames=[]
        for index,pose in enumerate(POSES):
            mask=ownership==index
            y,x=np.nonzero(mask)
            bounds=(max(0,int(x.min())-8),max(0,int(y.min())-8),min(sheet.width,int(x.max())+9),min(sheet.height,int(y.max())+9))
            pixels=rgba.copy();pixels[~mask]=0
            frame=Image.fromarray(pixels).crop(bounds)
            filename=f"{index:02d}-{pose}.png"
            frame.save(output/filename)
            anchor=[ANCHORS[index][0]-bounds[0],ANCHORS[index][1]-bounds[1]]
            frames.append({"pose":pose,"file":f"res://assets/kael-slam-0111/{variant}/{filename}","anchor":anchor,"size":list(frame.size),"source_bounds":list(bounds),"phase_from":PHASES[index]})
        variants[variant]=frames
    metadata={"standing_body_height":68,"source_body_height":380,"pixel_scale":SCALE,"impact_progress":.62,"impact_offset":[29,5],"variants":variants}
    (OUT/"frames.json").write_text(json.dumps(metadata,indent=2),encoding="utf8")
    # Actual 68px character-scale evidence. Top/bottom rows share a foot line.
    canvas=Image.new("RGB",(720,280),"#101c20")
    draw=ImageDraw.Draw(canvas)
    for row,variant in enumerate(variants):
        for index,frame in enumerate(variants[variant]):
            x=60+index*120;baseline=108+row*140
            art=Image.open(ASSETS/frame["file"].split("res://assets/")[1])
            art=art.resize((round(art.width*SCALE),round(art.height*SCALE)),Image.Resampling.LANCZOS)
            at=(round(x-frame["anchor"][0]*SCALE),round(baseline-frame["anchor"][1]*SCALE))
            canvas.paste(art,at,art)
            draw.line((x-35,baseline,x+35,baseline),fill="#507064",width=1)
            draw.text((x-40,baseline+12),frame["pose"],fill="#ebd4a0")
    canvas.save(ASSETS.parent/"build"/"kael-slam-68px-contact.png")
    print("Extracted 12 true Kael attack poses with stable planted-foot anchors.")

if __name__=="__main__":main()
