#define S(a,b,t) smoothstep(a,b,t)

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float iTime;
out vec4 fragColor;


float DistLine(vec2 p, vec2 a, vec2 b){
    vec2 pa = p-a;
    vec2 ba = b-a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    return length(pa -ba *t);
}

float Line(vec2 p, vec2 a, vec2 b){
    float d = DistLine(p,a,b);
    float d2= length(a-b);
    float m = S(.02, .001, d);
    m *= S(1.2, .001, length(a-b)) *.5 + S(.1, .03, abs(d2-.75));
     return m;
}

float N21(vec2 p){
    p = fract(p*vec2(233.213, 853.23));
    p += dot(p, p+23.24);
    return fract(p.x*p.y);
}

vec2 N22(vec2 p){
    float n = N21(p);
    return vec2(n, N21(p+n));
}

vec2 GetPos(vec2 id, vec2 off){
    vec2 n = N22(id + off) * iTime;
    return off + sin(n) *.4;
}

float Layer(vec2 uv){


    vec2 gv = fract(uv) -.5;
    vec2 id = floor(uv);
    float m = 0.;

    vec2 p[9];
    int i = 0;
    

    p[0] = GetPos(id, vec2(-1., -1.));
    p[1] = GetPos(id, vec2(0., -1.));
    p[2] = GetPos(id, vec2(1., -1.));

    p[3] = GetPos(id, vec2(-1., 0.));
    p[4] = GetPos(id, vec2(0., 0.));
    p[5] = GetPos(id, vec2(1., 0.));

    p[6] = GetPos(id, vec2(-1., 1.));
    p[7] = GetPos(id, vec2(0., 1.));
    p[8] = GetPos(id, vec2(1., 1.));


    float t=iTime* 5.;
    

    for(int i = 0; i < 9;i++)
    {
        m += Line(gv, p[4], p[i]);
        
        vec2 j = (p[i] - gv) *30.;
        float sparkle =  1./dot(j, j);
        
        m+= sparkle*(sin(t+fract(p[i].x)*10.)*.5 + .5);
    }
    
     m += Line(gv, p[1], p[3]);
     m += Line(gv, p[1], p[5]);
     m += Line(gv, p[3], p[7]);
     m += Line(gv, p[5], p[7]);
     
     return m;
}


void main( void )
{
    vec2 fragCoord = FlutterFragCoord();
    
	vec2 uv=(fragCoord.xy-uSize.xy)/uSize.y;


    //zoom
    uv *= 2.;
    float m = 0.;
    float t = iTime * .07;
    float s = sin(t);
    float c = cos(t);
    mat2 rot = mat2(c, -s, s, c);

    uv *= rot;
    
    for(float i=0.;i<1.;i+= 1./4.){
        float z = fract(i+t);
        float size = mix(10., .5, z);
        float fade = S(0., .9, z) * S(1., .8, z);
        
        m += Layer(uv * 1.2 * size + i*24.) * fade;
    }

    vec3 col = vec3(.04, .04, .1) + ((vec3(0.2*m, 0.2*m, 0.1*m)));

    fragColor = vec4(col,1.0);
}