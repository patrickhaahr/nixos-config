default:
    @just --list

# Format, clippy with safe autofixes, comment guard and tests: the gate before every commit.
check:
    cargo fmt
    cargo clippy --fix --allow-dirty --allow-staged --all-targets --all-features
    cargo clippy --all-targets --all-features -- -D warnings
    bash tools/comment-guard
    cargo test --all-features

dev *args:
    cargo run -- {{ args }}

build:
    cargo build --release

test-one name:
    cargo test --all-features -- {{ name }} --nocapture
