Implement the work described by the user in the spec or tickets.

Use `/tdd` where possible, at pre-agreed seams.

Run focused typechecking and tests while implementing.

Once done, deploy `reviewer` with the diff or changed hunks, changed file paths, acceptance criteria, and concise change summary. If it reports blocker, high, or medium findings, deploy one NEW `worker` with those findings and the change scope. Then resume the same reviewer session once with only the worker's diff and unresolved findings.

Stop correctness review after at most three reviewer calls: the initial review and two resumed follow-up. Report remaining findings instead of starting another worker or fresh reviewer.

After correctness review is clean, deploy `simplifier` once with the diff or changed hunks and changed file paths for a final advisory pass. Do not resume it and do not launch a worker for low-severity or optional cleanup.

Run the full project validation once after all changes, then come up with a git commit message but do not commit.
