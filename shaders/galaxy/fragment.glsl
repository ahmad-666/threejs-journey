varying vec3 vColor;
void main(){
    //here we can change shape of each fragment(particle) with help of shader patterns
    //because we are using particles our geometry is THREE.BufferGeometry we cannot use uv here 
    //but we have gl_PointCoord
    //gl_FragColor = vec4(1.0,1.0,1.0,1.0) ;
    //gl_FragColor = vec4(gl_PointCoord,1.0,1.0) ; //same green,red,blue gradient as uv for each particle 
    //we can remove blending property inside material to see more of its effect
    //just like shader pattern section that we uses uv to draw pattern on each fragment here we use gl_PointCoord to draw patten inside each fragment(particle)
    //we want to create disk patten on each fragment:
    //1-calc distance between gl_FragColor and center 
    //2-use step to return 0.0 if distance is bellow 0.5 and 1.0 else
    //3-invert value
    // float dist = distance(gl_PointCoord,vec2(0.5));
    // float strength = step(0.5,dist) ;
    // strength = 1.0 - strength ; 
    // gl_FragColor = vec4(vec3(strength),1.0) ;
    //for create diffuse disk (disk with fade effect on edges)
    //1-calc distance between gl_FragColor and center
    //2-multiply by 2 to it reaches white sooner 
    //3-invert value 
    // float dist = distance(gl_PointCoord,vec2(0.5));
    // float strength = dist * 2.0 ;
    // strength = 1.0 - strength ;
    // gl_FragColor = vec4(vec3(strength),1.0) ;
    //for apply light point pattern:
    //1-calc distance between gl_FragColor and center
    //2-invert value 
    //3-apply power on it
    // float dist = distance(gl_PointCoord,vec2(0.5));
    // float strength = 1.0 - dist ;
    // strength = pow(strength,10.0) ; //for values between [0,1] power make them smaller
    // gl_FragColor = vec4(vec3(strength),1.0) ;
    //all above pattern only show black,white colors for apply color --> inside .js file we provide rgb values for each particle and send it via attributes of geometry and send those with varying to fragment 
    //light point with coloring 
    float dist = distance(gl_PointCoord,vec2(0.5));
    float strength = 1.0 - dist ;
    strength = pow(strength,10.0) ; 
    vec3 colors = mix(vec3(0.0),vColor,strength); //base on strength we mix vColor with vec3(0.0)
    gl_FragColor = vec4(vec3(colors),1.0) ;
}