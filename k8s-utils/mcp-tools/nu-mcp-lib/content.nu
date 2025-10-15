# MCP Content Item Module

# Create text content item
export def text [text: string] {
  {
    type: "text"
    text: $text
  }
}

# Create image content item  
export def image [
  data: string
  mime_type: string
] {
  {
    type: "image"
    data: $data
    mimeType: $mime_type
  }
}

# Create resource content item
export def resource [
  uri: string
  mime_type: string
  --text: string
] {
  mut res = {
    type: "resource"
    resource: {
      uri: $uri
      mimeType: $mime_type
    }
  }
  
  if $text != null {
    $res.resource.text = $text
  }
  
  $res
}