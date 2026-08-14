{ inputs, pkgs }:
{
  install-anti-slop = inputs.anti-slop + "/skills/install-anti-slop";

  code-standards-typescript = pkgs.runCommand "code-standards-typescript-skill" { } ''
    mkdir -p "$out"
    {
      printf '%s\n' '---'
      printf '%s\n' 'name: code-standards-typescript'
      printf '%s\n' 'description: TypeScript/React coding standards covering local style, errors as values, parsing, domain types, modules, adapters, testing, and agent implementation choices. Invoke this skill always when working in TypeScript language.'
      printf '%s\n' '---'
      printf '\n'
      printf '%s\n' '## Local Style Rules'
      printf '\n'
      printf '%s\n' '- Use ES modules with proper import sorting and extensions'
      printf '%s\n' '- Prefer `function` keyword over arrow functions for top-level'
      printf '%s\n' '- Explicit return type annotations for exported functions'
      printf '%s\n' '- React: explicit Props types, function components'
      printf '%s\n' '- Never use `any`; prefer precise types, generics, `unknown`, or narrowing'
      printf '%s\n' '- Avoid try/catch when possible (return errors as values)'
      printf '%s\n' '- No nested ternaries - use switch or if/else chains'
      printf '\n'
      printf '%s\n' '## Full-Stack TypeScript Additions'
      printf '\n'
      printf '%s\n' '- Let types flow end-to-end from DB/schema to server to client with the project'
      printf '%s\n' '  established tool, such as tRPC, oRPC, Elysia, or TanStack Start.'
      printf '%s\n' '- Do not restate types you can derive. Prefer `Pick`, `Omit`, `Parameters`,'
      printf '%s\n' '  `ReturnType`, `Awaited`, `typeof`, and source-of-truth inference before writing'
      printf '%s\n' '  a new interface.'
      printf '%s\n' '- Pass objects instead of positional arguments by default, except on proven hot'
      printf '%s\n' '  performance-critical paths.'
      printf '%s\n' '- For shared validation helpers that should not pick a validator, accept'
      printf '%s\n' '  `StandardSchemaV1<unknown, T>`.'
      printf '%s\n' '- Prefer real integration seams over mocks: LocalStack for AWS, Miniflare for'
      printf '%s\n' '  Cloudflare Workers, and real Postgres or SQLite when storage behavior matters.'
      printf '%s\n' '- When adding observability, use OpenTelemetry spans instead of print logging.'
      printf '\n'
      cat ${inputs.dmmulroy-coding-standards}/coding-standards-draft.md
    } > "$out/SKILL.md"
  '';
}
