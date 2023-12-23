// Ported from: https://www.shadertoy.com/view/Wtl3D7

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float time;
out vec4 fragColor;


#define PI 3.1415926

float rand(float t)
{
    return fract(sin(dot(vec2(t,t) ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void) {
    vec2 fragCoord = FlutterFragCoord();
    
	vec2 uv=(fragCoord.xy*2.0-uSize.xy)/uSize.y;
 	vec2 uv1=uv-vec2(0.8,.4);
    float r = length(uv1)*111.;
    
    float t = ceil(r);
    float rt = rand(t);
    float a = fract(atan(uv1.y, uv1.x)/PI+time*rt*.1 +t*0.1);

    float ang = rt;
    float c = smoothstep(ang,ang-1.5,a*5.) ;
    
    vec3 col = vec3(.3,0.3,.5)*3.;
    float rr = length(uv-vec2(0.6,1.4))-0.8;
	vec3 coll=vec3(0.,rr*0.1,rr*0.24);
    
    coll=mix(coll,col*rt,c*step(0.1,r/111.));

    
    fragColor=vec4(coll,1.0);
}