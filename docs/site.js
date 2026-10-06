const repository = document.documentElement.dataset.repository || 'actualraptor/extinction-protocol';
const base = `https://github.com/${repository}`;
// Keep the downloads paired with the screenshots and notes for this release.
const releaseTag = 'v0.13.0';
const links = {
 repo:base,
 release:`${base}/releases/tag/${releaseTag}`,
 windows:`${base}/releases/download/${releaseTag}/Extinction-Protocol-Windows-0.13.0.zip`,
 linux:`${base}/releases/download/${releaseTag}/Extinction-Protocol-Linux-0.13.0-UNVERIFIED.tar.gz`,
 feedback:`${base}/issues/new/choose`
};
document.querySelectorAll('[data-link]').forEach(link=>{link.href=links[link.dataset.link];});
const shots = [
 ['voss-0130','0.13.0 · Mara Voss in the Lost Cradle, with the first iteration of the new HUD.','Mara Voss fighting early enemies with an illustrated bottom HUD and minimap'],
 ['kael-0130','0.13.0 · Kael’s ancestral HUD in an early expedition.','Kael exploring the Lost Cradle with an amber and bone-themed HUD'],
 ['vesper-0130','0.13.0 · Vesper’s celestial HUD, framed in violet and gold.','Vesper in early gameplay with a celestial-themed HUD'],
 ['upgrades-0130','0.13.0 · New upgrade cards and matching Take and re-roll controls.','Three illustrated upgrade cards with improved reward previews'],
 ['boss','Basalt · A boss with a point to prove. Earlier development capture.','A molten dinosaur boss on a prehistoric battlefield'],
 ['frostbreak','The Ivory Shelf · Cold ground. Hot pursuit. Earlier development capture.','Snow-covered ruins and prehistoric creatures']
];
let current=0;
const active=document.querySelector('#active-shot'),large=document.querySelector('#large-shot'),dialog=document.querySelector('#lightbox'),thumbs=document.querySelector('#thumbnails');
shots.forEach((shot,i)=>{const button=document.createElement('button');button.type='button';button.setAttribute('aria-label',`Show screenshot ${i+1}: ${shot[1]}`);button.setAttribute('aria-pressed',String(i===0));const img=document.createElement('img');img.src=`assets/${shot[0]}-thumb.webp`;img.alt='';button.append(img);button.addEventListener('click',()=>select(i));thumbs.append(button);});
function select(index){current=(index+shots.length)%shots.length;const shot=shots[current];active.src=large.src=`assets/${shot[0]}.webp`;active.alt=large.alt=shot[2];document.querySelector('#shot-caption').textContent=document.querySelector('#large-caption').textContent=shot[1];document.querySelector('#image-counter').textContent=`${String(current+1).padStart(2,'0')} / ${String(shots.length).padStart(2,'0')}`;[...thumbs.children].forEach((button,i)=>button.setAttribute('aria-pressed',String(i===current)));}
document.querySelector('#expand-shot').addEventListener('click',()=>{select(current);dialog.showModal();});
document.querySelector('#close-lightbox').addEventListener('click',()=>dialog.close());
document.querySelector('#previous-shot').addEventListener('click',()=>select(current-1));
document.querySelector('#next-shot').addEventListener('click',()=>select(current+1));
dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});
document.addEventListener('keydown',event=>{const inGallery=dialog.open||document.activeElement.closest('.media');if(!inGallery)return;if(event.key==='ArrowRight'||event.key==='ArrowLeft'){event.preventDefault();select(current+(event.key==='ArrowRight'?1:-1));}});
select(0);
