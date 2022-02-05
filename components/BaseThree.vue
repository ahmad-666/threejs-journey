<template>
  <div class="width-100 fill-height d-flex justify-end">
    <canvas ref="canvas"></canvas>
  </div>
</template>
<script>
import * as THREE from 'three';
import CANNON from 'cannon';
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
      oldTime: 0,
      controls: null,
      gui: null,
      plane: null,
      planeBody: null,
      objects: [],
      physicsWorld: null,
      defaultMaterial: null,
      contactMaterial: null,
      ambientLight: null,
      directionalLight: null,
      audio: new Audio('/sounds/hit.mp3'),
      standardMaterial: new THREE.MeshStandardMaterial({
        metalness: 0.3,
        roughness: 0.4,
      }),
      sphereGeometry: new THREE.SphereBufferGeometry(1),
      boxGeometry: new THREE.BoxBufferGeometry(1, 1, 1),
      debugObj: {
        createSphere: () => {
          this.createSphere(Math.random(), {
            x: (Math.random() - 0.5) * 2,
            y: Math.random() * 2,
            z: (Math.random() - 0.5) * 2,
          });
        },
        createBox: () => {
          this.createBox(
            Math.random() * 3,
            Math.random() * 3,
            Math.random() * 3,
            {
              x: (Math.random() - 0.5) * 3,
              y: Math.random() * 3,
              z: (Math.random() - 0.5) * 3,
            }
          );
        },
        reset: () => {
          this.objects.forEach(obj => {
            obj.body.removeEventListener('collide', this.playSound);
            this.physicsWorld.removeBody(obj.body);
            this.scene.remove(obj.mesh);
          });
        },
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
    this.createMeshes();
    this.createPhysicsWorld();
    this.createPhysicsMaterials();
    this.createBodies();
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
      this.plane = new THREE.Mesh(
        new THREE.PlaneBufferGeometry(10, 10),
        new THREE.MeshStandardMaterial({
          color: '#777777',
          metalness: 0.3,
          roughness: 0.4,
        })
      );
      this.plane.receiveShadow = true;
      this.plane.position.z = -3;
      this.plane.rotation.x = -Math.PI * 0.5;
      this.scene.add(this.plane);
    },
    createPhysicsWorld() {
      this.physicsWorld = new CANNON.World();
      this.physicsWorld.gravity.set(0, -9.82, 0);
      this.physicsWorld.broadphase = new CANNON.SAPBroadphase(
        this.physicsWorld
      );
      this.physicsWorld.allowSleep = true;
    },
    createPhysicsMaterials() {
      this.defaultMaterial = new CANNON.Material('default');
      this.contactMaterial = new CANNON.ContactMaterial(
        this.defaultMaterial,
        this.defaultMaterial,
        {
          friction: 0.1,
          restitution: 0.75,
        }
      );
      this.physicsWorld.addContactMaterial(this.contactMaterial);
    },
    createBodies() {
      this.planeBody = new CANNON.Body({
        mass: 0,
        shape: new CANNON.Plane(),
        material: this.defaultMaterial,
      });
      this.planeBody.quaternion.setFromAxisAngle(
        new CANNON.Vec3(1, 0, 0),
        -Math.PI * 0.5
      );
      this.planeBody.position.z = -3;
      this.physicsWorld.add(this.planeBody);
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
    createSphere(radius, position) {
      const mesh = new THREE.Mesh(this.sphereGeometry, this.standardMaterial);
      mesh.scale.set(radius, radius, radius);
      mesh.castShadow = true;
      mesh.position.copy(position);
      this.scene.add(mesh);
      const body = new CANNON.Body({
        mass: 1,
        shape: new CANNON.Sphere(radius),
        position,
        material: this.defaultMaterial,
      });
      body.addEventListener('collide', this.playSound);
      this.physicsWorld.addBody(body);
      this.objects.push({ mesh, body });
    },
    createBox(width, height, depth, position) {
      const mesh = new THREE.Mesh(this.boxGeometry, this.standardMaterial);
      mesh.scale.set(width, height, depth);
      mesh.castShadow = true;
      mesh.position.copy(position);
      this.scene.add(mesh);
      const body = new CANNON.Body({
        mass: 1,
        shape: new CANNON.Box(
          new CANNON.Vec3(width / 2, height / 2, depth / 2)
        ),
        position,
        material: this.defaultMaterial,
      });
      body.addEventListener('collide', this.playSound);
      this.physicsWorld.addBody(body);
      this.objects.push({ mesh, body });
    },
    playSound(e) {
      const impact = e.contact.getImpactVelocityAlongNormal();
      if (impact > 2) {
        this.audio.volume = Math.random();
        this.audio.currentTime = 0;
        this.audio.play();
      }
    },
    animate() {
      const elapsedTime = this.clock.getElapsedTime();
      const deltaTime = elapsedTime - this.oldTime;
      this.oldTime = elapsedTime;
      this.physicsWorld.step(1 / 60, deltaTime, 3);
      this.objects.forEach(obj => {
        obj.mesh.position.copy(obj.body.position);
        obj.mesh.quaternion.copy(obj.body.quaternion);
      });
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
      window.requestAnimationFrame(this.animate);
    },
    addGui() {
      this.gui.add(this.debugObj, 'createSphere');
      this.gui.add(this.debugObj, 'createBox');
      this.gui.add(this.debugObj, 'reset');
    },
  },
};
</script>
