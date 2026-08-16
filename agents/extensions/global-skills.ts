import {
  formatSkillsForPrompt,
  getAgentDir,
  getSettingsListTheme,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type Skill,
} from "@earendil-works/pi-coding-agent";
import { existsSync } from "node:fs";
import { readFile, rename, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { Container, type SettingItem, SettingsList, Text } from "@earendil-works/pi-tui";

const statePath = join(getAgentDir(), "enabled-skills.json");

type Profiles = Map<string, Set<string>>;

function isGlobal(skill: Skill): boolean {
  return skill.sourceInfo.scope === "user";
}

function parseProfiles(value: unknown): Profiles | undefined {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return undefined;

  const profiles: Profiles = new Map();
  for (const [repo, names] of Object.entries(value)) {
    if (!Array.isArray(names) || !names.every((name) => typeof name === "string")) return undefined;
    profiles.set(repo, new Set(names));
  }
  return profiles;
}

async function loadProfiles(): Promise<Profiles> {
  if (!existsSync(statePath)) return new Map();
  const profiles = parseProfiles(JSON.parse(await readFile(statePath, "utf8")));
  if (!profiles) throw new Error(`Invalid skill state in ${statePath}`);
  return profiles;
}

async function saveProfiles(profiles: Profiles): Promise<void> {
  const json = Object.fromEntries(
    [...profiles].sort(([left], [right]) => left.localeCompare(right)).map(([repo, names]) => [
      repo,
      [...names].sort(),
    ]),
  );
  const temporaryPath = `${statePath}.${process.pid}.tmp`;
  await writeFile(temporaryPath, `${JSON.stringify(json, null, 2)}\n`);
  await rename(temporaryPath, statePath);
}

async function findRepo(pi: ExtensionAPI, cwd: string): Promise<string> {
  const result = await pi.exec("git", ["-C", cwd, "rev-parse", "--show-toplevel"]);
  return resolve(result.code === 0 && result.stdout.trim() ? result.stdout.trim() : cwd);
}

/** Registers the repository-scoped global skill toggle command. */
export default function globalSkillsExtension(pi: ExtensionAPI): void {
  let profiles: Profiles = new Map();
  let repo = "";
  let enabledSkills = new Set<string>();

  pi.on("session_start", async (_event, ctx) => {
    repo = await findRepo(pi, ctx.cwd);
    try {
      profiles = await loadProfiles();
    } catch (error) {
      profiles = new Map();
      ctx.ui.notify(String(error), "warning");
    }
    enabledSkills = new Set(profiles.get(repo));
  });

  pi.on("before_agent_start", (event) => {
    const skills = event.systemPromptOptions.skills ?? [];
    const visibleSkills = skills.filter((skill) => !isGlobal(skill) || enabledSkills.has(skill.name));
    const currentSection = formatSkillsForPrompt(skills);

    return {
      systemPrompt: currentSection
        ? event.systemPrompt.replace(currentSection, formatSkillsForPrompt(visibleSkills))
        : event.systemPrompt,
    };
  });

  pi.on("input", (event, ctx) => {
    const name = event.text.match(/^\/skill:([a-z0-9-]+)(?:\s|$)/)?.[1];
    const isGlobalSkill = pi
      .getCommands()
      .some(
        (command) =>
          command.name === `skill:${name}` && command.source === "skill" && command.sourceInfo.scope === "user",
      );
    if (!name || !isGlobalSkill || enabledSkills.has(name)) return { action: "continue" };

    ctx.ui.notify(`Skill ${name} is disabled for this repository. Use /skills ${name} to enable it.`, "warning");
    return { action: "handled" };
  });

  async function persist(ctx: Pick<ExtensionCommandContext, "ui">): Promise<void> {
    profiles.set(repo, new Set(enabledSkills));
    try {
      await saveProfiles(profiles);
    } catch (error) {
      ctx.ui.notify(`Could not save ${statePath}: ${String(error)}`, "error");
    }
  }

  pi.registerCommand("skills", {
    description: "Enable or disable global skills for this repository",
    getArgumentCompletions(prefix) {
      return pi
        .getCommands()
        .filter((command) => command.source === "skill" && command.sourceInfo.scope === "user")
        .map((command) => command.name.replace(/^skill:/, ""))
        .filter((name) => name.startsWith(prefix))
        .map((name) => ({ value: name, label: name }));
    },
    handler: async (args, ctx) => {
      const globalSkills = (ctx.getSystemPromptOptions().skills ?? []).filter(isGlobal);
      const names = globalSkills.map((skill) => skill.name).sort();
      const requestedName = args.trim();

      if (requestedName) {
        if (!names.includes(requestedName)) {
          ctx.ui.notify(`Unknown global skill: ${requestedName}`, "error");
          return;
        }
        if (!enabledSkills.delete(requestedName)) enabledSkills.add(requestedName);
        await persist(ctx);
        ctx.ui.notify(`${enabledSkills.has(requestedName) ? "Enabled" : "Disabled"} ${requestedName}`, "info");
        return;
      }

      if (ctx.mode !== "tui") {
        ctx.ui.notify("/skills requires TUI mode when no skill name is supplied", "error");
        return;
      }

      let pendingSave = Promise.resolve();
      await ctx.ui.custom<void>((tui, theme, _keybindings, done) => {
        const container = new Container();
        container.addChild(new Text(theme.fg("accent", theme.bold(`Skills for ${repo}`)), 1, 1));

        const items: SettingItem[] = names.map((name) => ({
          id: name,
          label: name,
          currentValue: enabledSkills.has(name) ? "enabled" : "disabled",
          values: ["disabled", "enabled"],
        }));
        const settings = new SettingsList(
          items,
          Math.min(items.length + 2, 15),
          getSettingsListTheme(),
          (name, value) => {
            if (value === "enabled") enabledSkills.add(name);
            else enabledSkills.delete(name);
            pendingSave = pendingSave.then(() => persist(ctx));
          },
          () => done(undefined),
          { enableSearch: true },
        );
        container.addChild(settings);

        return {
          render: (width) => container.render(width),
          invalidate: () => container.invalidate(),
          handleInput: (data) => {
            settings.handleInput(data);
            tui.requestRender();
          },
        };
      });
      await pendingSave;
    },
  });
}
