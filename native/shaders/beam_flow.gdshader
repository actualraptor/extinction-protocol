shader_type canvas_item;
render_mode unshaded;
uniform float age=0.0;
uniform float seed=0.0;
uniform float envelope=1.0;
uniform int mode=0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){float n=0.0;float a=.55;for(int i=0;i<4;i++){n+=noise(p)*a;p=mat2(vec2(1.6,1.2),vec2(-1.2,1.6))*p;a*=.5;}return n;}
void fragment(){
 float x=UV.x;float y=(UV.y-.5)*2.0;float t=age;
 vec2 drift=vec2(fbm(vec2(x*5.0-t*2.8,y*2.0+seed)),fbm(vec2(x*6.0-t*3.2,y*2.8+seed+7.0)))-.5;
 vec2 flow=vec2(x*8.0-t*5.4,y*3.4+seed)+drift*.85;
 float n=fbm(flow);float folds=fbm(flow*2.0+vec2(-t*1.4,t*.65));
 float nose=smoothstep(0.0,.025,x);float end=1.0-smoothstep(.87,1.0,x);
 vec3 rgb;float alpha;
 if(mode==0){
  float center=sin(x*7.0-t*5.5+seed)*.055*x+drift.y*.10*x;
  float radius=.06+smoothstep(.0,.73,x)*.47;
  float roll=radius*(.75+n*.55);
  // Elliptical end cap: the expanding jet closes as a round billow.
  float cap=max(0.0,(x-.77)/.215);
  float radial=sqrt(pow((y-center)/max(.04,roll),2.0)+cap*cap);
  float edge=1.0-radial+(folds-.5)*.20;
  float body=smoothstep(-.06,.07,edge);
  float hot=clamp((1.0-abs(y-center)/max(.06,roll))*.43+n*.58+folds*.32,0.0,1.0);
  rgb=mix(vec3(.5,.025,.005),vec3(1.0,.23,.015),smoothstep(.1,.5,hot));
  rgb=mix(rgb,vec3(1.0,.79,.14),smoothstep(.45,.82,hot));
  rgb=mix(rgb,vec3(1.0,.98,.7),smoothstep(.82,1.0,hot));
  float glow=exp(-radial*4.5)*.17;
  alpha=max(body*.95,glow)*nose*(1.0-smoothstep(.985,1.0,x))*envelope;
 }else{
  float curve=sin(x*12.0-t*8.0+seed)*.08*sin(x*3.14159)+sin(x*23.0+t*4.0)*.035;
  float width=(mode==2?.12:.23)*(1.0+n*.5);
  float d=abs(y-curve);
  float liquid=smoothstep(width+.025,width-.025,d+(folds-.5)*.08);
  float core=exp(-d*35.0)*(mode==2?.9:.65);
  float pulse=pow(max(0.0,sin(x*35.0-t*22.0+seed)),6.0)*liquid;
  float strand=exp(-abs(y-curve-sin(x*20.0-t*11.0)*.07)*70.0);
  rgb=mix(vec3(.36,.08,.8),vec3(.05,.84,.69),liquid*.75+folds*.2);
  rgb=mix(rgb,vec3(.76,1.0,.93),clamp(core+strand*.38+pulse*.45,0.0,1.0));
  alpha=max(liquid*.82,max(exp(-d*6.0)*.22,strand*.75))*nose*end*envelope;
 }
 COLOR=vec4(rgb,alpha);
}
