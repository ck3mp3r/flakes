# MCP JSON Schema Module

# JSON Schema helpers
export def string_prop [
  description: string
  --enum: list<string>
  --default: string
] {
  mut prop = {
    type: "string"
    description: $description
  }
  
  if $enum != null { $prop.enum = $enum }
  if $default != null { $prop.default = $default }
  
  $prop
}

export def boolean_prop [
  description: string
  --default = false
] {
  {
    type: "boolean"
    description: $description
    default: $default
  }
}

export def object_prop [
  description: string
] {
  {
    type: "object"
    description: $description
  }
}

export def object_schema [
  properties: record
  required: list<string> = []
] {
  {
    type: "object"
    properties: $properties
    required: $required
  }
}