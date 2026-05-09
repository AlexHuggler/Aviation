import { readFile } from "node:fs/promises";
import { describe, expect, it } from "vitest";

async function readSiteFile(path: string): Promise<string> {
  return readFile(new URL(`../${path}`, import.meta.url), "utf8");
}

describe("beta form page", () => {
  it("submits beta applications to a managed HTTPS form endpoint", async () => {
    const html = await readSiteFile("index.html");

    expect(html).toContain('action="https://formsubmit.co/ajax/Contact@solo-track.com"');
    expect(html).toContain('method="POST"');
    expect(html).toContain('headers: { \'Accept\': \'application/json\' }');
    expect(html).toContain('id="formStatus"');
    expect(html).toContain('aria-live="polite"');
    expect(html).toContain('href="mailto:Contact@solo-track.com"');
    expect(html).not.toContain("https://forms.solo-track.com");
    expect(html).not.toContain("mailto:Contact@solo-track.com?");
    expect(html).not.toContain("mailto:Contact@solo-track.com?subject=${subject}&body=${body}");
  });
});

describe("privacy policy", () => {
  it("discloses voluntary beta enrollment contact information collection", async () => {
    const html = await readSiteFile("privacy/index.html");

    expect(html).toContain("Beta enrollment contact information");
    expect(html).toContain("voluntarily submit through the beta application form");
    expect(html).toContain("managed form submission provider");
    expect(html).toContain("do not operate our own beta form collection backend");
    expect(html).toContain("not used for tracking");
  });
});
