# Default task: sync dependencies, generate BAML client, and lint
default: sync baml-generate lint

# Sync dependencies using uv
sync *args:
    #!/usr/bin/env -S bash -euo pipefail
    uv sync {{args}}

# Generate the BAML client
baml-generate *args:
    #!/usr/bin/env -S bash -euo pipefail
    echo "Generating BAML client..."
    (cd src/taskgist; uv run baml-cli generate {{args}})

# Run BAML tests
baml-test *args: baml-generate
    #!/usr/bin/env -S bash -euo pipefail
    (cd src/taskgist; uv run baml-cli test {{args}}) # baml-cli test usually discovers tests in baml_src/

# Lint the Python code with ruff
lint *args:
    #!/usr/bin/env -S bash -euo pipefail
    uv run ruff check {{args}} .

# Format the Python code with ruff
format *args:
    #!/usr/bin/env -S bash -euo pipefail
    uv run ruff format {{args}} .

# Build the Python package (sdist and wheel)
build *args: sync baml-generate
    #!/usr/bin/env -S bash -euo pipefail
    uv build {{args}}

# Run the taskgist CLI tool. Synopsis: just run "Create a new feature"
run *args:
    #!/usr/bin/env -S bash -euo pipefail
    uv run taskgist -- "{{args}}"

# Install the package in editable mode (uv sync usually handles this for projects)
# This is mostly for explicit re-installation if needed.
install-editable:
    #!/usr/bin/env -S bash -euo pipefail
    uv pip install -e .

# Clean up build artifacts, caches, and generated files
clean:
    #!/usr/bin/env -S bash -euo pipefail
    rm -rf dist/
    rm -rf .eggs/
    rm -rf *.egg-info/
    rm -rf .pytest_cache/
    rm -rf .ruff_cache/
    rm -rf .mypy_cache/
    rm -rf src/taskgist/__pycache__/
    rm -rf src/taskgist/baml_client/ # Remove generated BAML client
    # Be careful with .venv if you have specific configurations in it.
    # For a full clean that requires re-syncing:
    # rm -rf .venv/
    echo "Cleaned build artifacts and caches. For a full venv clean, manually remove .venv and re-run 'just sync'."

# Publish the package to PyPI (requires credentials and built artifacts)
# Make sure you have built the package first (just build)
# You might need to configure UV_PUBLISH_TOKEN or username/password
# publish-pypi: build
# echo "Publishing to PyPI..."
# uv publish dist/*

# Publish the package to TestPyPI
# publish-testpypi: build
# echo "Publishing to TestPyPI..."
# uv publish --repository-url https://test.pypi.org/legacy/ dist/*

# Generate a directory snapshot for the project (from your original example)
snapshot:
    #!/usr/bin/env -S bash -euo pipefail
    project_name="$(basename "${PWD%.git}")"
    snapshot_filename=".${project_name}_repo_snapshot.md"
    echo "Creating snapshot: ${snapshot_filename}"
    # Ensure dir2prompt is available or replace with tree/ls commands
    # For this example, assuming dir2prompt is a custom tool.
    # If not, you might use: tree -L 2 -a -I '.git|.venv|__pycache__|.ruff_cache|dist|*.egg-info' > "${snapshot_filename}"
    # Or a more complex script to mimic dir2prompt.
    # For now, lets use a placeholder if dir2prompt is not found.
    if command -v dir2prompt &> /dev/null; then
        dir2prompt > "${snapshot_filename}"
    else
        echo "dir2prompt command not found. Using tree instead for snapshot."
        tree -L 3 -a -I '.git|.venv|__pycache__|.ruff_cache|dist|*.egg-info|src/taskgist/baml_client' > "${snapshot_filename}"
    fi
    wc -c "${snapshot_filename}"

# --- Release Automation ---
# Helper script for versioning: scripts/bump_version.py

# Pre-flight checks for release tasks
_pre_flight_checks:
    #!/usr/bin/env -S bash -euo pipefail
    echo "Performing pre-flight checks..."
    if ! git diff --quiet --exit-code; then
        echo "Error: Working directory is not clean. Please commit or stash changes." >&2; exit 1;
    fi
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    # Adjust 'main' if your primary development branch is different (e.g., 'master')
    if [[ "$current_branch" != "main" ]]; then
        echo "Error: Not on 'main' branch. Current branch: $current_branch" >&2; exit 1;
    fi
    echo "Pulling latest changes from origin $current_branch..."
    git pull origin "$current_branch" --ff-only # Ensure fast-forward only, or handle merge if preferred
    echo "Pre-flight checks passed."


# Common release logic used by specific release tasks
# This recipe is called with the NEW_VERSION and DRY_RUN status
_common_release new_version dry_run='false':
    #!/usr/bin/env -S bash -euo pipefail
    set -e # Exit on any error
    new_version="{{new_version}}"
    dry_run="{{dry_run}}"
    CURRENT_VERSION_FROM_FILE=$(python scripts/bump_version.py current) # Get actual current from file before any changes
    echo "Current version in file: $CURRENT_VERSION_FROM_FILE"
    echo "Target version for this release: $new_version"

    if [[ "$dry_run" == "true" ]]; then
        echo ""
        echo "--- DRY RUN MODE ---"
        if [[ "$new_version" != "$CURRENT_VERSION_FROM_FILE" ]]; then
            echo "Would update 'src/taskgist/__init__.py' from $CURRENT_VERSION_FROM_FILE to $new_version."
        else
            echo "Version in 'src/taskgist/__init__.py' would remain $new_version (already set or no change needed)."
        fi
        echo "Would commit 'src/taskgist/__init__.py' with message 'Bump version to v$new_version'."
        echo "Would create annotated tag 'v$new_version' with message 'Version v$new_version'."
        current_branch_for_dry_run=$(git rev-parse --abbrev-ref HEAD)
        echo "Would push '$current_branch_for_dry_run' branch and tag 'v$new_version' to origin."
        echo "--- END DRY RUN ---"
        exit 0
    fi

    # Actual operations
    # The Python script (called by release-patch/minor/major/set) has already updated the version file.
    # We verify the file content here.
    VERSION_IN_FILE_AFTER_SCRIPT=$(python scripts/bump_version.py current)
    if [[ "$VERSION_IN_FILE_AFTER_SCRIPT" != "$new_version" ]]; then
        echo "Error: Version in file ($VERSION_IN_FILE_AFTER_SCRIPT) does not match target version ($new_version) after script execution." >&2
        echo "This might indicate an issue with scripts/bump_version.py or the release process." >&2
        exit 1
    fi
    echo "Version in 'src/taskgist/__init__.py' confirmed as $new_version."
    
    echo "Committing version update..."
    git add src/taskgist/__init__.py
    git commit -m "Bump version to v$new_version"

    echo "Creating annotated tag v$new_version..."
    # Use -s for GPG signing if you have it configured, otherwise -a is fine.
    git tag -a "v$new_version" -m "Version v$new_version"

    current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "Pushing $current_branch branch and tag v$new_version to origin..."
    git push origin "$current_branch"
    git push origin "v$new_version" # Push the specific tag

    echo ""
    echo "SUCCESS: Release v$new_version successfully prepared and pushed to origin."
    echo "GitHub Actions CI should now pick up the tag 'v$new_version' and create a GitHub Release."

# Release a new patch version
# Usage: just release-patch [--dry-run]
release-patch *args: _pre_flight_checks
    #!/usr/bin/env -S bash -euo pipefail
    args="{{args}}"
    DRY_RUN=false
    if [[ "$args" == "--dry-run" ]]; then DRY_RUN=true; fi
    
    echo "Determining new patch version..."
    # Python script updates file if not dry_run, and prints new version to stdout as its last line.
    NEW_VERSION_OUTPUT=$(python scripts/bump_version.py bump patch)
    NEW_VERSION=$(echo "$NEW_VERSION_OUTPUT" | tail -n1) # Capture the last line (the version)

    just _common_release "$NEW_VERSION" "$DRY_RUN"

# Release a new minor version
# Usage: just release-minor [--dry-run]
release-minor *args: _pre_flight_checks
    #!/usr/bin/env -S bash -euo pipefail
    args="{{args}}"
    DRY_RUN=false
    if [[ "$args" == "--dry-run" ]]; then DRY_RUN=true; fi

    echo "Determining new minor version..."
    NEW_VERSION_OUTPUT=$(python scripts/bump_version.py bump minor)
    NEW_VERSION=$(echo "$NEW_VERSION_OUTPUT" | tail -n1)

    just _common_release "$NEW_VERSION" "$DRY_RUN"

# Release a new major version
# Usage: just release-major [--dry-run]
release-major *args: _pre_flight_checks
    #!/usr/bin/env -S bash -euo pipefail
    args="{{args}}"
    DRY_RUN=false
    if [[ "$args" == "--dry-run" ]]; then DRY_RUN=true; fi

    echo "Determining new major version..."
    NEW_VERSION_OUTPUT=$(python scripts/bump_version.py bump major)
    NEW_VERSION=$(echo "$NEW_VERSION_OUTPUT" | tail -n1)

    just _common_release "$NEW_VERSION" "$DRY_RUN"

# Set and release a specific version
# Usage: just release-set 1.2.3 [--dry-run]
release-set version *args: _pre_flight_checks
    #!/usr/bin/env -S bash -euo pipefail
    args="{{args}}"
    DRY_RUN=false
    if [[ "$args" == "--dry-run" ]]; then DRY_RUN=true; fi

    if ! [[ "{{version}}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format '{{version}}'. Must be X.Y.Z." >&2; exit 1;
    fi
    
    echo "Setting version to {{version}}..."
    NEW_VERSION_OUTPUT=$(python scripts/bump_version.py set "{{version}}")
    NEW_VERSION=$(echo "$NEW_VERSION_OUTPUT" | tail -n1)

    just _common_release "$NEW_VERSION" "$DRY_RUN"
