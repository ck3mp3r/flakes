#!/usr/bin/env nu

# Kubernetes resource retrieval tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "get_resource"
      description: "Get Kubernetes resources with filtering and formatting options"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type (e.g., pods, deployments, services, nodes)"
          }
          name: {
            type: "string"
            description: "Resource name (optional - lists all if not specified)"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional - uses current context if not specified)"
          }
          all_namespaces: {
            type: "boolean"
            description: "List resources across all namespaces"
            default: false
          }
          output_format: {
            type: "string"
            description: "Output format (json, yaml, wide, name)"
            default: "wide"
          }
          label_selector: {
            type: "string"
            description: "Label selector to filter resources (e.g., 'app=nginx')"
          }
          field_selector: {
            type: "string"
            description: "Field selector to filter resources (e.g., 'status.phase=Running')"
          }
        }
        required: ["resource_type"]
      }
    }
    {
      name: "list_resource_types"
      description: "List all available resource types in the cluster"
      input_schema: {
        type: "object"
        properties: {
          namespaced: {
            type: "boolean"
            description: "Filter to only namespaced resources"
          }
        }
      }
    }
    {
      name: "get_resource_summary"
      description: "Get a summary of resources across namespaces"
      input_schema: {
        type: "object"
        properties: {
          resource_types: {
            type: "array"
            items: { type: "string" }
            description: "List of resource types to summarize (e.g., ['pods', 'deployments'])"
          }
        }
      }
    }
  ] | to json
}

# Call a specific tool with arguments
def "main call-tool" [
  tool_name: string # Name of the tool to call
  args: string = "{}" # JSON arguments for the tool
] {
  let parsed_args = $args | from json

  match $tool_name {
    "get_resource" => {
      let resource_type = $parsed_args | get resource_type
      let name = if "name" in $parsed_args { $parsed_args | get name } else { null }
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let all_namespaces = if "all_namespaces" in $parsed_args { $parsed_args | get all_namespaces } else { false }
      let output_format = if "output_format" in $parsed_args { $parsed_args | get output_format } else { "wide" }
      let label_selector = if "label_selector" in $parsed_args { $parsed_args | get label_selector } else { null }
      let field_selector = if "field_selector" in $parsed_args { $parsed_args | get field_selector } else { null }
      
      get_resource $resource_type $name $namespace $all_namespaces $output_format $label_selector $field_selector
    }
    "list_resource_types" => {
      let namespaced = if "namespaced" in $parsed_args { $parsed_args | get namespaced } else { null }
      list_resource_types $namespaced
    }
    "get_resource_summary" => {
      let resource_types = if "resource_types" in $parsed_args { $parsed_args | get resource_types } else { ["pods", "deployments", "services"] }
      get_resource_summary $resource_types
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Get Kubernetes resources with various filtering options
def get_resource [
  resource_type: string
  name?: string
  namespace?: string
  all_namespaces: bool = false
  output_format: string = "wide"
  label_selector?: string
  field_selector?: string
] {
  try {
    mut cmd = ["kubectl", "get", $resource_type]
    
    # Add resource name if specified
    if $name != null {
      $cmd = ($cmd | append $name)
    }
    
    # Add namespace options
    if $all_namespaces {
      $cmd = ($cmd | append "--all-namespaces")
    } else if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    # Add output format
    $cmd = ($cmd | append "--output" | append $output_format)
    
    # Add selectors
    if $label_selector != null {
      $cmd = ($cmd | append "--selector" | append $label_selector)
    }
    
    if $field_selector != null {
      $cmd = ($cmd | append "--field-selector" | append $field_selector)
    }
    
    # Execute the command
    let result = run-external $cmd.0 ...$cmd.1..
    
    if $output_format in ["json", "yaml"] {
      $result
    } else {
      $"Kubernetes Resources - ($resource_type):
($result)

Command executed: ($cmd | str join ' ')"
    }
  } catch { |e|
    $"Error retrieving ($resource_type): ($e.msg)
Please check:
- Resource type is correct (use 'list_resource_types' to see available types)
- You have access to the cluster
- Namespace exists (if specified)
- Selectors are valid"
  }
}

# List all available resource types
def list_resource_types [namespaced?: bool] {
  try {
    mut cmd = ["kubectl", "api-resources"]
    
    if $namespaced != null {
      if $namespaced {
        $cmd = ($cmd | append "--namespaced=true")
      } else {
        $cmd = ($cmd | append "--namespaced=false")
      }
    }
    
    let result = run-external $cmd.0 ...$cmd.1..
    
    $"Available Kubernetes Resource Types:
($result)

Use these resource types with the 'get_resource' tool.
Common examples: pods, deployments, services, configmaps, secrets, nodes"
  } catch { |e|
    $"Error listing resource types: ($e.msg)"
  }
}

# Get a summary of resources across the cluster
def get_resource_summary [resource_types: list<string>] {
  try {
    mut summary_lines = ["Resource Summary:"]
    
    for resource_type in $resource_types {
      try {
        let count_result = run-external "kubectl" "get" $resource_type "--all-namespaces" "--no-headers" | lines | length
        $summary_lines = ($summary_lines | append $"  ($resource_type): ($count_result) total")
        
        # Get namespace breakdown for namespaced resources
        try {
          let ns_breakdown = run-external "kubectl" "get" $resource_type "--all-namespaces" "--no-headers" 
            | lines 
            | each { |line| $line | split row ' ' | get 0 } 
            | group-by 
            | transpose key value 
            | each { |row| $"    ($row.key): ($row.value | length)" }
            | str join (char newline)
          
          if ($ns_breakdown | str length) > 0 {
            $summary_lines = ($summary_lines | append $"($ns_breakdown)")
          }
        } catch {
          # Resource might not be namespaced, continue
        }
      } catch {
        $summary_lines = ($summary_lines | append $"  ($resource_type): Unable to retrieve")
      }
    }
    
    $summary_lines | str join (char newline)
  } catch { |e|
    $"Error generating resource summary: ($e.msg)"
  }
}