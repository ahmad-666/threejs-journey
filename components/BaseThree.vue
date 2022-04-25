<template>
  <div class="width-100 fill-height d-flex justify-end">
    <canvas ref="canvas"></canvas>
  </div>
</template>
<script>
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
export default {
  data() {
    return {
      scene: null,
      camera: null,
      fov: 95,
      width: null,
      height: null,
      renderer: null,
      clock: new THREE.Clock(),
      controls: null,
      gui: null,
      ambientLight: null,
      directionalLight: null,
      debugObj: {
        envMapIntensity: 5,
      },
      gltfLoader: null,
      gltf: null,
      envMap: null,
      uTime: { value: 0 },
    };
  },
  computed: {
    aspectRatio() {
      return this.width / this.height;
    },
  },
  mounted() {
    const dat = require('dat.gui');
    this.gui = new dat.GUI();
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.createEnvMap();
    this.createScene();
    this.createMeshes();
    this.createLight();
    this.createCamera();
    this.createRenderer();
    this.animate();
    this.addGui();
    window.addEventListener('resize', this.windowResize);
    // window.addEventListener('dblclick', this.windowFullScreen);
  },
  beforeDestroy() {
    this.gui.destroy();
  },
  methods: {
    windowResize() {
      this.width = window.innerWidth;
      this.height = window.innerHeight;
      this.camera.aspect = this.width / this.height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(this.width, this.height);
      this.renderer.setPixelRatio(Math.min(2, window.devicePixelRatio));
    },
    async windowFullScreen() {
      const isFullScreen =
        document.fullscreenElement || document.webkitFullScreenElement;
      if (!isFullScreen) {
        if (this.$refs.canvas.requestFullscreen) {
          await this.$refs.canvas.requestFullscreen();
        } else if (this.$refs.canvas.webkitRequestFullscreen) {
          await this.$refs.canvas.webkitRequestFullscreen();
        }
      } else if (document.exitFullscreen) {
        document.exitFullscreen();
      } else {
        document.webkitExitFullscreen();
      }
    },
    createScene() {
      this.scene = new THREE.Scene();
      this.scene.background = this.envMap;
    },
    createCamera() {
      this.camera = new THREE.PerspectiveCamera(
        this.fov,
        this.aspectRatio,
        0.1,
        100
      );
      this.camera.position.z = -12; // we move camera backward
      this.controls = new OrbitControls(this.camera, this.$refs.canvas);
      this.controls.enableDamping = true;
      this.scene.add(this.camera);
    },
    createRenderer() {
      this.renderer = new THREE.WebGLRenderer({
        canvas: this.$refs.canvas,
        antialias: true,
      });
      this.renderer.setSize(this.width, this.height);
      this.renderer.setPixelRatio(Math.min(2, window.devicePixelRatio));
      this.renderer.render(this.scene, this.camera);
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      this.renderer.setSize(this.width, this.height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      this.renderer.physicallyCorrectLights = true;
      this.renderer.outputEncoding = THREE.sRGBEncoding;
      this.renderer.toneMapping = THREE.LinearToneMapping;
      this.renderer.toneMappingExposure = 1;
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    },
    createMeshes() {
      // we use realistic render code with Lee Perry Smith model
      // in prev examples model had embedded textures but in this example we have separate files for textures
      const textureLoader = new THREE.TextureLoader();
      this.gltfLoader = new GLTFLoader();
      this.gltfLoader.load('/models/LeePerrySmith/LeePerrySmith.glb', gltf => {
        // gltf.scene.scale.set(2, 2, 2);
        // gltf.scene.position.y = -2;
        gltf.scene.rotation.y = Math.PI;
        this.scene.add(gltf.scene);
        this.gltf = gltf;
        this.mapTexture = textureLoader.load('/models/LeePerrySmith/color.jpg');
        this.mapTexture.encoding = THREE.sRGBEncoding;
        this.normalTexture = textureLoader.load(
          '/models/LeePerrySmith/normal.jpg'
        );
        // MeshDepthMaterial (for handle shadows)
        // we see strange result for shadows because threejs use shadow map to handle shadows and in each render our own material will be replaced by MeshDepthMaterial and we rotate our own material but not rotate those materials
        // we create new MeshDepthMaterial rotate it and apply that on our MeshStandardMaterial
        const depthMaterial = new THREE.MeshDepthMaterial({
          depthPacking: THREE.RGBADepthPacking,
        });
        depthMaterial.onBeforeCompile = shader => {
          shader.uniforms.uTime = this.uTime;
          shader.vertexShader = shader.vertexShader.replace(
            '#include <common>',
            `#include <common>
            uniform float uTime;
             mat2 get2dRotationMatrix(float _angle){
               return mat2(cos(_angle),-sin(_angle),sin(_angle),cos(_angle));
             }
            `
          );
          shader.vertexShader = shader.vertexShader.replace(
            '#include <begin_vertex>',
            `#include <begin_vertex>
             float angle = position.y + uTime ; 
             mat2 rotateMatrix = get2dRotationMatrix(angle);
             transformed.xz *= rotateMatrix;
            `
          );
        };
        // now drop shadow is find but core shadow still has problems
        // core shadow has problems because of normals (normal show direction of outside of vertices and will help with light,shadow,reflection,...) and we need to rotate normals too
        // MeshStandardMaterial
        this.material = new THREE.MeshStandardMaterial({
          // create new material for applying our textures
          // if we use ShaderMaterial we need to create everything from start
          // we use built-in materials(MeshStandardMaterial) and just slightly change their code ... here we want to rotate vertices
          // we do that inside onBeforeCompile hook(event) of material
          map: this.mapTexture,
          normalMap: this.normalTexture,
        });
        this.material.onBeforeCompile = shader => {
          // if we see it won't execute maybe restart whole dev-server
          // we have shader.map,shader.aoMap,shader.alphaMap,...
          // shader.fragmentShader(string),shader.vertexShader(string),shader.uniforms(object)
          // all built-in shaders --> \node_modules\three\src\renderers\shaders
          // in 'ShaderChunk' folder we see those files that will #include inside shaders in 'ShaderLib' folder
          // for rotating vertices we need to change vertex shader and we use .replace method to do that
          // for change shaders of MeshStandardMaterial we change node_modules\three\src\renderers\shaders\ShaderLib\meshphysical.glsl.js we open it and we see bunch of include we want to change '#include <begin_vertex>'
          // we go to inside node_modules\three\src\renderers\shaders\ShaderChunk\begin_vertex.glsl.js and we see its code --> vec3 transformed = vec3( position )
          // shader.uniforms.uTime = { value: this.uTime }; //this is wrong because although this.uTime will be updated but this method execute only one time so we must use whole object as reference
          shader.uniforms.uTime = this.uTime; // this is wrong because although this.uTime will be updated but this method execute only one time
          shader.vertexShader = shader.vertexShader.replace(
            '#include <common>', // inside 'common' we have bunch of #define things and its a good place to inject so other values or methods
            `#include <common>
            uniform float uTime; //we must call uniform inside <common> because <begin-vertex> is inside main() method and uniforms must init outside of main
             mat2 get2dRotationMatrix(float _angle){
               return mat2(cos(_angle),-sin(_angle),sin(_angle),cos(_angle));
             }
            `
          );
          shader.vertexShader = shader.vertexShader.replace(
            // for rotate normals
            // inside beginnormal_vertex we have objectNormal
            // beginnormal_vertex and begin_vertex are in same scope so we have to be careful about two variables with same name and we just use matrix values from begin_vertex
            // we should keep the order and beginnormal_vertex is first and then begin_vertex(same order inside original vertexShader file)
            '#include <beginnormal_vertex>',
            `#include <beginnormal_vertex>
            //transformed.y += 3.0; --> we do it for test to see if it works  
             //here we use 2d matrix for get rotation values but we can do it without matrix too   
             float angle = position.y + uTime ; //we have position in vertexShader ... we relate rotate angle to elevation(y)
             //float angle = sin(position.y + uTime) * 0.2 ; 
             mat2 rotateMatrix = get2dRotationMatrix(angle);
             objectNormal.xz *= rotateMatrix;
            `
          );
          shader.vertexShader = shader.vertexShader.replace(
            '#include <begin_vertex>', // inside 'begin_vertex' we have 'transformed' and after #include we have access to it
            // for rotation we rotate y-axis base of elevation
            // vertex shader will execute for each vertex
            `#include <begin_vertex>       
             transformed.xz *= rotateMatrix;
            `
          );
        };
        const mesh = this.gltf.scene.children[0];
        mesh.material = this.material; // apply material with new textures
        mesh.customDepthMaterial = depthMaterial; // apply our own DepthMaterial
        this.applyMaterial();
        this.updateMaterials();
      });
    },
    createLight() {
      // this.ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
      // this.scene.add(this.ambientLight);
      this.directionalLight = new THREE.DirectionalLight(0xffffff, 3);
      this.directionalLight.castShadow = true;
      this.directionalLight.shadow.mapSize.set(1024, 1024);
      this.directionalLight.shadow.camera.far = 15;
      this.directionalLight.shadow.camera.left = -7;
      this.directionalLight.shadow.camera.top = 7;
      this.directionalLight.shadow.camera.right = 7;
      this.directionalLight.shadow.camera.bottom = -7;
      this.directionalLight.position.set(0.25, 3, -2.25);
      this.scene.add(this.directionalLight);
    },
    applyMaterial() {},
    updateMaterials() {
      this.scene.traverse(child => {
        if (
          child instanceof THREE.Mesh &&
          child.material instanceof THREE.MeshStandardMaterial
        ) {
          child.material.envMap = this.envMap;
          child.material.envMapIntensity = this.debugObj.envMapIntensity;
          child.material.needsUpdate = true;
          child.castShadow = true;
          child.receiveShadow = true;
        }
      });
    },
    animate() {
      // this.uTime = { value: this.clock.getElapsedTime() }; //wrong
      this.uTime.value = this.clock.getElapsedTime(); // true
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    createEnvMap() {
      const cubeTextureLoader = new THREE.CubeTextureLoader();
      this.envMap = cubeTextureLoader.load([
        '/environmentMaps/0/px.jpg',
        '/environmentMaps/0/nx.jpg',
        '/environmentMaps/0/py.jpg',
        '/environmentMaps/0/ny.jpg',
        '/environmentMaps/0/pz.jpg',
        '/environmentMaps/0/nz.jpg',
      ]);
      this.envMap.encoding = THREE.sRGBEncoding;
    },
    addGui() {},
  },
};
</script>
