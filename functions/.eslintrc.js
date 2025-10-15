module.exports = {
  parser: "@typescript-eslint/parser", // TS parser'ı
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: "module",
  },
  env: {
    es6: true,
    node: true,
  },
  plugins: ["@typescript-eslint"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
  ],
  rules: {
    quotes: ["error", "double"],
    "import/no-unresolved": 0,
    indent: ["warn", 2, { SwitchCase: 1 }],
    "max-len": ["warn", { code: 100, ignoreStrings: true }],
    "object-curly-spacing": "off",
    "eol-last": "off",
  },
};
