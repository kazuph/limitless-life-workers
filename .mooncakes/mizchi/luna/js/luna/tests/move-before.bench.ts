/**
 * DOM operation benchmark tests
 * Run with: pnpm test:browser
 */

import { describe, test, expect, beforeEach, afterEach } from "vitest";

// Extend Element interface for moveBefore (Chrome 133+)
declare global {
  interface Element {
    moveBefore(node: Node, child: Node | null): Node;
  }
}

// Benchmark helper (silent - no console output)
function bench(name: string, fn: () => void, iterations = 1000, warmup = 100) {
  // Warmup
  for (let i = 0; i < warmup; i++) {
    fn();
  }

  // Actual run
  const start = performance.now();
  for (let i = 0; i < iterations; i++) {
    fn();
  }
  const elapsed = performance.now() - start;
  const perOp = elapsed / iterations;

  return { name, elapsed, perOp };
}

describe("moveBefore API", () => {
  let container: HTMLDivElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("moveBefore preserves element reference", () => {
    const ul = document.createElement("ul");
    const li1 = document.createElement("li");
    const li2 = document.createElement("li");
    li1.textContent = "Item 1";
    li2.textContent = "Item 2";
    ul.appendChild(li1);
    ul.appendChild(li2);
    container.appendChild(ul);

    // Store reference
    const originalLi1 = li1;

    // Move li1 to end
    ul.moveBefore(li1, null);

    // Verify it's the same element
    expect(ul.lastChild).toBe(originalLi1);
    expect(ul.children[1]).toBe(originalLi1);
  });

  test("insertBefore also preserves element reference", () => {
    const ul = document.createElement("ul");
    const li1 = document.createElement("li");
    const li2 = document.createElement("li");
    li1.textContent = "Item 1";
    li2.textContent = "Item 2";
    ul.appendChild(li1);
    ul.appendChild(li2);
    container.appendChild(ul);

    // Store reference
    const originalLi1 = li1;

    // Move li1 to end using insertBefore
    ul.insertBefore(li1, null);

    // Verify it's the same element
    expect(ul.lastChild).toBe(originalLi1);
  });
});

describe("moveBefore vs insertBefore benchmark", () => {
  let container: HTMLDivElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  const setupList = (count: number): HTMLUListElement => {
    const ul = document.createElement("ul");
    for (let i = 0; i < count; i++) {
      const li = document.createElement("li");
      li.textContent = `Item ${i}`;
      ul.appendChild(li);
    }
    container.appendChild(ul);
    return ul;
  };

  test("benchmark: single element move", () => {
    const results: { name: string; perOp: number }[] = [];

    results.push(
      bench("insertBefore_single", () => {
        const ul = setupList(10);
        const first = ul.firstChild!;
        ul.insertBefore(first, null);
        ul.remove();
      })
    );

    results.push(
      bench("moveBefore_single", () => {
        const ul = setupList(10);
        const first = ul.firstChild!;
        ul.moveBefore(first, null);
        ul.remove();
      })
    );

    expect(results.length).toBe(2);
  });

  test("benchmark: shuffle 10 elements", () => {
    const results: { name: string; perOp: number }[] = [];

    results.push(
      bench("insertBefore_shuffle_10", () => {
        const ul = setupList(10);
        const children = Array.from(ul.children);
        for (let i = children.length - 1; i >= 0; i--) {
          ul.insertBefore(children[i], ul.firstChild);
        }
        ul.remove();
      })
    );

    results.push(
      bench("moveBefore_shuffle_10", () => {
        const ul = setupList(10);
        const children = Array.from(ul.children);
        for (let i = children.length - 1; i >= 0; i--) {
          ul.moveBefore(children[i], ul.firstChild);
        }
        ul.remove();
      })
    );

    expect(results.length).toBe(2);
  });

  test("benchmark: shuffle 50 elements", () => {
    const results: { name: string; perOp: number }[] = [];

    results.push(
      bench(
        "insertBefore_shuffle_50",
        () => {
          const ul = setupList(50);
          const children = Array.from(ul.children);
          for (let i = children.length - 1; i >= 0; i--) {
            ul.insertBefore(children[i], ul.firstChild);
          }
          ul.remove();
        },
        500
      )
    );

    results.push(
      bench(
        "moveBefore_shuffle_50",
        () => {
          const ul = setupList(50);
          const children = Array.from(ul.children);
          for (let i = children.length - 1; i >= 0; i--) {
            ul.moveBefore(children[i], ul.firstChild);
          }
          ul.remove();
        },
        500
      )
    );

    expect(results.length).toBe(2);
  });

  test("moveBefore preserves iframe state", async () => {
    // Create container with iframe
    const wrapper = document.createElement("div");
    const section1 = document.createElement("section");
    const section2 = document.createElement("section");
    const iframe = document.createElement("iframe");
    iframe.srcdoc = "<html><body>Test content</body></html>";

    wrapper.appendChild(section1);
    wrapper.appendChild(section2);
    section1.appendChild(iframe);
    container.appendChild(wrapper);

    // Wait for iframe to load
    await new Promise((resolve) => {
      iframe.onload = resolve;
      setTimeout(resolve, 100); // Fallback timeout
    });

    // Get iframe content before move
    const contentBefore = iframe.contentDocument?.body?.textContent;

    // Move iframe to section2 using moveBefore
    section2.moveBefore(iframe, null);

    // Check iframe content after move
    const contentAfter = iframe.contentDocument?.body?.textContent;

    // moveBefore should preserve iframe state
    expect(iframe.parentElement).toBe(section2);
    expect(contentAfter).toBe(contentBefore);
  });
});

describe("DOM operation microbenchmarks", () => {
  let container: HTMLDivElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("benchmark: createElement", () => {
    const result = bench("createElement_div", () => {
      document.createElement("div");
    }, 10000);
    expect(result.perOp).toBeLessThan(1);
  });

  test("benchmark: appendChild", () => {
    const result = bench("appendChild", () => {
      const div = document.createElement("div");
      container.appendChild(div);
      div.remove();
    }, 5000);
    expect(result.perOp).toBeLessThan(1);
  });

  test("benchmark: textContent assignment", () => {
    const div = document.createElement("div");
    container.appendChild(div);

    const result = bench("textContent_set", () => {
      div.textContent = "Hello World";
    }, 10000);

    expect(result.perOp).toBeLessThan(1);
  });

  test("benchmark: innerHTML clear", () => {
    const result = bench("innerHTML_clear", () => {
      const div = document.createElement("div");
      div.innerHTML = "<span>test</span><span>test2</span>";
      container.appendChild(div);
      div.innerHTML = "";
      div.remove();
    }, 5000);
    expect(result.perOp).toBeLessThan(1);
  });

  test("benchmark: setAttribute", () => {
    const div = document.createElement("div");
    container.appendChild(div);

    const result = bench("setAttribute", () => {
      div.setAttribute("class", "test-class");
    }, 10000);

    expect(result.perOp).toBeLessThan(1);
  });

  test("benchmark: classList.add", () => {
    const div = document.createElement("div");
    container.appendChild(div);

    const result = bench("classList_add", () => {
      div.classList.add("test-class");
      div.classList.remove("test-class");
    }, 10000);

    expect(result.perOp).toBeLessThan(1);
  });
});
