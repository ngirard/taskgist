import unittest
from taskgist.main import create_gist
from taskgist.baml_client.types import KeywordPhrase


class TestCreateGist(unittest.TestCase):
    def test_multi_word_elements(self):
        kp = KeywordPhrase(
            actionVerb="Create",
            phrase=[
                "user authentication",
                "email verification",
                "password reset",
            ],
        )
        self.assertEqual(
            create_gist(kp),
            "create-user-authentication-email-verification-password-reset",
        )

    def test_spaces_and_nbsps(self):
        kp = KeywordPhrase(
            actionVerb=" Create ", phrase=[" user\u00a0authentication  "]
        )
        self.assertEqual(create_gist(kp), "create-user-authentication")

    def test_duplicates(self):
        kp = KeywordPhrase(
            actionVerb="Create", phrase=["create", "user", "user", "authentication"]
        )
        self.assertEqual(create_gist(kp), "create-user-authentication")


if __name__ == "__main__":
    unittest.main()
