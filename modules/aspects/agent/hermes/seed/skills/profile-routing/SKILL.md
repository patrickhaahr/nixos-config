---
name: profile-routing
description: Use when deciding which Hermes profile or specialist should handle a request. Select the narrowest owner and preserve profile boundaries.
---

# Profile routing

Use the existing Hermes profile roster as the service map. Keep the default profile minimal and route domain work instead of loading unrelated knowledge here.

## Routing map

- `homelab`: zaza, nika, pi, router, NixOS, k3s, Docker, networking, and self-hosted services
- `coach`: fitness, strength training, health habits, and coaching conversations
- `household`: household operations and smart-home work

## Procedure

1. Resolve the request's scope before matching it to a primary profile. When the user explicitly leaves a name or alias unresolved, use the routing map as a discovery lead, not proof of identity. Follow the ambiguous-name procedure below before assigning the whole investigation to a domain.
2. Check whether a second profile is needed for an independent specialist contribution.
3. Send a complete brief. Do not assume the other profile can see this conversation's context. Preserve uncertainty and distinguish observed evidence from historical leads. Grant full authority: specialists change, restart, fix and install what the task needs without asking first, and say what they changed. Name a boundary only when Patrick set one ("just look", "don't touch X"). Include delivery requirements and evidence paths.
4. Keep credentials, private identifiers, and profile-local memory in the owning profile.
5. Combine results in the default profile only after checking conflicts and verifying side effects.

## Ambiguous-name investigations

1. Enumerate plausible matches across accessible contexts before choosing a referent. Batch independent checks of local file names and contents, conversation history, SSH aliases, host resolution and connector availability. Inspect people or device directories when available and relevant. Do not connect new accounts or contact people just to expand discovery.
2. Search repository roots individually. A parent directory failing `git status` or `git grep` says nothing about repositories beneath it. Treat history as a source of leads and verify current identity and status against live reads.
3. Group matches by underlying entity. Correlate a host, DNS name, SSH alias and device record through identifiers returned by tools. Keep configuration targets, service endpoints and semantic namesakes visible without counting them as additional machines. Do not add unrelated public namesakes without contextual evidence.
4. Delegate each domain-specific candidate to its narrowest specialist. If one underlying entity is confidently identified, proceed to investigate purpose, ownership evidence, configuration and current status. Otherwise, summarize each distinct candidate and ask for the identifier that would distinguish them.
5. Separate configuration intent, deployed resources and runtime behavior. A declared ingress does not prove a listening backend; an inactive optional service does not establish an unintended outage. Distinguish repository commit dates and cached tracking refs from deployment time and current remote synchronization.
6. Report searched contexts and access limits alongside findings. Say 'not identified in the searched contexts' rather than claiming that no matching person or project exists. Do not use malformed or partial directory responses to establish identity or completeness.
7. Honor the requested delivery channel. When the user requests a report through tool output, emit the actual report there, not only its file path, and keep the final chat acknowledgment short. A no-contact instruction also excludes routine completion notifications.

When no profile clearly owns the task, handle planning and research here, then ask Patrick before creating a new specialist boundary.
