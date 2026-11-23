let
  manual = description: {
    inherit description;
    disable-model-invocation = true;
  };
in
{
  rust-best-practices.description = "Invoke when working in .rs code.";
  test-audit.description = "Invoke when writing, changing or reviewing tests.";

  install-anti-slop.disable-model-invocation = true;

  ai-seo = manual "Optimize content to be cited in AI answers such as ChatGPT, Perplexity and AI Overviews.";
  effect = manual "Write or review TypeScript that uses Effect.";
  diagram-design = manual "Create architecture, flow, sequence and data diagrams as HTML or SVG.";
  improve = manual "Audit a codebase and write self-contained improvement plans for other agents to execute.";
  frontend-slides = manual "Build an animated HTML slide deck, or convert a PPTX to web slides.";
  security-audit = manual "Security review or audit of a codebase, API or service.";
  seo-audit = manual "Audit a site's technical and on-page SEO and diagnose ranking drops.";
}
