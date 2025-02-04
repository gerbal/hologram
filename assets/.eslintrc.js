module.exports = {
  env: {
    browser: true,
    es2021: true,
    mocha: true,
  },
  extends: "eslint:recommended",
  globals: {
    Elixir_Enum: "readonly",
    Elixir_Hologram_Template_Renderer: "readonly",
    Elixir_Kernel: "readonly",
    Erlang_Lists: "readonly",
    Elixir_Map: "readonly",
    Elixir_String_Chars: "readonly",
    Erlang: "readonly",
    Erlang_Maps: "readonly",
  },
  overrides: [
    {
      env: {
        node: true,
      },
      files: [".eslintrc.{js,cjs}"],
      parserOptions: {
        sourceType: "script",
      },
    },
  ],
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  rules: {
    "no-unused-vars": [
      "error",
      {argsIgnorePattern: "^_", varsIgnorePattern: "^_"},
    ],
  },
};
