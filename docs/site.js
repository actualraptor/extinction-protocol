const repository = document.documentElement.dataset.repository || 'actualraptor/extinction-protocol';
const base = `https://github.com/${repository}`;
// Keep the downloads paired with the screenshots and notes for this release.
const releaseTag = 'v0.14.2';
const links = {
 repo:base,
 release:`${base}/releases/tag/${releaseTag}`,
 windows:`${base}/releases/download/${releaseTag}/Extinction-Protocol-Windows-0.14.2.zip`,
 linux:`${base}/releases/download/${releaseTag}/Extinction-Protocol-Linux-0.14.2-UNVERIFIED.tar.gz`,
 feedback:`${base}/issues/new/choose`
};
document.querySelectorAll('[data-link]').forEach(link=>{link.href=links[link.dataset.link];});
const shots = [
 ['voss-hordes-ui','Development preview · Mara Voss: gunfire and orbiting blades against the horde.','Mara Voss fighting a horde with revolver shots and orbiting blades'],
 ['vesper-elements-ui','Development preview · Vesper: lightning, frost and fire in one build.','Vesper combining elemental attacks with the integrated celestial HUD'],
 ['kael-cleave-ui','Development preview · Kael: close-range cleaves and a moving blade barrier.','Kael fighting ordinary prehistoric hordes with his ancestral HUD'],
 ['voss-thermal-ui','Development preview · Mara Voss: fire, ice and bombardment.','Mara Voss using several elemental and ranged abilities against enemies'],
 ['vesper-orbits-ui','Development preview · Vesper: lightning and orbiting blades.','Vesper fighting a horde with violet lightning and green orbiting blades'],
 ['kael-blades-ui','Development preview · Kael: firepower meets close combat.','Kael combining his club with ranged attacks and orbiting blades'],
 ['discoveries','Development preview · Discoveries: a clear grid of unlocks and equipment.','The redesigned Discoveries grid'],
 ['expedition','Development preview · A stampede crosses a live expedition.','Compys rushing through an active expedition'],
 ['main-menu','Development preview · The official logo and redesigned main menu.','Extinction Protocol main menu']
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
