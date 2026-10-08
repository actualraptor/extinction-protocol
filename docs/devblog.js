const element=(tag,text,cls)=>{const node=document.createElement(tag);if(text)node.textContent=text;if(cls)node.className=cls;return node;};
fetch('roadmap.json').then(response=>{if(!response.ok)throw Error('Unavailable');return response.json();}).then(data=>{
 const posts=document.querySelector('#posts');posts.replaceChildren();
 for(const entry of data.devlog){
  const article=element('article',null,'blog-entry');article.id=entry.id;
  const time=element('time',entry.date);time.dateTime=entry.date;article.append(time,element('span',entry.stage||'Development update','blog-stage'),element('h2',entry.title),element('p',entry.body));
  for(const [key,label] of [['changed','What changed'],['testing','How we checked it'],['learned','What we learned'],['next','Next steps']])if(entry[key])article.append(element('h3',label),element('p',entry[key]));
  if(entry.card){const link=element('a','Follow this work on the roadmap →');link.href=`roadmap.html#${encodeURIComponent(entry.card)}`;article.append(link);}posts.append(article);
 }
}).catch(()=>{const link=element('a','Read the devblog on GitHub');link.href='https://github.com/actualraptor/extinction-protocol/blob/main/DEVBLOG.md';document.querySelector('#posts').replaceChildren(link);});
