{ inputs }:
let
  skill = name: inputs.wshobson-agents + "/plugins/python-development/skills/${name}";
in
{
  python-anti-patterns = skill "python-anti-patterns";
  python-code-style = skill "python-code-style";
  python-error-handling = skill "python-error-handling";
  python-testing-patterns = skill "python-testing-patterns";
  python-type-safety = skill "python-type-safety";
}
