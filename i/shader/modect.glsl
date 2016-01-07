uniform sampler2D destSampler;
uniform sampler2D srcSampler;

uniform ivec2 destSize;
uniform ivec4 destRect;

uniform ivec2 srcSize;
uniform ivec4 srcRect;

uniform float contrast;

varying vec4 vertTexCoord;

const vec3 luma = vec3(0.2125, 0.7154, 0.0721);

int count = 0;

vec3 ContrastSaturationBrightness(vec3 color, float brt, float sat, float con)
{
    // Increase or decrease theese values to adjust r, g and b color channels seperately
    const float AvgLumR = 0.5;
    const float AvgLumG = 0.5;
    const float AvgLumB = 0.5;
    
    vec3 AvgLumin = vec3(AvgLumR, AvgLumG, AvgLumB);
    vec3 brtColor = color * brt;
    vec3 intensity = vec3(dot(brtColor, luma));
    vec3 satColor = mix(intensity, brtColor, sat);
    vec3 conColor = mix(AvgLumin, satColor, con);
    return conColor;
}

void main() {
    vec2 st = vertTexCoord.st;
    
    vec3 nowColor = texture2D(destSampler, st).rgb;
    vec3 preColor = texture2D(srcSampler, st).rgb;

    vec3 nowContr = ContrastSaturationBrightness(nowColor, 1.0, 1.0, contrast);
    vec3 preContr = ContrastSaturationBrightness(preColor, 1.0, 1.0, contrast);

    float nowLuma = dot(nowContr, luma);
    float preLuma = dot(preContr, luma);
    
    float diff = nowLuma-preLuma;
    
    //gl_FragColor = vec4(nowLuma, nowLuma, nowLuma, 1);
    
    if(diff > 0.5) {
        gl_FragColor = vec4(1, 1, 1, 1);
    } else {
        gl_FragColor = vec4(0, 0, 0, 1);
    }
    
}