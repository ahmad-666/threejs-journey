uniform float uSize;
attribute float aSizeRandomness;
uniform float uTime;
attribute vec3 aRandomness ;
//attribute vec3 color; //if we use it we face redefinition error because we use ShaderMaterial and inside that we use vertexColor: true and we will adding this attribute automatically
varying vec3 vColor;
void main(){
    vec4 modelPos = modelMatrix * vec4(position,1.0);
    //animation: we want our galaxy to be rotated 
    //we want particles near to center rotate faster 
    //1-calc distance,angle of each particle to center of galaxy
    //2-increase angle related to uTime
    float distToCenter = length(modelPos.xz) ;
    float angle = atan(modelPos.x,modelPos.z) + (1.0 / distToCenter) * uTime * 0.2 ;
    //atan for find angle in space ... we add that angle to some value 
    //we use 1.0/distToCenter because we want less distance rotate with more speed
    modelPos.x = cos(angle) * distToCenter;
    modelPos.z = sin(angle)  * distToCenter;
    modelPos.xyz += aRandomness ;
    vec4 viewPos = viewMatrix * modelPos;
    vec4 projectionPos = projectionMatrix * viewPos;
    gl_Position = projectionPos ;
    gl_PointSize = uSize * aSizeRandomness; //we must use it when dealing with particles and its fragment size 
    gl_PointSize *= ( 1.0 / - viewPos.z ); //add it for sizeAttenuation
    vColor = color ;
}