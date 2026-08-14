Implement the work described by the user in the spec or tickets.

Use `/tdd` where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, deploy the `reviewer` and `simplifier` subagents concurrently with the same change scope. If either reports findings, deploy the `worker` subagent with both completed verdicts and the change scope. The worker implements confirmed fixes and runs validation after the implementation.

Repeat the concurrent reviews and worker handoff until both reviewers reply `satisfied`. Then come up with a git commit message, but do not commit.
