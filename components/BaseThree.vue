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
      clock: new THREE.Clock(),
      controls: null,
      gui: null,
      floor: null,
      sphere: null,
      ambientLight: null,
      directionalLight: null,
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
    window.addEventListener('dblclick', this.windowFullScreen);
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
      this.floor = new THREE.Mesh(
        new THREE.PlaneBufferGeometry(10, 10),
        new THREE.MeshStandardMaterial({
          color: '#777777',
          metalness: 0.3,
          roughness: 0.4,
        })
      );
      this.floor.receiveShadow = true;
      this.floor.rotation.x = -Math.PI * 0.5;
      this.scene.add(this.floor);
      this.sphere = new THREE.Mesh(
        new THREE.SphereBufferGeometry(0.5, 32, 32),
        new THREE.MeshStandardMaterial({
          metalness: 0.3,
          roughness: 0.4,
        })
      );
      this.sphere.castShadow = true;
      this.sphere.position.y = 0.5;
      this.scene.add(this.sphere);
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
      // const elapsedTime = this.clock.getElapsedTime();
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    addGui() {},
  },
};
</script>
