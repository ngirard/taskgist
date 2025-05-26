// To use this configuration, run `baml-cli generate`
// For more information, see https://docs.boundaryml.com/v2/baml-overview/concepts/client-generators

generator python_client {
  output_type "python/pydantic"
  // Where the generated code will be saved (relative to baml_src/)
  output_dir "../"
  version "0.89.0" // Should match the baml-py version in pyproject.toml
  // default_client_mode "async" // You can specify sync or async default
}
