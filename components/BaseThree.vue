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
      debugObj: {
        ambientColor: 0xffffff,
        directionalColor: 0xffffff,
        fogColor: 0x263238,
      },
      ambientLight: null,
      directionalLight: null,
      pointLight: null,
      floor: null,
      house: new THREE.Group(),
      walls: null,
      roof: null,
      door: null,
      bushes: new THREE.Group(),
      graves: new THREE.Group(),
      fog: null,
      textureLoader: null,
      ghost1: null,
      ghost2: null,
      clock: new THREE.Clock(),
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
    this.textureLoader = new THREE.TextureLoader();
    this.createScene();
    this.createCamera();
    this.addLights();
    this.createFloor();
    this.createHouse();
    this.createBushes();
    this.createGraves();
    this.createFog();
    this.createGhosts();
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
        antialias: true,
      });
      this.renderer.setSize(this.width, this.height);
      this.renderer.setPixelRatio(Math.min(2, window.devicePixelRatio));
      this.renderer.render(this.scene, this.camera);
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      this.renderer.setSize(this.width, this.height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      this.renderer.setClearColor(this.debugObj.fogColor);
      this.renderer.shadowMap.enabled = true;
      this.directionalLight.castShadow = true;
      this.pointLight.castShadow = true;
      this.ghost1.castShadow = true;
      this.ghost2.castShadow = true;
      this.walls.castShadow = true;
      this.bushes.children.forEach(bush => {
        bush.castShadow = true;
      });
      this.graves.children.forEach(grave => {
        grave.castShadow = true;
      });
      this.floor.receiveShadow = true;
      this.directionalLight.shadow.mapSize.width = 256;
      this.directionalLight.shadow.mapSize.height = 256;
      this.directionalLight.shadow.camera.far = 10;
      this.pointLight.shadow.mapSize.width = 256;
      this.pointLight.shadow.mapSize.height = 256;
      this.pointLight.shadow.camera.far = 10;
      this.ghost1.shadow.mapSize.width = 256;
      this.ghost1.shadow.mapSize.height = 256;
      this.ghost1.shadow.camera.far = 10;
      this.ghost2.shadow.mapSize.width = 256;
      this.ghost2.shadow.mapSize.height = 256;
      this.ghost2.shadow.camera.far = 10;
    },
    addLights() {
      this.ambientLight = new THREE.AmbientLight(
        this.debugObj.ambientColor,
        0.6
      );
      this.scene.add(this.ambientLight);
      this.directionalLight = new THREE.DirectionalLight(
        this.debugObj.directionalColor,
        1
      );
      this.directionalLight.position.set(-2, 2, 0);
      this.scene.add(this.directionalLight);
      this.pointLight = new THREE.PointLight(0xff9800, 2, 10);
      this.pointLight.position.set(0, 2, 2);
      this.scene.add(this.pointLight);
    },
    createFloor() {
      const grassColorTexture = this.textureLoader.load(
        '/textures/grass/color.jpg'
      );
      const grassAmbientOcclusionTexture = this.textureLoader.load(
        '/textures/grass/ambientOcclusion.jpg'
      );
      const grassNormalTexture = this.textureLoader.load(
        '/textures/grass/normal.jpg'
      );
      const grassRoughnessTexture = this.textureLoader.load(
        '/textures/grass/roughness.jpg'
      );
      grassColorTexture.repeat.set(5, 5);
      grassAmbientOcclusionTexture.repeat.set(5, 5);
      grassNormalTexture.repeat.set(5, 5);
      grassRoughnessTexture.repeat.set(5, 5);
      grassColorTexture.wrapS = THREE.RepeatWrapping;
      grassAmbientOcclusionTexture.wrapS = THREE.RepeatWrapping;
      grassNormalTexture.wrapS = THREE.RepeatWrapping;
      grassRoughnessTexture.wrapS = THREE.RepeatWrapping;
      grassColorTexture.wrapT = THREE.RepeatWrapping;
      grassAmbientOcclusionTexture.wrapT = THREE.RepeatWrapping;
      grassNormalTexture.wrapT = THREE.RepeatWrapping;
      grassRoughnessTexture.wrapT = THREE.RepeatWrapping;

      this.floor = new THREE.Mesh(
        new THREE.PlaneBufferGeometry(8, 8),
        new THREE.MeshStandardMaterial({
          color: 0x009688,
          map: grassColorTexture,
          aoMap: grassAmbientOcclusionTexture,
          normalMap: grassNormalTexture,
          roughnessMap: grassRoughnessTexture,
        })
      );
      this.floor.geometry.setAttribute(
        'uv2',
        new THREE.Float32BufferAttribute(
          this.floor.geometry.attributes.uv.array,
          2
        )
      );
      this.floor.rotation.x = -Math.PI * 0.5;
      this.floor.position.y = 0;
      this.scene.add(this.floor);
    },
    createHouse() {
      const doorColorTexture = this.textureLoader.load(
        '/textures/door/color.jpg'
      );
      const doorAlphaTexture = this.textureLoader.load(
        '/textures/door/alpha.jpg'
      );
      const doorAmbientOcclusionTexture = this.textureLoader.load(
        '/textures/door/ambientOcclusion.jpg'
      );
      const doorHeightTexture = this.textureLoader.load(
        '/textures/door/height.jpg'
      );
      const doorNormalTexture = this.textureLoader.load(
        '/textures/door/normal.jpg'
      );
      const doorMetalNessTexture = this.textureLoader.load(
        '/textures/door/metalness.jpg'
      );
      const doorRoughnessTexture = this.textureLoader.load(
        '/textures/door/roughness.jpg'
      );
      const wallsColorTexture = this.textureLoader.load(
        '/textures/bricks/color.jpg'
      );
      const wallsAmbientOcclusionTexture = this.textureLoader.load(
        '/textures/bricks/ambientOcclusion.jpg'
      );
      const wallsNormalTexture = this.textureLoader.load(
        '/textures/bricks/normal.jpg'
      );
      const wallsRoughnessTexture = this.textureLoader.load(
        '/textures/bricks/roughness.jpg'
      );
      this.scene.add(this.house);
      this.walls = new THREE.Mesh(
        new THREE.BoxBufferGeometry(3, 2, 2.5),
        new THREE.MeshStandardMaterial({
          color: 0x4e342e,
          map: wallsColorTexture,
          aoMap: wallsAmbientOcclusionTexture,
          normalMap: wallsNormalTexture,
          roughnessMap: wallsRoughnessTexture,
        })
      );
      this.walls.geometry.setAttribute(
        'uv2',
        new THREE.Float32BufferAttribute(
          this.walls.geometry.attributes.uv.array,
          2
        )
      );
      this.walls.position.y = 1; // half of height of walls

      this.house.add(this.walls);
      this.roof = new THREE.Mesh(
        new THREE.ConeBufferGeometry(2.5, 0.75, 4),
        new THREE.MeshStandardMaterial({ color: 0x37474f })
      );

      this.roof.position.y = 2 + 0.75 / 2 + 0.001; // full height of wall + half height of itself + some value for prevent z-index fighting
      this.roof.rotation.y = Math.PI * 0.25;
      this.house.add(this.roof);
      this.door = new THREE.Mesh(
        new THREE.PlaneBufferGeometry(1.5, 1.5, 100, 100),
        new THREE.MeshStandardMaterial({
          color: 0x795548,
          map: doorColorTexture,
          transparent: true,
          alphaMap: doorAlphaTexture,
          aoMap: doorAmbientOcclusionTexture,
          displacementMap: doorHeightTexture,
          displacementScale: 0.1,
          normalMap: doorNormalTexture,
          metalnessMap: doorMetalNessTexture,
          roughnessMap: doorRoughnessTexture,
        })
      );
      this.door.geometry.setAttribute(
        'uv2',
        new THREE.Float32BufferAttribute(
          this.door.geometry.attributes.uv.array,
          2
        )
      );
      this.door.position.z = 2.5 / 2 + 0.001; // half depth of walls + some value for prevent z-index fighting
      this.door.position.y = 0.75; // half height of itself
      this.house.add(this.door);
    },
    createBushes() {
      const bushGeometry = new THREE.SphereBufferGeometry(1);
      const bushMaterial = new THREE.MeshStandardMaterial({ color: 0x9ccc65 });
      const bush1 = new THREE.Mesh(bushGeometry, bushMaterial);
      const bush2 = new THREE.Mesh(bushGeometry, bushMaterial);
      const bush3 = new THREE.Mesh(bushGeometry, bushMaterial);
      const bush4 = new THREE.Mesh(bushGeometry, bushMaterial);
      bush1.scale.set(0.2, 0.2, 0.2);
      bush1.position.set(0.5, 0.2, 1.75);
      this.bushes.add(bush1);
      bush2.scale.set(0.1, 0.1, 0.1);
      bush2.position.set(0.8, 0.1, 1.95);
      this.bushes.add(bush2);
      bush3.scale.set(0.15, 0.15, 0.15);
      bush3.position.set(-0.5, 0.15, 1.75);
      this.bushes.add(bush3);
      bush4.scale.set(0.1, 0.1, 0.1);
      bush4.position.set(-0.75, 0.1, 1.55);
      this.bushes.add(bush4);
      this.scene.add(this.bushes);
    },
    createGraves() {
      const graveGeometry = new THREE.BoxBufferGeometry(0.4, 0.55, 0.15);
      const graveMaterial = new THREE.MeshStandardMaterial({
        color: 0x424242,
      });
      for (let i = 0; i < 20; i++) {
        const grave = new THREE.Mesh(graveGeometry, graveMaterial);
        const angle = Math.PI * 2 * Math.random();
        const amp = Math.random() * 2 + 2;
        grave.position.x = Math.sin(angle) * amp;
        grave.position.z = Math.cos(angle) * amp;
        grave.position.y = 0.75 / 2;
        this.graves.add(grave);
      }
      this.scene.add(this.graves);
    },
    createFog() {
      this.fog = new THREE.Fog(this.debugObj.fogColor, 1, 8);
      this.scene.fog = this.fog;
    },
    createGhosts() {
      this.ghost1 = new THREE.PointLight(0xff0000, 5, 3);

      this.scene.add(this.ghost1);
      this.ghost2 = new THREE.PointLight(0x0000ff, 5, 3);

      this.scene.add(this.ghost2);
    },
    animate() {
      const elapsedTime = this.clock.getElapsedTime();
      this.ghost1.position.x = 2 * Math.sin(elapsedTime * 2);
      this.ghost1.position.z = 2 * Math.cos(elapsedTime * 2);
      this.ghost1.position.y = Math.sin(elapsedTime);
      this.ghost2.position.x = 2.5 * Math.sin(-elapsedTime * 1);
      this.ghost2.position.z =
        2.5 * Math.cos(-elapsedTime * 1) + Math.cos(elapsedTime * 2);
      this.ghost2.position.y = 2 * Math.sin(elapsedTime * 4);
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    addGui() {
      this.gui
        .addColor(this.debugObj, 'ambientColor')
        .name('ambient light color')
        .onChange(val => {
          this.ambientLight.color = new THREE.Color(val);
        });
      this.gui
        .add(this.ambientLight, 'intensity')
        .min(0)
        .max(1)
        .step(0.1)
        .name('ambient light intensity');
      this.gui
        .addColor(this.debugObj, 'directionalColor')
        .name('directional light color')
        .onChange(val => {
          this.directionalLight.color = new THREE.Color(val);
        });
      this.gui
        .add(this.directionalLight, 'intensity')
        .min(0)
        .max(1)
        .step(0.1)
        .name('directional light intensity');
      this.gui
        .add(this.directionalLight.position, 'x')
        .min(-5)
        .max(5)
        .step(0.1)
        .name('directional light x');
      this.gui
        .add(this.directionalLight.position, 'y')
        .min(-5)
        .max(5)
        .step(0.1)
        .name('directional light y');
      this.gui
        .add(this.directionalLight.position, 'z')
        .min(-5)
        .max(5)
        .step(0.1)
        .name('directional light z');
      this.gui
        .addColor(this.debugObj, 'fogColor')
        .name('fog color')
        .onChange(val => {
          this.fog.color = new THREE.Color(val);
        });
    },
  },
};
</script>
