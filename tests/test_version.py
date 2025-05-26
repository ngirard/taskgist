import subprocess
import unittest

import taskgist


class TestVersionCLI(unittest.TestCase):
    def test_cli_version(self):
        result = subprocess.run(
            ["taskgist", "--version"],
            capture_output=True,
            text=True,
        )
        self.assertTrue(result.stdout.strip().endswith(taskgist.__version__))
        self.assertEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
