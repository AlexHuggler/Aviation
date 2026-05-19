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

  it("matches the anonymous RevenueCat App Privacy label", async () => {
    const html = await readSiteFile("privacy/index.html");

    expect(html).toContain("SoloTrack uses anonymous RevenueCat app user IDs");
    expect(html).toContain("Purchases &gt; Purchase History");
    expect(html).toContain("Data Linked to You:</strong> None");
    expect(html).toContain("Data Not Linked to You:</strong> Purchases");
    expect(html).toContain("does not use custom RevenueCat app user IDs, IDFA, or App Tracking Transparency");
  });
});

describe("App Store launch readiness copy", () => {
  it("does not publish stale beta, no-subscription, or no-RevenueCat claims", async () => {
    const publicFiles = [
      "index.html",
      "privacy/index.html",
      "terms/index.html",
      "support/index.html",
      "contact/index.html",
      "blog/what-solotrack-does/index.html",
      "blog/privacy-first-pilot-logbook/index.html",
      "partners/fly8ma/index.html"
    ];

    for (const path of publicFiles) {
      const html = await readSiteFile(path);

      expect(html, path).not.toMatch(/free beta|no subscriptions|no RevenueCat|purchase-or-paywall SDKs|Apple frameworks only|TODO: Add postal/i);
      expect(html, path).not.toMatch(/The Free iOS Flight Logbook|The free iOS flight logbook/i);
    }
  });

  it("homepage introduces the v1.0 Pro subscription offer", async () => {
    const html = await readSiteFile("index.html");

    expect(html).toContain("SoloTrack Pro");
    expect(html).toContain("30-day free trial");
    expect(html).toContain("RevenueCat");
  });
});

describe("FLY8MA partner explainer", () => {
  it("is an unlisted noindex page with the partner video assets", async () => {
    const html = await readSiteFile("partners/fly8ma/index.html");

    expect(html).toContain('<meta name="robots" content="noindex,follow">');
    expect(html).toContain('/assets/media/solotrack-beta-landscape.mp4');
    expect(html).toContain('/assets/media/solotrack-beta-landscape-still.png');
    expect(html).toContain("FLY8MA teaches students what they need to know");
    expect(html).toContain("SoloTrack helps them track what they have actually flown");
    expect(html).toContain("not an EFB");
    expect(html).toContain("not a substitute for a CFI");
  });

  it("does not expose the partner page in public navigation or sitemap", async () => {
    const home = await readSiteFile("index.html");
    const sitemap = await readSiteFile("sitemap.xml");

    expect(home).not.toContain("/partners/fly8ma/");
    expect(sitemap).not.toContain("/partners/fly8ma/");
  });
});
