import colors from 'vuetify/es5/util/colors';
export default {
  breakpoint: {
    thresholds: {
      xs: 500,
      sm: 750,
      md: 1100,
      lg: 1500,
    },
    mobileBreakpoint: 'sm',
    scrollBarWidth: 16,
  },
  treeShake: true,
  rtl: true,
  theme: {
    dark: true,
    themes: {
      light: {
        primary: colors.orange.base,
        secondary: colors.cyan.base,
        accent: colors.deepPurple.base,
        success: colors.teal.accent4,
        info: colors.lightBlue.darken2,
        error: colors.red.base,
        warning: colors.amber.accent3,
        backgroundColor: colors.blueGrey.lighten5,
        cardColor: colors.shades.white,
        titleColor: colors.blueGrey.darken4,
        textColor: colors.blueGrey.darken1,
      },
      dark: {
        primary: colors.orange.base,
        secondary: colors.cyan.base,
        accent: colors.deepPurple.base,
        success: colors.teal.accent4,
        info: colors.lightBlue.darken2,
        error: colors.red.base,
        warning: colors.amber.accent3,
        backgroundColor: '#1e1e2f',
        cardColor: '#27293d',
        titleColor: colors.shades.white,
        textColor: colors.blueGrey.lighten2,
      },
    },
  },
};
