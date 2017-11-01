#version 330

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform vec3 spectrum;
uniform sampler2D texture0;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D prevFrame;

#define MAX_STEP 32.0
#define ep 0.01
#define ep_shadow 0.5
#define PI 3.141592654
#define SHADOW_SCALE 8.0

struct Material

vec2 hash( vec2 p ) {
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p ) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
    vec2 i = floor(p + (p.x+p.y)*K1);   
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));  
}

#define OCTAVES 8
float fbm(in vec2 st)
{
    float value=0.0;
    float amplitude=0.5;
    float frequency=2.0;

    for(int i=0; i<OCTAVES; i++)
    {
        value+=amplitude*noise(st*frequency);
        st*=2.0;
        amplitude*=0.5;
    }
    
    return value;
}

float fbm2(in vec2 st, float intensity, float frequency,float density, int detail)
{
    float value=0.0;
    float amplitude=0.5;

    for(int i=0; i<detail; i++)
    {
        value+=amplitude*noise(st*frequency);
        st*=density;
        amplitude*=intensity;
    }
    
    return value;
}

float smooth_min(float a, float b)
{
    float res=exp(-32.0*a)+exp(-32.0*b);
    return -log(max(0.0001, res))/32.0;

}


in VertexData
{
    vec4 v_position;
    vec3 v_normal;
    vec2 v_texcoord;
} inData;

out vec4 fragColor;


void main(void)
{
    vec2 uv=-1.0+2.0*gl_FragCoord.xy/resolution.y-vec2(0.5,0.0);
    vec3 origin=vec3(0.0,0.0,-5.0);
    vec3 dir=normalize(vec3(uv, 1.0));
    vec3 color;

    
    //uv, intensity, frequency, density, detail
    float sub_cloud=fbm2(uv*1.03+vec2(time*0.01,-0.14*time), 0.21, 1.0, 1.984, 32);
    float ddxy=fbm2(uv*2.41+vec2(0.08*time,-0.15*time), 0.68, 0.52, 1.63, 32);
    float dirt=fbm2(uv*0.71+vec2(0.11*time,-0.15*time), 0.62, 0.65,1.36, 32);
    float c2=fbm2(uv*0.59+vec2(0.04*time,-0.027*time),0.46, 0.69,2.0, 4);
    
    color=vec3(0.94*sub_cloud*dirt*ddxy-1.41*ddxy-0.992*dirt-2.43*c2)*vec3(-0.94,-3.1,-0.2)+vec3(0.38,0.26,1.84) -3.8*dirt*vec3(0.1,0.6,0.1);
    color-=vec3(0.35,0.8,0.61);
    color+=vec3(0.1,0.2,0.01)*(uv.y+1.0);
    //fragColor=vec4(color, 1.0);
    fragColor=vec4(color,1.0);
}