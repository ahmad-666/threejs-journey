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
      this.camera.position.z = 3;
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
      this.gltfLoader = new GLTFLoader();
      this.gltfLoader.load(
        '/models/FlightHelmet/glTF/FlightHelmet.gltf',
        gltf => {
          gltf.scene.scale.set(4, 4, 4);
          gltf.scene.position.y = -2;
          gltf.scene.rotation.y = Math.PI * 0.1;
          this.scene.add(gltf.scene);
          this.gltf = gltf;
          this.gui
            .add(this.gltf.scene.rotation, 'y')
            .min(-Math.PI)
            .max(Math.PI)
            .step(0.01);
          this.updateMaterials();
        }
      );
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
    addGui() {
      this.gui
        .add(this.directionalLight, 'intensity')
        .min(0)
        .max(10)
        .step(0.01);
      this.gui
        .add(this.directionalLight.position, 'x')
        .min(-5)
        .max(5)
        .step(0.1);
      this.gui
        .add(this.directionalLight.position, 'y')
        .min(-5)
        .max(5)
        .step(0.1);
      this.gui
        .add(this.directionalLight.position, 'z')
        .min(-5)
        .max(5)
        .step(0.1);
      this.gui
        .add(this.debugObj, 'envMapIntensity')
        .min(1)
        .max(10)
        .step(1)
        .onChange(this.updateMaterials);
      this.gui
        .add(this.renderer, 'toneMapping', {
          No: THREE.NoToneMapping,
          Linear: THREE.LinearToneMapping,
          Reinhard: THREE.ReinhardToneMapping,
          Cineon: THREE.CineonToneMapping,
          ACESFilmic: THREE.ACESFilmicToneMapping,
        })
        .onChange(() => {
          this.renderer.toneMapping = parseInt(this.renderer.toneMapping);
          this.updateMaterials();
        });
      this.gui.add(this.renderer, 'toneMappingExposure').min(1).max(10).step(1);
    },
  },
};
</script>
