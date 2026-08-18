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

# Run the complete pre-commit gate.
check:
    ./scripts/check
