#!/usr/bin/env -S deno run --allow-read --allow-write
/**
 * Generate MoonBit test cases from JSON Schema Test Suite
 *
 * Usage:
 *   deno run --allow-read --allow-write scripts/generate_spec_tests.ts
 */

import { walk } from "https://deno.land/std@0.208.0/fs/walk.ts";
import { basename, join } from "https://deno.land/std@0.208.0/path/mod.ts";

interface TestCase {
  description: string;
  schema: unknown;
  tests: {
    description: string;
    data: unknown;
    valid: boolean;
  }[];
}

// Test files to include (start with basic ones)
const INCLUDE_FILES = [
  "type.json",
  "minimum.json",
  "maximum.json",
  "exclusiveMinimum.json",
  "exclusiveMaximum.json",
  "minLength.json",
  "maxLength.json",
  "minItems.json",
  "maxItems.json",
  "required.json",
  "const.json",
  "enum.json",
  "anyOf.json",
  "allOf.json",
  "oneOf.json",
  "properties.json",
  "items.json",
];

function sanitizeTestName(name: string): string {
  return name
    .replace(/[^a-zA-Z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_|_$/g, "")
    .toLowerCase();
}

function hasProblematicChars(value: unknown): boolean {
  if (typeof value === "string") {
    return /[\x00-\x1f\x7f"\\]/.test(value);
  }
  if (Array.isArray(value)) {
    return value.some(hasProblematicChars);
  }
  if (typeof value === "object" && value !== null) {
    const obj = value as Record<string, unknown>;
    for (const k of Object.keys(obj)) {
      if (/[\x00-\x1f\x7f"\\]/.test(k) || hasProblematicChars(obj[k])) {
        return true;
      }
    }
  }
  return false;
}

function jsonToMoonBit(value: unknown, indent = 0): string {
  if (value === null) {
    // At top level, need to use parse; in nested context, use null literal
    return indent === 0 ? '@json.parse("null")' : "null";
  }
  if (typeof value === "boolean") {
    return value ? "true" : "false";
  }
  if (typeof value === "number") {
    return `${value}`;
  }
  if (typeof value === "string") {
    // Escape backslashes first, then quotes
    const escaped = value
      .replace(/\\/g, "\\\\")
      .replace(/"/g, '\\"');
    return `"${escaped}"`;
  }
  if (Array.isArray(value)) {
    // Use JSON literal syntax for arrays
    const items = value.map(v => jsonToMoonBit(v, indent + 1));
    return `[${items.join(", ")}]`;
  }
  if (typeof value === "object") {
    const obj = value as Record<string, unknown>;
    const keys = Object.keys(obj);
    if (keys.length === 0) {
      return "{}";
    }
    const pairs = keys.map(k => {
      // Escape key
      const escapedKey = k.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
      const v = jsonToMoonBit(obj[k], indent + 1);
      return `"${escapedKey}": ${v}`;
    });
    return `{ ${pairs.join(", ")} }`;
  }
  return `"unsupported"`;
}

function generateTestCode(
  filename: string,
  testGroups: TestCase[],
  usedNames: Set<string>
): string {
  const lines: string[] = [];
  const baseTestName = sanitizeTestName(basename(filename, ".json"));

  lines.push("// Auto-generated from JSON Schema Test Suite");
  lines.push(`// Source: ${filename}`);
  lines.push("");

  let testIndex = 0;
  let skipped = 0;
  for (const group of testGroups) {
    const groupName = sanitizeTestName(group.description);

    // Skip tests with problematic characters in schema
    if (hasProblematicChars(group.schema)) {
      skipped += group.tests.length;
      continue;
    }

    for (const test of group.tests) {
      testIndex++;

      // Skip tests with problematic characters in data
      if (hasProblematicChars(test.data)) {
        skipped++;
        continue;
      }

      const testName = sanitizeTestName(test.description);
      let fullTestName = `spec_${baseTestName}_${groupName}_${testName}`;

      // Truncate long test names and ensure uniqueness
      let safeName = fullTestName.substring(0, 70);
      if (usedNames.has(safeName)) {
        safeName = `${safeName}_${testIndex}`;
      }
      usedNames.add(safeName);

      lines.push("///|");
      lines.push(`test "${safeName}" {`);
      lines.push(`  let schema : Json = ${jsonToMoonBit(group.schema)}`);
      lines.push(`  let data : Json = ${jsonToMoonBit(test.data)}`);
      lines.push(`  let validator = build_validator(schema)`);
      lines.push(`  let result = validator.validate(data)`);

      if (test.valid) {
        lines.push(`  guard result is Ok(_)`);
      } else {
        lines.push(`  guard result is Err(_)`);
      }

      lines.push("}");
      lines.push("");
    }
  }

  if (skipped > 0) {
    lines.unshift(`// Skipped ${skipped} tests with special characters`);
  }

  return lines.join("\n");
}

async function main() {
  const testSuiteDir = "test-suite/tests/draft2020-12";
  const outputDir = "src/validate";

  // Check if test suite exists
  try {
    await Deno.stat(testSuiteDir);
  } catch {
    console.error(`Test suite not found at ${testSuiteDir}`);
    console.error("Please clone: git clone https://github.com/json-schema-org/JSON-Schema-Test-Suite.git test-suite");
    Deno.exit(1);
  }

  const allTests: string[] = [];
  const usedNames = new Set<string>();

  for (const filename of INCLUDE_FILES) {
    const filepath = join(testSuiteDir, filename);

    try {
      const content = await Deno.readTextFile(filepath);
      const testGroups: TestCase[] = JSON.parse(content);

      const testCode = generateTestCode(filename, testGroups, usedNames);
      allTests.push(testCode);

      console.log(`Generated tests from ${filename}: ${testGroups.reduce((sum, g) => sum + g.tests.length, 0)} tests`);
    } catch (err) {
      console.warn(`Skipping ${filename}: ${err}`);
    }
  }

  // Write all tests to a single file
  const outputPath = join(outputDir, "spec_test.mbt");
  const header = `// JSON Schema Test Suite - Auto-generated
// Do not edit manually. Regenerate with:
//   deno run --allow-read --allow-write scripts/generate_spec_tests.ts

`;

  await Deno.writeTextFile(outputPath, header + allTests.join("\n"));
  console.log(`\nWritten to ${outputPath}`);
}

main();
