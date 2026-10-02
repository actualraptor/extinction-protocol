const repository = document.documentElement.dataset.repository || 'actualraptor/extinction-protocol';
const releaseTag = 'v0.9.3';
const base = `https://github.com/${repository}`;
// The v0.9.3 release currently contains binaries exported with the 0.9.2
// filenames. Keep the asset names explicit until the next release is renamed.
const links = {
 repo:base,
 release:`${base}/releases/tag/${releaseTag}`,
 windows:`${base}/releases/download/${releaseTag}/Extinction-Protocol-Windows-0.9.2.zip`,
 linux:`${base}/releases/download/${releaseTag}/Extinction-Protocol-Linux-0.9.2.tar.gz`,
 feedback:`${base}/issues/new/choose`
};
document.querySelectorAll('[data-link]').forEach(link=>{link.href=links[link.dataset.link];});
const shots = [
 ['observatory','The Unmade Sky · Fight your way through a world coming apart.','A survivor surrounded by mutated creatures in the Unmade Sky'],
 ['boss','Basalt Behemoth · A boss with a point to prove.','A molten dinosaur boss on a prehistoric battlefield'],
 ['frostbreak','The Ivory Shelf · Cold ground. Hot pursuit.','Snow-covered ruins and prehistoric creatures'],
 ['upgrades','Choose your power · Build something unreasonable.','Three fossil-framed weapon upgrade cards'],
 ['survivors','Five survivors · Five ways to defy extinction.','The five playable survivor characters'],
 ['expedition','The expedition · Read the battlefield. Keep moving.','Top-down expedition gameplay with monsters and weapons']
];
let current=0;
const active=document.querySelector('#active-shot'),large=document.querySelector('#large-shot'),dialog=document.querySelector('#lightbox'),thumbs=document.querySelector('#thumbnails');
shots.forEach((shot,i)=>{const button=document.createElement('button');button.type='button';button.setAttribute('aria-label',`Show screenshot ${i+1}: ${shot[1]}`);button.setAttribute('aria-pressed',String(i===0));const img=document.createElement('img');img.src=`assets/${shot[0]}-thumb.webp`;img.alt='';button.append(img);button.addEventListener('click',()=>select(i));thumbs.append(button);});
function select(index){current=(index+shots.length)%shots.length;const shot=shots[current];active.src=large.src=`assets/${shot[0]}.webp`;active.alt=large.alt=shot[2];document.querySelector('#shot-caption').textContent=document.querySelector('#large-caption').textContent=shot[1];document.querySelector('#image-counter').textContent=`${String(current+1).padStart(2,'0')} / 06`;[...thumbs.children].forEach((button,i)=>button.setAttribute('aria-pressed',String(i===current)));}
document.querySelector('#expand-shot').addEventListener('click',()=>{select(current);dialog.showModal();});
document.querySelector('#close-lightbox').addEventListener('click',()=>dialog.close());
document.querySelector('#previous-shot').addEventListener('click',()=>select(current-1));
document.querySelector('#next-shot').addEventListener('click',()=>select(current+1));
dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});
document.addEventListener('keydown',event=>{const inGallery=dialog.open||document.activeElement.closest('.media');if(!inGallery)return;if(event.key==='ArrowRight'||event.key==='ArrowLeft'){event.preventDefault();select(current+(event.key==='ArrowRight'?1:-1));}});
select(0);
