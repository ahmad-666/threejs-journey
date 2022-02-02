module.exports = {
  root: true,
  env: {
    browser: true,
    node: true
  },
  parserOptions: {
    parser: '@babel/eslint-parser',
    requireConfigFile: false
  },
  extends: [
    '@nuxtjs',
    'plugin:nuxt/recommended',
    'prettier'
  ],
  plugins: [
  ],
  // add your custom rules here
	rules: {
    'no-console': 'warn',
    'no-unused-vars': 'error',
    'import/prefer-default-export': 'warn',
    'no-param-reassign': 'warn',
    'no-underscore-dangle': 'off',
    'import/no-named-as-default': 'warn',
    'arrow-body-style': 'off', // this is eslint rule but affect prettier
    'no-plusplus': 'off',
    'spaced-comment': 'warn',
    'no-nested-ternary': 'off',
    'vue/valid-v-slot': [
      'error',
      {
        allowModifiers: true,
      },
    ],
  },
}
