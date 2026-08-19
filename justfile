set shell := ["sh", "-cu"]

# Show available repository tasks.
default:
    @just --list

# Run native mlplunit tests.
tests *args:
    ./scripts/run-tests {{args}}

# Print selected tools without installing anything.
mlpl-path:
    ./scripts/select-mlpl

mlplunit-path:
    ./scripts/select-mlplunit

# Install or verify a revision-pinned library in a consumer tree.
install library dest revision="HEAD":
    ./scripts/install-library --install --library {{library}} --dest {{dest}} --revision {{revision}}

verify-install library dest:
    ./scripts/install-library --check --library {{library}} --dest {{dest}}

# Run the complete pre-commit gate.
check:
    ./scripts/check
