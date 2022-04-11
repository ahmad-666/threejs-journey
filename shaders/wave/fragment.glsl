uniform vec3 uDepthColor;
uniform vec3 uSurfaceColor;
varying float vElevation ;
uniform float uColorOffset;
uniform float uColorMultiplier;
void main(){
    //vec3 color = mix(uDepthColor,uSurfaceColor,vElevation * 5.0);
    //we mix color related to elevation
    //vElevation === uWaveAmp * sin(modelPos.x * uWaveFreq.x + uTime * uWaveSpeed.x) * sin(modelPos.z * uWaveFreq.y + uTime * uWaveSpeed.y)
    //means its from [-uWaveAmp,uWaveAmp] so we create uColorOffset,uColorMultiplier to tweak mix strength 
    float mixColorStrength = (vElevation + uColorOffset) * uColorMultiplier ;
    //first we use + inside () then multiplier
    vec3 color = mix(uSurfaceColor,uDepthColor,mixColorStrength);
    gl_FragColor = vec4(color,1.0) ;
}