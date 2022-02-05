<template>
  <div class="width-100 fill-height d-flex justify-end">
    <canvas ref="canvas"></canvas>
  </div>
</template>
<script>
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js';
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
      oldTime: 0,
      controls: null,
      gui: null,
      ambientLight: null,
      directionalLight: null,
      debugObj: {},
      gltfLoader: null,
      draco: null,
      animationMixer: null,
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
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      this.renderer.setSize(this.width, this.height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    },
    createMeshes() {
      this.draco = new DRACOLoader();
      this.draco.setDecoderPath('/draco/');
      this.gltfLoader = new GLTFLoader();
      this.gltfLoader.setDRACOLoader(this.draco);
      this.gltfLoader.load('/models/Fox/glTF/Fox.gltf', gltf => {
        this.animationMixer = new THREE.AnimationMixer(gltf.scene);
        const runAnimation = this.animationMixer.clipAction(gltf.animations[0]);
        runAnimation.play();
        gltf.scene.scale.set(0.02, 0.02, 0.02);
        this.scene.add(gltf.scene);
      });
    },
    createLight() {
      this.ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
      this.scene.add(this.ambientLight);
      this.directionalLight = new THREE.DirectionalLight(0xffffff, 0.2);
      this.directionalLight.castShadow = true;
      this.directionalLight.shadow.mapSize.set(1024, 1024);
      this.directionalLight.shadow.camera.far = 15;
      this.directionalLight.shadow.camera.left = -7;
      this.directionalLight.shadow.camera.top = 7;
      this.directionalLight.shadow.camera.right = 7;
      this.directionalLight.shadow.camera.bottom = -7;
      this.directionalLight.position.set(5, 5, 5);
      this.scene.add(this.directionalLight);
    },
    animate() {
      const newTime = this.clock.getElapsedTime();
      const deltaTime = newTime - this.oldTime;
      this.oldTime = newTime;
      if (this.animationMixer) {
        this.animationMixer.update(deltaTime);
      }
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    addGui() {},
  },
};
</script>
