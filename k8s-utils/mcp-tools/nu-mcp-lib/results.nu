# MCP Results Module

# Create tools/call result
export def result [
  content: list<record>
  --error = false
] {
  {
    content: $content
    isError: $error
  }
}