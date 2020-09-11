module.exports = {
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js"
  ],
  target: 'relaxed',
  prefix: '',
  important: false,
  separator: ':',
  theme: {
    fontFamily: {
      body: ['Montserrat', 'sans-serif'],
    },
    spacing: {
      '0': '0',
      '0.5rem': '0.5rem',
      '1rem': '1rem',
      '2rem': '2rem',
      '3rem': '3rem',
      '4rem': '4rem',
      '5rem': '5rem',
      '6rem': '6rem',
      '14.25rem': '14.25rem',
      '15rem': '15rem'
    },
    borderRadius: {
      // '5px': '5px',
      // '10px': '10px',
      // '25px': '25px',
      // '70px': '70px',
      0: 0,
      '3rem': '3rem',
      '5rem': '5rem',
      '10': '0.83rem',
      '15': '1.25rem',
      '25': '2.08rem',
      '35': '2.91rem',
      '50': '4.16rem'
    },
    fontSize: {
      'reference': '6px',
      '1rem': '1rem',
      '1.5rem': '1.5rem',
      '2rem': '2rem',
      '3rem': '3rem',
      '4rem': '4rem',
      '5rem': '5rem',
      '6rem': '6rem',
      '8rem': '8rem',
      '10rem': '10rem',
      '11rem': '11rem'
    },
    colors: {
      // transparent: 'transparent',
      // current: 'currentColor',

      // ['primary-dark']: '#006B80',
      // ['primary-light']: '#F5FBFC',
      // danger: '#EF5350',
      // ['danger-light']: '#FEEDED',
      // success: '#81C784',
      // ['success-light']: '#ECF7ED',
      // info: '#29B6F6',
      // ['info-light']: '#D5EAF4',
      // warning: '#FFD54F',
      // black: '#000',

      white: '#fff',
      body: '#484848',
      primary: '#008EAA',
      green: {
        pale: '#9ABEAA',
        1: '#81C784',
        2: '#009639',
      },
      gray: {
        1: '#EEEEEE'
      },
      brown: '#9E652E',
      yellow: {
        1: '#FFD54F',
        2: '#FF9E1B',
      },
      charcoal: '#3D3D3D',
      darkMode: '#303030',
      darkModeBorder: '#707070',
      red: '#EF5350',
      offWhite: '#EEEEEE',
      // gray: {
      //   100: '#F6F6F6',
      //   200: '#F3F3F3',
      //   300: '#E8E8E8',
      //   400: '#DCDCDC',
      //   500: '#A2A2A2',
      // },
    },
    padding: (theme) => theme('spacing'),
    borderWidth: {
      default: '1px',
      0: '0',
      2: '2px',
      3: '3px',
      10: '10px'
    },
    borderColor: (theme) => theme('colors'),
  },
  variants: {
    borderRadius: ['responsive'],
    fontSize: ['responsive'],
    padding: ['responsive'],
  },
};
