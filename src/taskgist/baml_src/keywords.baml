class KeywordPhrase {
  actionVerb string @description("The leading verb that describes the main action")
  phrase string[] @description("Complete keyword phrase with essential terms only")
}

function ExtractKeywords(taskDescription: string) -> KeywordPhrase {
  client FlashLite
  prompt #"
    Extract a concise keyword phrase from the given software engineering task description.
    The phrase must:
    - Start with an action verb
    - Consist of only only essential keywords
    - Omit articles (the, a, an), common prepositions (in, on, to, for), and pronouns (it, this, that, etc.).
    - Be representative of the core task.
    - Not exceed 5 words
    - Each returned word must be a single token with no spaces

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
