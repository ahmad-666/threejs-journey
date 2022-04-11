<template>
  <div class="width-100 fill-height d-flex justify-end">
    <canvas ref="canvas"></canvas>
  </div>
</template>
<script>
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import vertexShader from '~/shaders/galaxy/vertex.glsl';
import fragmentShader from '~/shaders/galaxy/fragment.glsl';
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
      clock: new THREE.Clock(),
      gui: null,
      parameters: {
        count: 100000,
        size: 0.01,
        radius: 4,
        branchNum: 3,
        randomnessPower: 3,
        insideColor: 0xaaaa,
        outsideColor: 0x88bb,
      },
      geometry: null,
      material: null,
      points: null,
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
    this.createRenderer();
    this.generateGalaxy();

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
      this.camera.position.z = 3;
      this.camera.position.y = 5;
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
    generateGalaxy() {
      if (this.points) {
        this.geometry.dispose();
        this.material.dispose();
        this.scene.remove(this.points);
      }
      this.geometry = new THREE.BufferGeometry();
      const positions = new Float32Array(this.parameters.count * 3);
      const colors = new Float32Array(this.parameters.count * 3);
      const randomness = new Float32Array(this.parameters.count * 3);
      const sizeRandomness = new Float32Array(this.parameters.count * 1); // for size randomness attribute
      const insideColor = new THREE.Color(this.parameters.insideColor);
      const outsideColor = new THREE.Color(this.parameters.outsideColor);
      for (let i = 0; i < this.parameters.count; i++) {
        const index = i * 3;
        const length = this.parameters.radius * Math.random();
        const angle =
          2 *
          Math.PI *
          ((i % this.parameters.branchNum) / this.parameters.branchNum);
        const randomnessX =
          Math.pow(Math.random(), this.parameters.randomnessPower) *
          (Math.random() < 0.5 ? 1 : -1);
        const randomnessY =
          Math.pow(Math.random(), this.parameters.randomnessPower) *
          (Math.random() < 0.5 ? 1 : -1);
        const randomnessZ =
          Math.pow(Math.random(), this.parameters.randomnessPower) *
          (Math.random() < 0.5 ? 1 : -1);
        // because we animate it we should add randomness after we find animated values not here
        // positions[index + 0] = Math.sin(angle) * length + randomnessX;
        // positions[index + 1] = 0 + randomnessY;
        // positions[index + 2] = Math.cos(angle) * length + randomnessZ;
        randomness[index + 0] = randomnessX;
        randomness[index + 1] = randomnessY;
        randomness[index + 2] = randomnessZ;
        positions[index + 0] = Math.sin(angle) * length;
        positions[index + 1] = 0;
        positions[index + 2] = Math.cos(angle) * length;
        const mixedColor = insideColor.clone();
        mixedColor.lerp(outsideColor, length);
        colors[index + 0] = mixedColor.r;
        colors[index + 1] = mixedColor.g;
        colors[index + 2] = mixedColor.b;
        sizeRandomness[i] = Math.random();
      }
      this.geometry.setAttribute(
        'position',
        new THREE.BufferAttribute(positions, 3)
      );
      this.geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
      this.geometry.setAttribute(
        'aSizeRandomness',
        new THREE.BufferAttribute(sizeRandomness, 1)
      );
      this.geometry.setAttribute(
        'aRandomness',
        new THREE.BufferAttribute(randomness, 3)
      );
      this.material = new THREE.ShaderMaterial({
        // change PointMaterial to ShaderMaterial
        // size: this.parameters.size, //we don't have it in ShaderMaterial
        // sizeAttenuation: true, //we don't have it in ShaderMaterial
        // because we comment sizeAttenuation part we see each particle in same size and distance will not affect it
        // we need to add sizeAttenuation on our own
        // all built-in materials of threejs including PointMaterial are using shaders so need to find shader file related to PointMaterial
        // go to node_modules\three\src\renderers\shaders\ShaderLib\points.glsl
        // inside that file we can find section with bellow code:
        // #ifdef USE_SIZEATTENUATION
        //   bool isPerspective = isPerspectiveMatrix( projectionMatrix );
        //   if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
        // #endif
        // we only need gl_PointSize *= ( scale / - mvPosition.z ); part
        // we need to find out what is scale and what is mvPosition
        // for scale we statically use '1.0' and mvPosition is our viewPos
        // to at the end we add
        depthWrite: false, // we can use it in ShaderMaterial
        blending: THREE.AdditiveBlending, // we can use it in ShaderMaterial
        vertexColors: true, // we can use it in ShaderMaterial ... only now we are allowed to color each particle even when using shaders ... first must use this property  then vertexShader because when using this property we will adding 'attribute vec3 color' inside vertexShader automatically
        side: THREE.DoubleSide,
        transparent: true,
        vertexShader,
        fragmentShader,
        uniforms: {
          uSize: { value: 14 * this.renderer.getPixelRatio() }, // size of each fragment
          // we use uniform because we want to control it via dat.gui ...for randomize it we use <uniform.size.value>*Math.random() ... Math.random() value coming from attribute
          // we need to handle different device pixel ratio too  and because of that we use *this.renderer.getPixelRatio()
          // first create renderer then call generateGalaxy
          uTime: { value: 0 },
        },
      });
      this.points = new THREE.Points(this.geometry, this.material);
      this.scene.add(this.points);
    },
    animate() {
      this.material.uniforms.uTime.value = this.clock.getElapsedTime();
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    addGui() {
      this.gui
        .add(this.parameters, 'count')
        .min(100)
        .max(500000)
        .step(100)
        .onFinishChange(this.generateGalaxy);
      this.gui
        .add(this.parameters, 'size')
        .min(0.001)
        .max(0.05)
        .step(0.001)
        .onFinishChange(this.generateGalaxy);
      this.gui
        .add(this.parameters, 'radius')
        .min(1)
        .max(3)
        .step(0.1)
        .onFinishChange(this.generateGalaxy);
      this.gui
        .add(this.parameters, 'branchNum')
        .min(1)
        .max(10)
        .step(1)
        .onFinishChange(this.generateGalaxy);
      this.gui
        .add(this.parameters, 'randomnessPower')
        .min(1)
        .max(20)
        .step(1)
        .onFinishChange(this.generateGalaxy);
      this.gui
        .addColor(this.parameters, 'insideColor')
        .onFinishChange(this.generateGalaxy);
      this.gui
        .addColor(this.parameters, 'outsideColor')
        .onFinishChange(this.generateGalaxy);
      this.gui
        .add(this.material.uniforms.uSize, 'value')
        .min(1)
        .max(30)
        .step(1)
        .name('particle size');
    },
  },
};
</script>
