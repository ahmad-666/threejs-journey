// eslint-disable-next-line nuxt/no-cjs-in-config
module.exports = {
  // Global page headers: https://go.nuxtjs.dev/config-head
  head: {
    titleTemplate: '%s',
    title: 'title',
    htmlAttrs: {
      lang: 'en',
    },
    meta: [
      { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: '' },
      { name: 'format-detection', content: 'telephone=no' },
    ],
    link: [{ rel: 'icon', type: 'image/x-icon', href: '/imgs/logo.png' }],
  },
  // Global CSS: https://go.nuxtjs.dev/config-css
  css: ['~/assets/styles/global.scss'],
  // Plugins to run before rendering page: https://go.nuxtjs.dev/config-plugins
  plugins: [],
  // Auto import components: https://go.nuxtjs.dev/config-components
  components: true,
  // Modules for dev and build (recommended): https://go.nuxtjs.dev/config-modules
  buildModules: [
    // https://go.nuxtjs.dev/eslint
    '@nuxtjs/eslint-module',
    // https://go.nuxtjs.dev/stylelint
    // '@nuxtjs/stylelint-module',
    // https://go.nuxtjs.dev/vuetify
    '@nuxtjs/vuetify',
  ],
  moment: {
    defaultLocale: 'fa',
    locales: ['fa'],
  },
  // Modules: https://go.nuxtjs.dev/config-modules
  modules: [],
  axios: {
    baseURL: 'https://api.yektour.com',
    progress: false,
    retry: { retries: 3 },
    headers: {
      common: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        // not add any 'credentials' or 'token' here because they can be easily accessed
      },
      // now set any auth token here
    },
  },
  // Vuetify module configuration: https://go.nuxtjs.dev/config-vuetify
  vuetify: {
    customVariables: ['~/assets/styles/vuetify.scss'],
    treeShake: true,
    optionsPath: './vuetify.options.js',
  },
  loading: {
    color: '#ff9800',
    failedColor: '#f44336',
    height: '5px',
    rtl: true,
  },
  env: {
    SERVER_URL: 'https://api.yektour.com',
  },
  router: { middleware: ['autoLogin'] },
  // Build Configuration: https://go.nuxtjs.dev/config-build
  build: {
    transpile: ['num2persian'],
  },
};
