#define PROCESSING_TEXTURE_SHADER

uniform sampler2D camSampler;
uniform sampler2D imgSampler;
//<
uniform sampler2D u_Texture1;
//>
uniform ivec2 camSize;
uniform ivec4 camRect;

uniform ivec2 imgSize;
uniform ivec4 imgRect;

varying vec4 vertTexCoord;

uniform float threshold;
uniform float camscalex;
uniform float camscaley;
uniform float alpha;
uniform float instamix;
uniform int instamode;

uniform float T_bright;
uniform float T_contrast;
uniform float T_saturation;
uniform float colmult;

uniform float plusr;
uniform float plusg;
uniform float plusb;

//<
const vec3 W = vec3(0.2125, 0.7154, 0.0721);

vec3 BrightnessContrastSaturation(vec3 color, float brt, float con, float sat)
{
    vec3 black = vec3(0., 0., 0.);
    vec3 middle = vec3(0.5, 0.5, 0.5);
    float luminance = dot(color, W);
    vec3 gray = vec3(luminance, luminance, luminance);
    
    vec3 brtColor = mix(black, color, brt);
    vec3 conColor = mix(middle, brtColor, con);
    vec3 satColor = mix(gray, conColor, sat);
    return satColor;
}

vec3 ovelayBlender(vec3 Color, vec3 filterr){
    vec3 filter_result;
    float luminance = dot(filterr, W);
    
    if(luminance < 0.5)
        filter_result = 2. * filterr * Color;
    else
        filter_result = 1. - (1. - (2. *(filterr - 0.5)))*(1. - Color);
    
    return filter_result;
}

vec3 multiplyBlender(vec3 Color, vec3 filterr){
    vec3 filter_result;
    float luminance = dot(filterr, W);
    
    if(luminance < 0.5)
        filter_result = 2. * filterr * Color;
    else
        filter_result = Color;
    
    return filter_result;
}
//>




void main() {

    //COORDS------------------------------------------------------------------
    
    vec2 st_cam = vec2(1.0 - vertTexCoord.s, vertTexCoord.t);
    vec2 st_img = vertTexCoord.st;

    vec2 scaleVector = vec2( camscalex, camscaley);
    vec2 fromCenter = st_cam.st - vec2(.5,.5);
    vec2 scaledFromCenter = fromCenter*scaleVector;
    vec2 resultCoordinate = vec2(.5,.5) + scaledFromCenter * vec2(1.0, 1.00);
    
    vec2 camvec = resultCoordinate;
    vec2 imgvec = st_img;

    //------------------------------------------------------------------------
    
    vec3 camColor = texture2D(camSampler, camvec).rgb;
    vec3 imgColor = texture2D(imgSampler, imgvec).rgb;
  
    float luminance = dot(vec3(0.2126, 0.7152, 0.0722), camColor);
    
    camColor = vec3(luminance, luminance, luminance);

    
    if( instamode == 0 ) {
        if (luminance < threshold) {
            gl_FragColor = vec4(2.0 * camColor * imgColor, alpha);
        } else {
            gl_FragColor = vec4(1.0 - 2.0 * (1.0 - camColor) * (1.0 - imgColor), alpha);
        }
        return;
    } else {
        
        //-------------------------------------------------------------------
        if (luminance < threshold) {
            camColor = vec3(2.0 * camColor * imgColor);
        } else {
            camColor = vec3(1.0 - 2.0 * (1.0 - camColor) * (1.0 - imgColor));
        }
        
        vec2 st = st_cam;
        vec3 filterr = texture2D(u_Texture1, st).rgb;
        vec3 irgb = camColor;
        //-------------------------------------------------------------------
        //HATCH
        
        /*
        //irgb = vec3(1.0, 1.0, 1.0);
        
        if (luminance < 1.00) {
            if (mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) == 0.0) {
                irgb = vec3(0.0, 0.0, 0.0);
                //irgb = camColor;
            }
        }
        if (luminance < 0.75) {
            if (mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) == 0.0) {
                irgb = vec3(0.0, 0.0, 0.0);
                //irgb = camColor;
            }
        }
        if (luminance < 0.50) {
            if (mod(gl_FragCoord.x + gl_FragCoord.y - 5.0, 10.0) == 0.0) {
                irgb = vec3(0.0, 0.0, 0.0);
                //irgb = camColor;
            }
        }
        if (luminance < 0.3) {
            if (mod(gl_FragCoord.x - gl_FragCoord.y - 5.0, 10.0) == 0.0) {
                irgb = vec3(0.0, 0.0, 0.0);
                //irgb = camColor;
            }
        }
         */
        
        
        //-------------------------------------------------------------------
        
        if( instamode == 1 ) {                              //EARLYBIRD
            vec3 bcs_result = BrightnessContrastSaturation(irgb, T_bright, T_contrast, T_saturation);
            vec3 rb_result = vec3(bcs_result.r*plusr, bcs_result.g*plusg, bcs_result.b*plusb);
            vec3 after_filter = mix(rb_result, multiplyBlender(rb_result, filterr), instamix); //0.8
        
            gl_FragColor = vec4(after_filter, alpha);
            return;
            
        } else if( instamode == 2 ) {                       //AMARO
            vec3 bcs_result = BrightnessContrastSaturation(irgb, T_bright, T_contrast, T_saturation);
            vec3 blue_result = vec3(bcs_result.r*plusr, bcs_result.g*plusg, bcs_result.b*plusb);
            vec3 after_filter = mix(blue_result, ovelayBlender(blue_result, filterr), instamix); //0.6
            
            gl_FragColor = vec4(after_filter, alpha);
            return;
            
        }  else if( instamode == 3 ) {                      //XPRO
            vec3 bcs_result = BrightnessContrastSaturation(irgb, T_bright, T_contrast, T_saturation);
            vec3 col_result = vec3(bcs_result.r*plusr, bcs_result.g*plusg, bcs_result.b*plusb);
            vec3 after_filter = mix(col_result, multiplyBlender(col_result, filterr), instamix); //0.7
            
            gl_FragColor = vec4(after_filter, alpha);
            return;
        }
    }

}
