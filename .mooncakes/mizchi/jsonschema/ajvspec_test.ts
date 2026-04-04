import { Ajv2020 } from "npm:ajv@8.17.1/dist/2020.js";
import { expect } from "jsr:@std/expect";

const ajv = new Ajv2020({
  allErrors: true,
});
const validate = ajv.compile({
  definitions: {
    A: {
      type: "object",
      properties: {
        a: { type: "number" },
      },
      required: ["a"],
    },
    B: {
      type: "object",
      properties: {
        b: { type: "number" },
      },
      required: ["b"],
    },
    Union: {
      oneOf: [
        {
          $ref: "#/definitions/A",
        },
        {
          $ref: "#/definitions/B",
        },
      ],
    },
  },
  // $ref: "#/definitions/Union",
  oneOf: [{ $ref: "#/definitions/A" }, { $ref: "#/definitions/B" }],
});

const ret = validate({ x: 1, y: 4 });
console.log(ret);

console.log({
  a: validate({ a: 1 }),
  b: validate({ b: 2 }),
  err: validate({ a: 1, b: 2, c: 3 }),
  ab: validate({ a: 1, b: 2 }),
});

Deno.test("prefixItems", () => {
  const schema = {
    type: "array",
    minItems: 2,
    prefixItems: [{ type: "number" }, { type: "string" }],
    // additionalItems: false,
  };
  const validate = ajv.compile(schema);
  expect(validate([1, "a"])).toBe(true);
});

Deno.test("prefixItems with const", () => {
  const schema = {
    type: "array",
    minItems: 2,
    prefixItems: [{ const: "t" }, { type: "string" }],
  };
  const validate = ajv.compile(schema);
  expect(validate(["t", "a"])).toBe(true);
  expect(validate(["none", "a"])).toBe(false);
});

// import { Ajv2020 } from "npm:ajv@8.17.1/dist/2020.js";
Deno.test("enum", () => {
  const ajv = new Ajv2020({ strict: false });
  // moonbit enum compatible
  /**
   * enum Root {
   *   Single,
   *   Positional(Int),
   *   Paramed(x~: String),
   * }
   */
  const jsonschema = {
    type: "array",
    items: {
      oneOf: [
        { const: "Single" },
        {
          type: "array",
          prefixItems: [{ const: "Positional" }, { type: "integer" }],
          maxItems: 2, // positionals and params
        },
        {
          type: "array",
          prefixItems: [
            { const: "Paramed" },
            {
              type: "object",
              required: ["x"],
              properties: { x: { type: "string" } },
            },
          ],
        },
      ],
    },
  };

  const validate = ajv.compile(jsonschema);
  const value = ["Single", ["Positional", 1], ["Paramed", { x: "y" }]];

  const result = validate(value);
  // console.log(result);
  expect(result).toBe(true);

  const maybeErr = validate([
    "Single",
    ["Positional", "not-number"],
    ["Paramed", {}],
  ]);
  expect(maybeErr).toBe(false);
  // console.log(maybeErr);
  // console.log(validate.errors);
});
