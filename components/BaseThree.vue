<template>
  <div class="width-100 fill-height d-flex justify-end">
    <canvas ref="canvas"></canvas>
  </div>
</template>
<script>
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import vertexShader from '~/shaders/wave/vertex.glsl';
import fragmentShader from '~/shaders/wave/fragment.glsl';
export default {
  data() {
    return {
      scene: null,
      camera: null,
      fov: 95,
      width: null,
      height: null,
      renderer: null,
      controls: null,
      gui: null,
      geometry: null,
      material: null,
      mesh: null,
      clock: new THREE.Clock(),
      debugObj: {
        depthColor: '#371be9',
        surfaceColor: '#7dd1c3',
      },
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
    this.createScene();
    this.createCamera();
    this.createMesh();
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
    },
    createCamera() {
      this.camera = new THREE.PerspectiveCamera(
        this.fov,
        this.aspectRatio,
        0.1,
        100
      );
      this.camera.position.z = 1;
      this.controls = new OrbitControls(this.camera, this.$refs.canvas);
      this.controls.enableDamping = true;
      this.scene.add(this.camera);
    },
    createRenderer() {
      this.renderer = new THREE.WebGLRenderer({
        canvas: this.$refs.canvas,
      });
      this.renderer.setSize(this.width, this.height);
      this.renderer.setPixelRatio(Math.min(2, window.devicePixelRatio));
      this.renderer.render(this.scene, this.camera);
    },
    createMesh() {
      this.geometry = new THREE.PlaneBufferGeometry(1, 1, 256, 256);
      // use more subdivision so see more details
      // anytime we want more details for textures,shaders,... use more subdivision
      this.material = new THREE.ShaderMaterial({
        vertexShader,
        fragmentShader,
        side: THREE.DoubleSide,
        transparent: true,
        uniforms: {
          uWaveAmp: { value: 0.2 }, // amp of 1 is too big inside glsl
          uWaveFreq: { value: new THREE.Vector2(5, 5) },
          uWaveSpeed: { value: new THREE.Vector2(1, 1) },
          uTime: { value: 0 },
          uDepthColor: {
            value: new THREE.Color(this.debugObj.depthColor),
          },
          uSurfaceColor: {
            value: new THREE.Color(this.debugObj.surfaceColor),
          },
          uColorOffset: { value: 0.3 },
          uColorMultiplier: { value: 1.6 },
          uNoiseAmp: { value: 0.15 },
          uNoiseFreq: { value: 15 },
          uNoiseSpeed: { value: 0.2 },
          uNoiseStrength: { value: 3 },
        },
      });
      this.mesh = new THREE.Mesh(this.geometry, this.material);
      this.mesh.rotation.x = -Math.PI * 0.4;
      this.scene.add(this.mesh);
    },
    animate() {
      this.material.uniforms.uTime.value = this.clock.getElapsedTime();
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    addGui() {
      this.gui
        .add(this.material.uniforms.uWaveAmp, 'value')
        .min(0.01)
        .max(1)
        .step(0.01)
        .name('waveAmp');
      // we use .name because by default name will be name of key means 'value'
      this.gui
        .add(this.material.uniforms.uWaveFreq.value, 'x')
        .min(0.1)
        .max(50)
        .step(0.5)
        .name('waveFreq-X');
      // this.material.uniforms.waveFreq.value is Vector2 so we need its .x and .y properties
      this.gui
        .add(this.material.uniforms.uWaveFreq.value, 'y')
        .min(0.1)
        .max(50)
        .step(0.5)
        .name('waveFreq-Y');
      this.gui
        .add(this.material.uniforms.uWaveSpeed.value, 'x')
        .min(0)
        .max(15)
        .step(0.1)
        .name('waveSpeed-X');
      this.gui
        .add(this.material.uniforms.uWaveSpeed.value, 'y')
        .min(0)
        .max(15)
        .step(0.1)
        .name('waveSpeed-Y');
      this.gui
        .addColor(this.debugObj, 'depthColor')
        .name('depth-color')
        .onChange(() => {
          // we create debugObj for colors
          // we use new THREE.Color for send to uniforms
          // here we update debugObj and we must again use new THREE.Color to set value of uniform
          // we can send uniform diretly to both vertex and fragment
          // send attribute only to vertex ... send varying from vertex to fragment
          this.material.uniforms.uDepthColor.value = new THREE.Color(
            this.debugObj.depthColor
          );
        });
      this.gui
        .addColor(this.debugObj, 'surfaceColor')
        .name('surface-color')
        .onChange(() => {
          this.material.uniforms.uSurfaceColor.value = new THREE.Color(
            this.debugObj.surfaceColor
          );
        });
      this.gui
        .add(this.material.uniforms.uColorOffset, 'value')
        .min(0)
        .max(1)
        .step(0.01)
        .name('uColorOffset');
      this.gui
        .add(this.material.uniforms.uColorMultiplier, 'value')
        .min(0)
        .max(5)
        .step(0.1)
        .name('uColorMultiplier');
      this.gui
        .add(this.material.uniforms.uNoiseAmp, 'value')
        .min(0)
        .max(1)
        .step(0.01)
        .name('uNoiseAmp');
      this.gui
        .add(this.material.uniforms.uNoiseFreq, 'value')
        .min(0)
        .max(50)
        .step(1)
        .name('uNoiseFreq');
      this.gui
        .add(this.material.uniforms.uNoiseSpeed, 'value')
        .min(0)
        .max(20)
        .step(1)
        .name('uNoiseSpeed');
      this.gui
        .add(this.material.uniforms.uNoiseStrength, 'value')
        .min(0)
        .max(10)
        .step(1)
        .name('uNoiseStrength');
    },
  },
};
</script>
