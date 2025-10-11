# MCP Tool Definition Module

# Create tool definition for tools/list response
export def tool [
  name: string
  description: string  
  input_schema: record
  --title: string
] {
  mut def = {
    name: $name
    description: $description
    inputSchema: $input_schema
  }
  
  if $title != null {
    $def.title = $title
  }
  
  $def
}