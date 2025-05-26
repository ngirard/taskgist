# scripts/bump_version.py
import re
import sys
import argparse
from pathlib import Path

# Correctly determine project root assuming script is in project_root/scripts/
PROJECT_ROOT = Path(__file__).parent.parent.resolve()
VERSION_FILE = PROJECT_ROOT / "src/taskgist/__init__.py"

VERSION_REGEX_INIT = re.compile(r"(__version__\s*=\s*['\"])(\d+\.\d+\.\d+)(['\"])")

def get_current_version_from_file(filepath, regex):
    if not filepath.exists():
        raise FileNotFoundError(f"Version file not found: {filepath}")
    content = filepath.read_text()
    match = regex.search(content)
    if not match:
        raise RuntimeError(f"Could not find version pattern in {filepath}")
    return match.group(2) # Group 2 is the X.Y.Z part

def set_version_in_file(filepath, regex, new_version_str):
    if not filepath.exists():
        raise FileNotFoundError(f"File not found: {filepath}")
    content = filepath.read_text()
    
    current_version_match = regex.search(content)
    if not current_version_match:
        raise RuntimeError(f"Could not find version pattern in {filepath} to replace.")

    if current_version_match.group(2) == new_version_str:
        print(f"Version in {filepath} is already {new_version_str}. No change made to file.", file=sys.stderr)
        return False # No change

    # Replace only the version part, keeping original quotes and spacing
    new_content = regex.sub(rf"\g<1>{new_version_str}\g<3>", content, count=1)
    
    if content == new_content: # Should not happen if previous check passed and new_version is different
        raise RuntimeError(f"Failed to update version in {filepath}. Content might be malformed or regex issue.")
        
    filepath.write_text(new_content)
    print(f"Updated version in {filepath} to {new_version_str}", file=sys.stderr)
    return True # Change made

def increment_version_part(current_version, part="patch"):
    major, minor, patch = map(int, current_version.split('.'))
    if part == "major": major += 1; minor = 0; patch = 0
    elif part == "minor": minor += 1; patch = 0
    elif part == "patch": patch += 1
    else: raise ValueError("Invalid version part. Choose 'major', 'minor', or 'patch'.")
    return f"{major}.{minor}.{patch}"

def main():
    parser = argparse.ArgumentParser(description="Manage project version in src/taskgist/__init__.py.")
    subparsers = parser.add_subparsers(dest="action", required=True, help="Action to perform")

    # Action: current
    parser_current = subparsers.add_parser("current", help="Print current version to stdout.")
    
    # Action: bump
    parser_bump = subparsers.add_parser("bump", help="Bump version part (major, minor, patch) and print new version to stdout.")
    parser_bump.add_argument("part", choices=["major", "minor", "patch"], default="patch", nargs="?", help="Part to bump (default: patch).")

    # Action: set
    parser_set = subparsers.add_parser("set", help="Set a specific version and print it to stdout.")
    parser_set.add_argument("version", help="Version to set (e.g., '1.2.3').")

    args = parser.parse_args()

    current_v = get_current_version_from_file(VERSION_FILE, VERSION_REGEX_INIT)

    if args.action == "current":
        print(current_v) # Output to stdout
        return

    new_v = None
    if args.action == "bump":
        new_v = increment_version_part(current_v, args.part)
        print(f"Current version: {current_v}. Bumping '{args.part}' to: {new_v}", file=sys.stderr)
    elif args.action == "set":
        if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
            parser.error(f"Invalid version format: '{args.version}'. Must be X.Y.Z.")
        new_v = args.version
        print(f"Current version: {current_v}. Setting to: {new_v}", file=sys.stderr)

    if new_v:
        if new_v != current_v:
            set_version_in_file(VERSION_FILE, VERSION_REGEX_INIT, new_v)
        else:
            # If setting to the same version, still print it to stdout as confirmation
            print(f"Version is already {new_v}. No file update needed.", file=sys.stderr)
        print(new_v) # Print the new/target version to stdout as the last output
    else:
        # This case should ideally be caught by argparse or earlier logic
        print("Error: New version was not determined.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
