const statuses={'in-progress':['In progress','#d8b76e'],improve:['Needs improvement','#c89771'],planned:['Planned','#9daccc'],done:['Done','#87b99a']};
const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text)n.textContent=text;if(cls)n.className=cls;return n;};
fetch('roadmap.json').then(r=>{if(!r.ok)throw Error('Board unavailable');return r.json();}).then(data=>{
 document.querySelector('#board-meta').textContent=`Updated ${data.updated} · Public playtest ${data.release}`;
 document.querySelector('#board-policy').textContent=data.policy;
 const board=document.querySelector('#board');board.replaceChildren();
 for(const [status,[label,color]] of Object.entries(statuses)){
  const column=el('section',null,'roadmap-column');column.dataset.status=status;column.style.setProperty('--status-color',color);
  const cards=data.cards.filter(c=>c.status===status);const heading=el('h2',label);heading.append(el('span',String(cards.length)));column.append(heading);
  for(const c of cards){const card=el('article',null,'roadmap-card');card.id=c.id;card.append(el('span',label,'status-tag'),el('h3',c.title),el('p',c.summary),el('p',c.next,'next'));column.append(card);}board.append(column);
 }
 for(const entry of data.devlog){const article=el('article');article.append(el('time',entry.date),el('h3',entry.title),el('p',entry.body));document.querySelector('#entries').append(article);}
 document.querySelectorAll('[data-filter]').forEach(button=>button.addEventListener('click',()=>{const filter=button.dataset.filter;document.querySelectorAll('[data-filter]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));document.querySelectorAll('.roadmap-column').forEach(c=>c.hidden=filter!=='all'&&c.dataset.status!==filter);board.classList.toggle('filtered',filter!=='all');}));
}).catch(()=>{document.querySelector('#board').replaceChildren(el('p','The board could not load. Read the GitHub roadmap using the link above.'));});
