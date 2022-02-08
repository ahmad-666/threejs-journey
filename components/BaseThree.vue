<template>
  <div class="width-100 fill-height d-flex justify-end">
    <canvas ref="canvas"></canvas>
  </div>
</template>
<script>
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
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
      parameters: {
        count: 20000,
        size: 0.01,
        radius: 4,
        branchNum: 5,
        spin: 2,
        randomnessPower: 5,
        insideColor: 0xff0000,
        outsideColor: 0x0000ff,
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
    this.generateGalaxy();
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
      this.camera.position.z = 3;
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
      const insideColor = new THREE.Color(this.parameters.insideColor);
      const outsideColor = new THREE.Color(this.parameters.outsideColor);
      for (let i = 0; i < this.parameters.count; i++) {
        const index = i * 3;
        const length = this.parameters.radius * Math.random();
        const spinAngle = this.parameters.spin * length;
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
        positions[index + 0] =
          Math.sin(angle + spinAngle) * length + randomnessX;
        positions[index + 1] = 0 + randomnessY;
        positions[index + 2] =
          Math.cos(angle + spinAngle) * length + randomnessZ;
        const mixedColor = insideColor.clone();
        mixedColor.lerp(outsideColor, length);
        colors[index + 0] = mixedColor.r;
        colors[index + 1] = mixedColor.g;
        colors[index + 2] = mixedColor.b;
      }
      this.geometry.setAttribute(
        'position',
        new THREE.BufferAttribute(positions, 3)
      );
      this.geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
      this.material = new THREE.PointsMaterial({
        size: this.parameters.size,
        sizeAttenuation: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        vertexColors: true,
      });
      this.points = new THREE.Points(this.geometry, this.material);
      this.scene.add(this.points);
    },
    animate() {
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    addGui() {
      this.gui
        .add(this.parameters, 'count')
        .min(100)
        .max(100000)
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
        .add(this.parameters, 'spin')
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
    },
  },
};
</script>
