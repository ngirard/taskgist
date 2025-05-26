# Taskgist

[![PyPI version](https://img.shields.io/pypi/v/taskgist.svg?style=flat-square)](https://pypi.org/project/taskgist/)
[![Python versions](https://img.shields.io/pypi/pyversions/taskgist.svg?style=flat-square)](https://pypi.org/project/taskgist/)
[![License](https://img.shields.io/pypi/l/taskgist.svg?style=flat-square)](https://opensource.org/licenses/MIT)

Taskgist generates a concise, hyphenated "gist" or keyword phrase from a software engineering task description. It uses [BoundaryML (BAML)](https://docs.boundaryml.com/) to interact with Google's Gemini Large Language Models (LLMs) for intelligent keyword extraction.

## Overview

Taskgist is a command-line tool designed to quickly summarize development tasks into a short, memorable, and usable string. This "gist" can be useful for:

* Generating branch names (e.g., `feature/create-user-auth`).
* Prefixing commit messages.
* Quick task identifiers in notes or discussions.

The tool processes natural language task descriptions, extracts key actions and terms, and formats them into a hyphenated phrase.

## Features

* **LLM-powered summarization**: Leverages Google's Gemini models via BAML for nuanced keyword extraction.
* **Concise output**: Generates short, hyphenated phrases focusing on action verbs and essential terms.
* **Flexible input**: Accepts task descriptions directly as a command-line argument or from a text file.
* **BAML integration**: Utilizes BAML for defining LLM interactions, data structures, and tests.
* **Modern Python tooling**: Uses `uv` for fast dependency management and `just` for task running.
* **CLI interface**: Easy to use and integrate into scripts or development workflows.

## How it works

1. You provide a task description (e.g., "Implement user login with two-factor authentication").
2. Taskgist uses a BAML function (`ExtractKeywords` defined in `src/taskgist/baml_src/keywords.baml`) to send this description to the configured LLM (currently Google Gemini FlashLite, as defined in `src/taskgist/baml_src/clients.baml`).
3. The BAML function instructs the LLM to extract an action verb and a concise keyword phrase, omitting common articles, prepositions, and pronouns.
4. The LLM returns a structured `KeywordPhrase` object (defined in BAML).
5. Taskgist processes this object to create a hyphenated string (e.g., `implement-user-login-two-factor-authentication`).
6. The tool is designed to output *only* the final generated gist to standard output, making it suitable for piping to other commands. All diagnostic messages, logs, or errors are directed to standard error.

## Prerequisites

### For users

* **Python 3.12 or higher.**
* **A Google AI API key for Gemini models.** You will need to set the `GEMINI_API_KEY` environment variable (see [Configuration](#configuration) below).
* **pip** (or **uv pip**) for installing the package.

### For developers (in addition to user prerequisites)

* [uv](https://github.com/astral-sh/uv): For project and environment management. Follow the installation instructions on their site.
* [just](https://github.com/casey/just): A command runner.

## Installation

### For users (Recommended)

The easiest way to install `taskgist` is using the pre-compiled wheel file from the latest GitHub release:

1. **Download the `.whl` file:**
    Go to the [latest release page](https://github.com/ngirard/taskgist/releases/latest).
    Download the `.whl` file (e.g., `taskgist-X.Y.Z-py3-none-any.whl`) from the "Assets" section.

2. **Install using pip:**
    Open your terminal and navigate to the directory where you downloaded the file. Then, install it using `pip` (or `uv pip` if you have `uv` installed and prefer to use it):
    ```bash
    pip install taskgist-X.Y.Z-py3-none-any.whl
    ```
    (Replace `taskgist-X.Y.Z-py3-none-any.whl` with the actual filename you downloaded).

    This will install `taskgist` and its dependencies into your Python environment.

3. **Configure API Key:**
    Proceed to the [Configuration](#configuration) section to set up your `GEMINI_API_KEY`.

### For developers

If you want to contribute to `taskgist` or modify the source code:

1. **Clone the repository:**
    ```bash
    git clone https://github.com/ngirard/taskgist.git
    cd taskgist
    ```

2. **Set up the environment and install dependencies:**
    `uv` will create a virtual environment (typically `.venv`) and install all dependencies specified in `pyproject.toml`, including `taskgist` in editable mode.
    ```bash
    just sync
    ```
    Alternatively, you can run the `uv` commands directly:
    ```bash
    uv venv  # Create virtual environment
    uv sync  # Sync dependencies
    ```

3. **Generate the BAML client:**
    BAML functions are compiled into a Python client. Generate it by running:
    ```bash
    just baml-generate
    ```
    This command is also part of the default `just` task.

## Configuration

Taskgist requires a Google AI API key to interact with the Gemini LLM.

1. Obtain an API key from [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Set the `GEMINI_API_KEY` environment variable. The recommended way is to create a `.env` file in the project root:

    ```env
    # .env
    GEMINI_API_KEY="YOUR_GEMINI_API_KEY_HERE"
    ```
    Taskgist will automatically load variables from this `.env` file at runtime.

## Usage

Once installed and configured, you can use the `taskgist` CLI. Ensure your virtual environment is activated if you're not using `just run` or `uv run`.

**Basic usage with a string input:**
```bash
taskgist "Create a new user authentication system with email verification and password reset capabilities"
```
Example output:
```
create-user-authentication-email-verification
```

**Using a file input:**
Create a file, for example, `my_task.txt`, with your task description:
```
Implement a feature to allow users to upload profile pictures.
The system should support JPG and PNG formats and resize images to a maximum of 500x500 pixels.
```
Then run `taskgist` pointing to the file, prefixed with `@:`:
```bash
taskgist "@:my_task.txt"
```
Example output:
```
implement-user-upload-profile-pictures
```

**Running via `just`:**
The `justfile` provides a convenient way to run the tool with arguments:
```bash
just run "Refactor the database schema for better performance"
just run "@:path/to/your/task_description.txt"
```

## Development

This project uses `just` as a command runner and `uv` for Python packaging and virtual environment management.

**Setting up the development environment:**
Ensure `uv` and `just` are installed. Then, clone the repository and run:
```bash
just # This runs sync, baml-generate, and lint
```

**Common development commands (see `justfile` for details):**

* `just`: Default task. Runs `sync`, `baml-generate`, and `lint`.
* `just sync`: Creates a virtual environment (if needed) and installs/updates dependencies using `uv sync`.
* `just baml-generate`: Generates the BAML Python client code. This is necessary after any changes to files in `src/taskgist/baml_src/`. The generated client is placed in `src/taskgist/baml_client/`.
* `just baml-test`: Runs tests defined within the BAML files (e.g., in `keywords.baml`). This uses `baml-cli test`.
* `just lint`: Lints the Python code using Ruff.
* `just format`: Formats the Python code using Ruff.
* `just build`: Builds the Python package (sdist and wheel) into the `dist/` directory.
* `just run "<task_description>"`: A wrapper to execute the `taskgist` CLI tool with the provided task description.
* `just clean`: Removes build artifacts, Python caches, and the generated BAML client directory.
* `just install-editable`: Installs the package in editable mode using `uv pip install -e .` (usually handled by `uv sync`).

## Project structure

```
.
├── src
│   └── taskgist
│       ├── baml_src/         # BAML definitions
│       │   ├── clients.baml    # LLM client configurations (e.g., Gemini)
│       │   ├── generators.baml # BAML client generator configuration
│       │   └── keywords.baml   # BAML functions, classes, and tests for keyword extraction
│       ├── baml_client/      # Generated BAML Python client (auto-generated, do not edit directly)
│       ├── __init__.py       # Package initializer (contains __version__)
│       └── main.py           # CLI entrypoint and core Python logic
├── justfile                  # Command runner recipes using 'just'
├── pyproject.toml            # Project metadata, dependencies, and build configuration (PEP 621)
└── README.md                 # This file
```

### BAML components

The core LLM interaction logic is defined in the `src/taskgist/baml_src/` directory:

* **`clients.baml`**: Defines the LLM client(s). Currently configured for `FlashLite` (a Google Gemini model) and specifies how to authenticate (using `GEMINI_API_KEY` from environment variables).
* **`generators.baml`**: Configures how the BAML Python client code is generated by `baml-cli generate`. It specifies the output directory (`../`, relative to `baml_src/`, meaning `src/taskgist/baml_client/`) and the BAML version.
* **`keywords.baml`**:
    * `class KeywordPhrase`: Defines the expected structured output from the LLM (an `actionVerb` and a list of `phrase` strings).
    * `function ExtractKeywords`: The main BAML function. It takes a `taskDescription` string, includes a detailed prompt for the LLM, and specifies `KeywordPhrase` as its return type.
    * `test ...`: Inline test cases for the `ExtractKeywords` function. These can be executed using `just baml-test`.

## License

This project is licensed under the MIT License. See the `pyproject.toml` file for license information.

## Contributing

Contributions are welcome! If you have suggestions for improvements, new features, or find any bugs, please feel free to:

1. Open an issue to discuss the change.
2. Fork the repository, make your changes, and submit a pull request.

Please ensure your code adheres to the project's linting and formatting standards (run `just lint` and `just format`).
