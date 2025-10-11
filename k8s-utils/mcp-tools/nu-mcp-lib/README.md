# Nu-MCP Library

Generic Model Context Protocol helpers for Nushell stdio servers.

## Usage

```nushell
use nu-mcp-lib *

# Create tool definition for tools/list
let my_tool = (tool "weather" "Get weather info" (object_schema {
  location: (string_prop "City name")
} ["location"]) --title "Weather Tool")

# Create tools/call result  
let success = (result [(text "Temperature: 72°F")])
let error = (result [(text "City not found")] --error=true)
```

## Functions

### Tool Definition
- `tool name description input_schema [--title]` - Create tool for tools/list

### Result Creation  
- `result content [--error]` - Create tools/call response
- `text string` - Text content item
- `image data mime_type` - Image content item  
- `resource uri mime_type [--text]` - Resource content item

### JSON Schema
- `object_schema properties required` - Object schema
- `string_prop description [--enum] [--default]` - String property
- `boolean_prop description [--default]` - Boolean property
- `object_prop description` - Object property

## Example Tool

```nushell
use nu-mcp-lib *

def "main list-tools" [] {
  [
    (tool "hello" "Say hello" (object_schema {
      name: (string_prop "Person's name")  
    } ["name"]) --title "Hello Tool")
  ] | to json
}

def "main call-tool" [tool_name: string, args: any = {}] {
  let parsed = ($args | from json)
  
  match $tool_name {
    "hello" => {
      result [(text $"Hello, ($parsed.name)!")] | to json
    }
    _ => {
      result [(text $"Unknown tool: ($tool_name)")] --error=true | to json  
    }
  }
}
```