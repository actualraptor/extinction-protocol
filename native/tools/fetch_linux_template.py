import io,urllib.request,zipfile,pathlib,hashlib
class Remote(io.RawIOBase):
 def __init__(self):self.pos=0;self.size=1281349702
 def seekable(self):return True
 def seek(self,n,w=0):self.pos=n if w==0 else self.pos+n if w==1 else self.size+n;return self.pos
 def tell(self):return self.pos
 def read(self,n=-1):
  n=min(self.size-self.pos,n if n>=0 else self.size-self.pos)
  if n<=0:return b''
  req=urllib.request.Request('https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz',headers={'Range':f'bytes={self.pos}-{self.pos+n-1}','User-Agent':'ExtinctionProtocol-build'})
  with urllib.request.urlopen(req,timeout=60) as r:
   assert r.status==206
   data=r.read()
  assert len(data)==n
  self.pos+=n;return data
with zipfile.ZipFile(Remote()) as z:
 names=[n for n in z.namelist() if 'linux_release.x86_64' in n]
 assert len(names)==1,names
 for name in names:
  p=pathlib.Path('tools/templates')/pathlib.Path(name).name
  data=z.read(name);p.write_bytes(data)
  print(p,len(data),hashlib.sha256(data).hexdigest())
