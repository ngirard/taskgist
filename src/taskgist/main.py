import argparse
import os
import asyncio
from pathlib import Path
import sys
from dotenv import load_dotenv
from contextlib import contextmanager

# Imports from generated BAML client and BAML library
# These imports assume 'baml_client' is a subdirectory within the 'taskgist' package
from baml_py.errors import BamlError
from .baml_client.async_client import b as ab  # Using async client
from .baml_client.types import KeywordPhrase
from .baml_client.config import set_log_level
from . import __version__

# Load environment variables from .env file at the earliest opportunity
load_dotenv()


@contextmanager
def redirect_stdout_fd_to_stderr_fd():
    """Temporarily redirects file descriptor 1 (stdout) to file descriptor 2 (stderr)."""
    sys.stdout.flush()  # Flush Python's stdout buffer before FD redirection

    original_stdout_fd = sys.stdout.fileno()  # Usually 1
    # Save a copy of the original stdout file descriptor.
    # os.dup() creates a new file descriptor that refers to the same open file description.
    saved_stdout_fd = os.dup(original_stdout_fd)

    # Redirect stdout's FD (1) to stderr's FD (2).
    # After this, any write to FD 1 will go to where FD 2 (stderr) points.
    os.dup2(sys.stderr.fileno(), original_stdout_fd)

    try:
        yield
    finally:
        # Flush any buffered data in Python's sys.stdout.
        # Even though FD 1 was redirected, Python's sys.stdout object might have its own buffer.
        # This data will go to stderr's destination because FD 1 currently points there.
        sys.stdout.flush()

        # Restore the original stdout file descriptor.
        # FD 1 will now point back to its original destination.
        os.dup2(saved_stdout_fd, original_stdout_fd)
        # Close the saved copy of the original stdout file descriptor.
        os.close(saved_stdout_fd)


def get_task_description(task_input: str) -> str:
    """Reads task description from string or file path."""
    if task_input.startswith("@:"):
        file_path_str = task_input[2:]
        file_path = Path(
            file_path_str
        ).resolve()  # Resolve to absolute path for clarity in errors
        if not file_path.is_file():
            raise FileNotFoundError(f"File not found: {file_path}")
        return file_path.read_text().strip()
    return task_input.strip()


async def run_extraction(task_description: str) -> KeywordPhrase | None:
    """Runs the BAML keyword extraction function."""
    if not task_description:
        print("Error: Task description is empty.")
        return None

    if not os.getenv("GEMINI_API_KEY"):
        print("Error: GEMINI_API_KEY environment variable not set.")
        print(
            'Please set it in your environment or in a .env file (e.g., GEMINI_API_KEY="sk-...").'
        )
        return None

    try:
        result = await ab.ExtractKeywords(taskDescription=task_description)
        return result
    except BamlError as e:
        print(f"BAML Error: {e}")
        if hasattr(
            e, "message"
        ):  # BamlValidationError has 'message', 'prompt', 'raw_output'
            print(f"  Message: {getattr(e, 'message')}")
        if hasattr(e, "prompt"):
            print(f"  Prompt: {getattr(e, 'prompt')}")
        if hasattr(e, "raw_output"):
            print(f"  Raw LLM Output: {getattr(e, 'raw_output')}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred during BAML extraction: {e}")
        return None


def create_gist(keyword_phrase_obj: KeywordPhrase) -> str:
    """Creates a hyphenated gist from the KeywordPhrase object."""
    action_verb = keyword_phrase_obj.actionVerb.strip().lower()
    phrase_elements = [elem.strip().lower() for elem in keyword_phrase_obj.phrase]

    final_gist_parts = []
    if action_verb:  # Only add if action_verb is not empty
        final_gist_parts.extend(action_verb.split())

    if phrase_elements:
        # Verification: if the first phrase element is the same as action_verb,
        # it means the model might have just repeated it from the explicit field.
        # The instruction is to ignore the first element of phrase in this case.
        if phrase_elements[0] == action_verb:
            relevant_phrase_elements = phrase_elements[1:]
        else:
            relevant_phrase_elements = phrase_elements

        for elem in relevant_phrase_elements:
            final_gist_parts.extend(elem.split())

    # Remove duplicates while preserving order and filter out empty strings
    seen = set()
    unique_final_gist_parts = [
        x for x in final_gist_parts if x and not (x in seen or seen.add(x))
    ]

    return "-".join(unique_final_gist_parts)


def main_cli():
    """Command-line interface for taskgist."""
    parser = argparse.ArgumentParser(
        description="Generates a concise gist from a software engineering task description using BAML.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    parser.add_argument(
        "task",
        type=str,
        help="The task description string, or a file path prefixed with '@:' (e.g., '@:path/to/task.txt').\n"
        'Example: taskgist "Create a new user authentication system"\n'
        'Example: taskgist "@:./mytask.txt"',
    )

    args = parser.parse_args()

    try:
        task_description_content = get_task_description(args.task)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)  # Explicitly to stderr
        return
    except Exception as e:
        print(
            f"Error processing task input: {e}", file=sys.stderr
        )  # Explicitly to stderr
        return

    if not task_description_content:
        print(
            "Error: No task description provided or file is empty.", file=sys.stderr
        )  # Explicitly to stderr
        return

    keyword_phrase_result = None
    # Apply the redirection context manager around the BAML call
    with redirect_stdout_fd_to_stderr_fd():
        set_log_level("ERROR")
        keyword_phrase_result = asyncio.run(run_extraction(task_description_content))

    if keyword_phrase_result:
        if not keyword_phrase_result.actionVerb and not keyword_phrase_result.phrase:
            print(
                "Warning: LLM returned empty actionVerb and phrase. Cannot generate gist.",
                file=sys.stderr,
            )  # Explicitly to stderr
        else:
            gist = create_gist(keyword_phrase_result)
            if gist:
                print(gist)  # This is the main output, goes to original stdout
            else:
                # This case might indicate an issue with create_gist or empty but valid LLM response
                print(
                    "Warning: Generated gist is empty after processing. Check LLM output and input task.",
                    file=sys.stderr,
                )  # Explicitly to stderr
    # If keyword_phrase_result is None, run_extraction already printed an error (which was redirected to stderr)


if __name__ == "__main__":
    # This allows the script to be run directly (e.g., python src/taskgist/main.py ...),
    # primarily for development/testing. The installed CLI 'taskgist' uses main_cli().
    main_cli()
