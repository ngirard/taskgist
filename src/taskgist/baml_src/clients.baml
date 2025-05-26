client<llm> FlashLite {
  provider google-ai
  options {
    model "gemini-2.0-flash-lite"
    api_key env.GEMINI_API_KEY
    generationConfig {
      temperature 0.0
    }
  }
}
