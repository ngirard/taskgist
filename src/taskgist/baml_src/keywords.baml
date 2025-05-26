class KeywordPhrase {
  actionVerb string @description("The leading verb that describes the main action")
  phrase string[] @description("Complete keyword phrase with essential terms only")
}

function ExtractKeywords(taskDescription: string) -> KeywordPhrase {
  client FlashLite
  prompt #"
    Extract a concise keyword phrase from the given software engineering task description.
    Guidelines:
    - Return at most five keywords.
    - The first keyword must be a single-word action verb summarizing the task.
    - Each keyword must be a single word with no spaces.
    - Omit articles (the, a, an), common prepositions (in, on, to, for), and pronouns (it, this, that, etc.).
    - Keep only essential terms representing the core task.

    {{ ctx.output_format }}

    {{ _.role("user") }} {{ taskDescription }}
  "#
}

test BasicTaskTest {
  functions [ExtractKeywords]
  args {
    taskDescription "Create a new user authentication system with email verification and password reset capabilities"
  }
}

test EmptyTaskTest {
  functions [ExtractKeywords]
  args {
    taskDescription "No task provided"
  }
}
