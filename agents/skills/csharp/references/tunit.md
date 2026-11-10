# TUnit

TUnit-specific rules for assertions, lifecycle, shared resources and parallelism.

## Assertions
- `await` every `Assert.That(...)`: an unawaited assertion never runs and the test passes.
- Use the most specific assertion (`IsEqualTo(5)`, not `That(x == 5).IsTrue()`) so the failure shows both values.

## Lifecycle
- TUnit creates a new test-class instance per test, so instance fields never carry state between tests.
- Hooks run per level: `[Before(Test)]` / `[After(Test)]` per test, `(Class)` once per class, `(Assembly)` once per assembly.
- Share an expensive resource (web host, database, container) through `[ClassDataSource<T>]` with `T : IAsyncInitializer, IAsyncDisposable`, injected through the test class constructor. Pick `Shared = SharedType.PerTestSession` (whole run), `PerAssembly`, `PerClass` or `Keyed`; the default `None` builds one per test. Prefer this over static fields set in class or assembly hooks.

```csharp
[ClassDataSource<TestWebServer>(Shared = SharedType.PerTestSession)]
public class ApiTests(TestWebServer server)
{
    [Test]
    public async Task Health_endpoint_returns_ok()
    {
        var response = await server.Factory.CreateClient().GetAsync("/api/health");
        await Assert.That(response.IsSuccessStatusCode).IsTrue();
    }
}
```

## Parallelism
- Tests run in parallel by default: give each test its own data (fresh IDs, its own rows or files).
- Serialize only what conflicts, with a key: `[NotInParallel("files")]` keeps tests sharing that key apart while everything else stays parallel.
- Order dependent steps with `[DependsOn(nameof(Step1))]`, which keeps unrelated tests parallel; `NotInParallel(Order = n)` serializes the whole run.
- Cap concurrency with `--maximum-parallel-tests` or `[assembly: ParallelLimiter<T>]`.
- Keep `[Matrix]` and data sources small; each combination is a separate test at discovery.
