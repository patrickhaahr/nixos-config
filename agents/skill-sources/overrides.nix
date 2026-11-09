let
  manual = description: {
    inherit description;
    disable-model-invocation = true;
  };
in
{
  effect.description = "Invoke when working in TypeScript code that uses Effect.";
  react-best-practices.description = "Invoke when writing, reviewing or optimizing React or Next.js code.";
  rust-best-practices.description = "Invoke when working in .rs code.";
  test-audit.description = "Invoke when writing, changing or reviewing tests.";

  better-accessibility.disable-model-invocation = true;
  better-auth-best-practices.disable-model-invocation = true;
  better-auth-security-best-practices.disable-model-invocation = true;
  cloudflare.disable-model-invocation = true;
  wrangler.disable-model-invocation = true;
  install-anti-slop.disable-model-invocation = true;
  better-colors.disable-model-invocation = true;
  better-interface.disable-model-invocation = true;
  better-layout.disable-model-invocation = true;
  better-typography.disable-model-invocation = true;
  better-ui.disable-model-invocation = true;
  better-writing.disable-model-invocation = true;
  grilling.disable-model-invocation = true;

  ai-seo = manual "Optimize content to be cited in AI answers such as ChatGPT, Perplexity and AI Overviews.";
  animate = manual "Build a web animation: purpose, properties, curve, duration and interruption.";
  awwwards = manual "Build an award-caliber portfolio, brand or launch site from a one-line brief.";
  design-taste-frontend = manual "Design or restyle a marketing or company website to a professional standard.";
  diagram-design = manual "Create architecture, flow, sequence and data diagrams as HTML or SVG.";
  frontend-slides = manual "Build an animated HTML slide deck, or convert a PPTX to web slides.";
  security-audit = manual "Security review or audit of a codebase, API or service.";
  seo-audit = manual "Audit a site's technical and on-page SEO and diagnose ranking drops.";
}
