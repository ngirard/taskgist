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
    # For now, let's use a placeholder if dir2prompt is not found.
    if command -v dir2prompt &> /dev/null; then
        dir2prompt > "${snapshot_filename}"
    else
        echo "dir2prompt command not found. Using tree instead for snapshot."
        tree -L 3 -a -I '.git|.venv|__pycache__|.ruff_cache|dist|*.egg-info|src/taskgist/baml_client' > "${snapshot_filename}"
    fi
    wc -c "${snapshot_filename}"
