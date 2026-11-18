const assert = require('assert');
const fs = require('fs');
const vm = require('vm');

const html = fs.readFileSync('esx_realestate/html/housing_tv.html', 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
function player() {
  let receive;
  const frame = {hidden:true, src:''};
  const video = {hidden:true, src:'', currentTime:0, play:()=>Promise.resolve(), addEventListener:(_,fn)=>{video.loaded=fn}};
  const document = {getElementById:id => id === 'embed' ? frame : video};
  vm.runInNewContext(script, {document, URL, window:{addEventListener:(_,fn)=>{receive=fn}}});
  return {frame,video,receive};
}
let a=player(); a.receive({data:{action:'play',provider:'aparat',video:'BNMK5'}});
assert.equal(a.frame.src,'https://www.aparat.com/video/video/embed/videohash/BNMK5/vt/frame?autoplay=true');
let b=player(); b.receive({data:{action:'play',provider:'direct',video:'https://cdn.example.com/movie.mp4?x=1',elapsed:12}});
assert.equal(b.video.src,'https://cdn.example.com/movie.mp4?x=1'); b.video.loaded(); assert.equal(b.video.currentTime,12);
let c=player(); c.receive({data:{action:'play',provider:'direct',video:'https://127.0.0.1/secret.mp4'}}); assert.equal(c.video.src,'');
let d=player(); d.receive({data:{action:'play',provider:'vimeo',video:'123'}}); assert(d.frame.src.includes('player.vimeo.com/video/123'));

const handlers={}, formHandlers={};
const input={value:'',focus(){this.focused=true}};
const cancel={addEventListener:(type,fn)=>handlers['cancel:'+type]=fn};
const form={addEventListener:(type,fn)=>formHandlers[type]=fn};
const panel={hidden:true,querySelector:()=>form};
let sent;
const document={getElementById:id=>id==='housing-tv-input'?panel:id==='housing-tv-url'?input:cancel};
const window={addEventListener:(name,fn)=>handlers[name]=fn};
const fetch=(url,data)=>{sent={url,data};return Promise.resolve({json:()=>Promise.resolve({ok:true})})};
vm.runInNewContext(fs.readFileSync('esx_realestate/html/js/housing_tv_input.js','utf8'),{document,window,fetch,GetParentResourceName:()=> 'housing',setTimeout:fn=>fn()});
handlers.message({data:{action:'HousingTVInput',open:true}}); assert(!panel.hidden && input.focused);
input.value=' https://www.aparat.com/v/BNMK5 ';
formHandlers.submit({preventDefault(){}});
assert(sent.url.endsWith('/housingTV:submit')); assert.equal(JSON.parse(sent.data.body).url,'https://www.aparat.com/v/BNMK5');
console.log('TV player providers and pasted input UI passed');
