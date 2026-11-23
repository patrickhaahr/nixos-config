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

  better-auth-best-practices.disable-model-invocation = true;
  better-auth-security-best-practices.disable-model-invocation = true;
  install-anti-slop.disable-model-invocation = true;

  ai-seo = manual "Optimize content to be cited in AI answers such as ChatGPT, Perplexity and AI Overviews.";
  diagram-design = manual "Create architecture, flow, sequence and data diagrams as HTML or SVG.";
  improve = manual "Audit a codebase and write self-contained improvement plans for other agents to execute.";
  frontend-slides = manual "Build an animated HTML slide deck, or convert a PPTX to web slides.";
  security-audit = manual "Security review or audit of a codebase, API or service.";
  seo-audit = manual "Audit a site's technical and on-page SEO and diagnose ranking drops.";
}
