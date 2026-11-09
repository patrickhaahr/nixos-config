use std::io::Write as _;

fn main() -> std::io::Result<()> {
    writeln!(std::io::stdout().lock(), "Hello, world!")
}
