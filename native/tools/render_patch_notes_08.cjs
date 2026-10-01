const {chromium}=require('C:/Users/Gullberg/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path=require('path');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const page=await browser.newPage({viewport:{width:1800,height:1200},deviceScaleFactor:1});
 await page.goto('file:///'+path.resolve('dist/patch-notes-0.8/patch-notes.html').replace(/\\/g,'/'));
 await page.evaluate(()=>document.fonts.ready);
 await page.screenshot({path:'dist/Extinction-Protocol-0.8-Full-Patch-Notes.png',fullPage:true});
 const dimensions=await page.evaluate(()=>({width:document.documentElement.scrollWidth,height:document.documentElement.scrollHeight,sections:document.querySelectorAll('section').length,overflow:[...document.querySelectorAll('table,.change-copy,section')].filter(e=>e.scrollWidth>e.clientWidth+1).length}));
 console.log(JSON.stringify(dimensions));
 for(const [name,y] of [['top',0],['middle',Math.floor(dimensions.height*.48)],['bottom',dimensions.height-1200]])await page.screenshot({path:'dist/patch-notes-0.8/preview-'+name+'.png',fullPage:true,clip:{x:0,y,width:1800,height:1200}});
 await browser.close();
})();

