# External skills: GitHub repo -> { skill name = folder in the repo; }.
# "" installs the whole repo as one skill. Pins live in sources.lock.json;
# after any change here run `just update-skills <owner/repo>`.
{
  "apollographql/skills".rust-best-practices = "skills/rust-best-practices";
  "better-auth/skills" = {
    better-auth-best-practices = "better-auth/best-practices";
    better-auth-security-best-practices = "security";
  };
  "cathrynlavery/diagram-design".diagram-design = "skills/diagram-design";
  "cloudflare/security-audit-skill".security-audit = "skills/security-audit";
  "cloudflare/skills" = {
    cloudflare = "skills/cloudflare";
    wrangler = "skills/wrangler";
  };
  "coreyhaines31/marketingskills" = {
    ai-seo = "skills/ai-seo";
    seo-audit = "skills/seo-audit";
  };
  "dmmulroy/anti-slop".install-anti-slop = "skills/install-anti-slop";
  "emilkowalski/skills".animate = "skills/animate";
  "jakubkrehel/skills" = {
    better-accessibility = "skills/better-accessibility";
    better-colors = "skills/better-colors";
    better-interface = "skills/better-interface";
    better-layout = "skills/better-layout";
    better-typography = "skills/better-typography";
    better-ui = "skills/better-ui";
    better-writing = "skills/better-writing";
    interface-review = "skills/interface-review";
  };
  "juliobsz/skills".awwwards = "awwwards";
  "kitlangton/skills".effect = "skills/effect";
  "Leonxlnx/taste-skill".design-taste-frontend = "skills/taste-skill";
  "mattpocock/skills" = {
    code-review = "skills/engineering/code-review";
    codebase-design = "skills/engineering/codebase-design";
    diagnosing-bugs = "skills/engineering/diagnosing-bugs";
    domain-modeling = "skills/engineering/domain-modeling";
    grill-with-docs = "skills/engineering/grill-with-docs";
    grilling = "skills/productivity/grilling";
    handoff = "skills/productivity/handoff";
    improve-codebase-architecture = "skills/engineering/improve-codebase-architecture";
    research = "skills/engineering/research";
    retro = "skills/engineering/retro";
    tdd = "skills/engineering/tdd";
    teach = "skills/productivity/teach";
    to-spec = "skills/engineering/to-spec";
    to-tickets = "skills/engineering/to-tickets";
    writing-for-agents = "skills/productivity/writing-for-agents";
  };
  "openclaw/openclaw".test-audit = ".agents/skills/test-audit";
  "shadcn/improve".improve = "skills/improve";
  "vercel-labs/agent-skills".react-best-practices = "skills/react-best-practices";
  "zarazhangrui/frontend-slides".frontend-slides = "";

  # Not installed. Uncomment and run `just update-skills <owner/repo>` to enable.
  # "cursor/plugins".unslop = "pstack/skills/unslop";
  # "typesafe-ai/skills".typesafe-ai = "skills/typesafe-ai";
  # "vercel-labs/agent-browser".agent-browser = "skills/agent-browser";
}
