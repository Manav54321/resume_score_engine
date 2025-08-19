/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      colors: {
        'brand-dark': '#111111',
        'brand-light': '#EAEAEA',
        'brand-secondary': '#A1A1A1',
        'brand-border': '#333333',
        'brand-input': '#1C1C1C',
        'brand-card': '#1A1A1A',
        'brand-green-light': '#A7F3D0',
        'brand-green-dark': '#065F46',
        'brand-yellow-light': '#FDE68A',
        'brand-yellow-dark': '#92400E',
        'brand-red-light': '#FECACA',
        'brand-red-dark': '#991B1B',
      }
    },
  },
  plugins: [],
}
