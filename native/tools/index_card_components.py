from pathlib import Path
from PIL import Image
import json
# Index separate atlas resources without changing or repainting generated pixels.
root=Path('native/assets/cards-modular')
xs=[0,341,683,1024]
tiers=['common','uncommon','rare','epic','legendary','artifact']
parts=['frame','title','panel','button','medallion']
manifest={}
for row,part in enumerate(parts):
    for col,tier in enumerate(tiers):
        sheet='components-a.png' if col<3 else 'components-b.png'
        im=Image.open(root/sheet)
        ys=[0,470,630,970,1118,1536] if col<3 else [0,490,640,975,1110,1536]
        column=col%3
        cell=(xs[column],ys[row],xs[column+1],ys[row+1])
        alpha=im.crop(cell).getchannel('A')
        bound=alpha.point(lambda a:255 if a>128 else 0).getbbox()
        assert bound,(tier,part)
        x,y=cell[0]+bound[0],cell[1]+bound[1]
        w,h=bound[2]-bound[0],bound[3]-bound[1]
        key=f'{tier}-{part}'
        manifest[key]=[x,y,w,h]
        (root/(key+'.tres')).write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/cards-modular/%s" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(%s, %s, %s, %s)\nfilter_clip = true\n'%(sheet,x,y,w,h))
im=Image.open(root/'table-panels.png')
for i,tier in enumerate(tiers):
    col=i%2; row=i//2
    ys=[0,341,683,1024]
    cell=(col*768,ys[row],(col+1)*768,ys[row+1])
    bound=im.crop(cell).getchannel('A').point(lambda a:255 if a>128 else 0).getbbox()
    x,y=cell[0]+bound[0],cell[1]+bound[1]
    w,h=bound[2]-bound[0],bound[3]-bound[1]
    key=f'{tier}-panel'
    manifest[key]=[x,y,w,h]
    (root/(key+'.tres')).write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/cards-modular/table-panels.png" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(%s, %s, %s, %s)\nfilter_clip = true\n'%(x,y,w,h))
(root/'regions.json').write_text(json.dumps(manifest,indent=2))
if (root/'variant-07.png').exists():
    im=Image.open(root/'variant-07.png')
    cw,ch=im.width//3,im.height//2
    for i,tier in enumerate(tiers):
        cell=((i%3)*cw,(i//3)*ch,(i%3+1)*cw,(i//3+1)*ch)
        bound=im.crop(cell).getchannel('A').point(lambda a:255 if a>128 else 0).getbbox()
        x,y=cell[0]+bound[0],cell[1]+bound[1];w,h=bound[2]-bound[0],bound[3]-bound[1]
        (root/('07-'+tier+'-frame.tres')).write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/cards-modular/variant-07.png" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(%s, %s, %s, %s)\nfilter_clip = true\n'%(x,y,w,h))
if (root/'variant-07.png').exists():
    im=Image.open(root/'variant-07.png')
    cw,ch=im.width//3,im.height//2
    for i,tier in enumerate(tiers):
        cell=((i%3)*cw,(i//3)*ch,(i%3+1)*cw,(i//3+1)*ch)
        bound=im.crop(cell).getchannel('A').point(lambda a:255 if a>128 else 0).getbbox()
        x,y=cell[0]+bound[0],cell[1]+bound[1];w,h=bound[2]-bound[0],bound[3]-bound[1]
        (root/('07-'+tier+'-frame.tres')).write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/cards-modular/variant-07.png" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(%s, %s, %s, %s)\nfilter_clip = true\n'%(x,y,w,h))
print('Indexed 30 independently reusable components')
