// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: ["./js/**/*.js", "../lib/devhub_web.ex", "../lib/devhub_web/**/*.*ex", "../lib/devhub/**/*.*ex", "../storybook/**/*.*exs"],
  safelist: [
    // calendar
    {
      pattern: /text-(red|gray|green|blue|orange|yellow|purple|pink)-(700|900)/,
    },
    {
      pattern: /bg-(red|gray|green|blue|orange|yellow|purple|pink)-100/,
    },
    {
      pattern: /bg-(red|gray|green|blue|orange|yellow|purple|pink)-200/,
      variants: ["hover"],
    },
  ],
  theme: {
    darkMode: "class",
    colors: {
      transparent: "transparent",
      current: "currentColor",
      white: "white",
      black: "black",
      blue: {
        50: "rgb(var(--blue-50))",
        100: "rgb(var(--blue-100))",
        200: "rgb(var(--blue-200))",
        300: "rgb(var(--blue-300))",
        400: "rgb(var(--blue-400))",
        500: "rgb(var(--blue-500))",
        600: "rgb(var(--blue-600))",
        700: "rgb(var(--blue-700))",
        800: "rgb(var(--blue-800))",
        900: "rgb(var(--blue-900))",
      },
      gray: {
        50: "rgb(var(--gray-50))",
        100: "rgb(var(--gray-100))",
        200: "rgb(var(--gray-200))",
        300: "rgb(var(--gray-300))",
        400: "rgb(var(--gray-400))",
        500: "rgb(var(--gray-500))",
        600: "rgb(var(--gray-600))",
        700: "rgb(var(--gray-700))",
        800: "rgb(var(--gray-800))",
        900: "rgb(var(--gray-900))",
      },
      surface: {
        0: "var(--surface-0)",
        1: "var(--surface-1)",
        2: "var(--surface-2)",
        3: "var(--surface-3)",
        4: "var(--surface-4)",
      },
      alpha: {
        4: "var(--alpha-4)",
        8: "var(--alpha-8)",
        16: "var(--alpha-16)",
        24: "var(--alpha-24)",
        32: "var(--alpha-32)",
        40: "var(--alpha-40)",
        64: "var(--alpha-64)",
        72: "var(--alpha-72)",
        80: "var(--alpha-80)",
        88: "var(--alpha-88)",
      },
      red: {
        50: "rgb(var(--red-50))",
        100: "rgb(var(--red-100))",
        200: "rgb(var(--red-200))",
        300: "rgb(var(--red-300))",
        400: "rgb(var(--red-400))",
        500: "rgb(var(--red-500))",
        600: "rgb(var(--red-600))",
        700: "rgb(var(--red-700))",
        800: "rgb(var(--red-800))",
        900: "rgb(var(--red-900))",
      },
      green: {
        50: "rgb(var(--green-50))",
        100: "rgb(var(--green-100))",
        200: "rgb(var(--green-200))",
        300: "rgb(var(--green-300))",
        400: "rgb(var(--green-400))",
        500: "rgb(var(--green-500))",
        600: "rgb(var(--green-600))",
        700: "rgb(var(--green-700))",
        800: "rgb(var(--green-800))",
        900: "rgb(var(--green-900))",
      },
      yellow: {
        50: "var(--yellow-50)",
        100: "var(--yellow-100)",
        200: "var(--yellow-200)",
        300: "var(--yellow-300)",
        400: "var(--yellow-400)",
        500: "var(--yellow-500)",
        600: "rgb(var(--yellow-600))",
        700: "var(--yellow-700)",
        800: "var(--yellow-800)",
        900: "var(--yellow-900)",
      },
      orange: {
        50: "var(--orange-50)",
        100: "var(--orange-100)",
        200: "var(--orange-200)",
        300: "var(--orange-300)",
        400: "var(--orange-400)",
        500: "var(--orange-500)",
        600: "var(--orange-600)",
        700: "var(--orange-700)",
        800: "var(--orange-800)",
        900: "var(--orange-900)",
      },
      purple: {
        50: "var(--purple-50)",
        100: "var(--purple-100)",
        200: "var(--purple-200)",
        300: "var(--purple-300)",
        400: "var(--purple-400)",
        500: "var(--purple-500)",
        600: "var(--purple-600)",
        700: "var(--purple-700)",
        800: "var(--purple-800)",
        900: "var(--purple-900)",
      },
      pink: {
        50: "var(--pink-50)",
        100: "var(--pink-100)",
        200: "var(--pink-200)",
        300: "var(--pink-300)",
        400: "var(--pink-400)",
        500: "var(--pink-500)",
        600: "var(--pink-600)",
        700: "var(--pink-700)",
        800: "var(--pink-800)",
        900: "var(--pink-900)",
      }
    },
    extend: {
      fontFamily: {
        inter: ["Inter", "san-serif"],
      },
      blur: {
        xs: "2px",
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds custom icons into app.css bundle
    // See `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "icons")
      let values = {}

      fs.readdirSync(iconsDir).forEach(file => {
        let name = path.basename(file, ".svg")
        values[name] = { name, fullPath: path.join(iconsDir, file) }
      })

      matchComponents(
        {
          devhub: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "")
            let size = theme("spacing.6")
            if (name.endsWith("-mini")) {
              size = theme("spacing.5")
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4")
            }
            return {
              [`--devhub-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--devhub-${name})`,
              mask: `var(--devhub-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            }
          },
        },
        { values }
      )
    }),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ]

      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })

      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "")
            let size = theme("spacing.6")
            if (name.endsWith("-mini")) {
              size = theme("spacing.5")
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4")
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            }
          },
        },
        { values }
      )
    }),
  ],
}
