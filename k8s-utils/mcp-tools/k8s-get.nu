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
            items: {type: "string"}
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
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name?
      let namespace = $parsed_args.namespace?
      let all_namespaces = $parsed_args.all_namespaces? | default false
      let output_format = $parsed_args.output_format? | default "wide"
      let label_selector = $parsed_args.label_selector?
      let field_selector = $parsed_args.field_selector?

      get_resource $resource_type $name $namespace $all_namespaces $output_format $label_selector $field_selector
    }
    "list_resource_types" => {
      let namespaced = $parsed_args.namespaced?
      list_resource_types $namespaced
    }
    "get_resource_summary" => {
      let resource_types = $parsed_args.resource_types? | default ["pods" "deployments" "services"]
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
    mut cmd_args = ["get" $resource_type]

    # Add resource name if specified
    if $name != null {
      $cmd_args = ($cmd_args | append $name)
    }

    # Add namespace options
    if $all_namespaces {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    } else if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    # Add output format
    $cmd_args = ($cmd_args | append "--output" | append $output_format)

    # Add selectors
    if $label_selector != null {
      $cmd_args = ($cmd_args | append "--selector" | append $label_selector)
    }

    if $field_selector != null {
      $cmd_args = ($cmd_args | append "--field-selector" | append $field_selector)
    }

    # Build and execute the command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    if $output_format in ["json" "yaml"] {
      $result
    } else {
      {
        type: "kubectl_output"
        resource_type: $resource_type
        command: ($full_cmd | str join " ")
        output: $result
      } | to json
    }
  } catch {|error|
    {
      type: "error"
      message: $"Error retrieving ($resource_type): ($error.msg)"
      suggestions: [
        "Check if resource type is correct"
        "Verify cluster access"
        "Ensure namespace exists"
        "Validate selectors"
      ]
    } | to json
  }
}

# List all available resource types
def list_resource_types [namespaced?: bool] {
  try {
    mut cmd_args = ["api-resources"]

    if $namespaced != null {
      if $namespaced {
        $cmd_args = ($cmd_args | append "--namespaced=true")
      } else {
        $cmd_args = ($cmd_args | append "--namespaced=false")
      }
    }

    # Build and execute the command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "api_resources"
      filter: (
        if $namespaced != null {
          if $namespaced { "namespaced" } else { "cluster-scoped" }
        } else { "all" }
      )
      command: ($full_cmd | str join " ")
      output: $result
      note: "Use these resource types with the get_resource tool"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error listing resource types: ($error.msg)"
    } | to json
  }
}

# Get a summary of resources across the cluster
def get_resource_summary [resource_types: list<string>] {
  let summary_data = $resource_types | each {|resource_type|
    let count_result = try {
      let full_cmd = ["kubectl" "get" $resource_type "--all-namespaces" "--no-headers"]
      print $"Executing: ($full_cmd | str join ' ')"
      run-external ...$full_cmd
      | lines
      | length
    } catch {
      null
    }

    let namespace_breakdown = try {
      let full_cmd = ["kubectl" "get" $resource_type "--all-namespaces" "--no-headers"]
      print $"Executing: ($full_cmd | str join ' ')"
      run-external ...$full_cmd
      | lines
      | each {|line|
        let parts = $line | split row ' '
        if ($parts | length) > 0 { $parts.0 } else { null }
      }
      | where $it != null
      | group-by
      | transpose namespace count
      | each {|row| {namespace: $row.namespace count: ($row.count | length)} }
    } catch {
      []
    }

    {
      resource_type: $resource_type
      total_count: ($count_result | default 0)
      namespace_breakdown: $namespace_breakdown
      status: (if $count_result != null { "success" } else { "error" })
    }
  }

  {
    type: "resource_summary"
    summary: $summary_data
    total_types_queried: ($resource_types | length)
    successful_queries: ($summary_data | where status == "success" | length)
  } | to json
}
