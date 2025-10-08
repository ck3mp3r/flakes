# Kubernetes resource retrieval tool for nu-mcp

use nu-mcp-lib *

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    (tool "get_resource" "Get Kubernetes resources with filtering and formatting options" 
      (object_schema {
        resource_type: (string_prop "Resource type (e.g., pods, deployments, services, nodes)")
        name: (string_prop "Resource name (optional - lists all if not specified)")
        namespace: (string_prop "Namespace (optional - uses current context if not specified)")
        all_namespaces: (boolean_prop "List resources across all namespaces")
        output_format: (string_prop "Output format" --enum ["json", "yaml", "wide", "name"] --default "wide")
        label_selector: (string_prop "Label selector to filter resources (e.g., 'app=nginx')")
        field_selector: (string_prop "Field selector to filter resources (e.g., 'status.phase=Running')")
        delegate_to: (string_prop "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')")
      } ["resource_type"]) --title "Get Kubernetes Resources")
    
    (tool "list_resource_types" "List all available resource types in the cluster"
      (object_schema {
        namespaced: (boolean_prop "Filter to only namespaced resources")
      } []) --title "List Resource Types")
      
    (tool "get_resource_summary" "Get a summary of resources across namespaces"
      (object_schema {
        resource_types: {
          type: "array"
          items: {type: "string"}
          description: "List of resource types to summarize (e.g., ['pods', 'deployments'])"
        }
      } []) --title "Get Resource Summary")
  ] | to json
}

# Call a specific tool with arguments
def "main call-tool" [
  tool_name: string # Name of the tool to call
  args: any = {} # Arguments as nushell record or JSON string
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
      let delegate_to = $parsed_args.delegate_to?

      get_resource $resource_type $name $namespace $all_namespaces $output_format $label_selector $field_selector $delegate_to
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
      result [(text $"Unknown tool: ($tool_name)")] --error=true | to json
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
  delegate_to?: string
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
      $cmd_args = ($cmd_args | append ["-n" $namespace])
    }

    # Add output format
    $cmd_args = ($cmd_args | append ["-o" $output_format])

    # Add selectors
    if $label_selector != null {
      $cmd_args = ($cmd_args | append ["-l" $label_selector])
    }

    if $field_selector != null {
      $cmd_args = ($cmd_args | append ["--field-selector" $field_selector])
    }

    # Build the command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = ($full_cmd | str join " ")
    
    if $delegate_to != null {
      # Return command for delegation (keeping existing functionality)
      {
        type: "kubectl_command_for_delegation"
        operation: "get_resource"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          resource_type: $resource_type
          name: $name
          namespace: $namespace
          all_namespaces: $all_namespaces
          output_format: $output_format
          label_selector: $label_selector
          field_selector: $field_selector
        }
      } | to json
    } else {
      # Execute the command
      let result = (run-external "kubectl" ...$cmd_args)
      
      result [
        (text $"Operation: get_resource")
        (text $"Command: ($cmd_string)")
        (text $"Result:\n($result)")
      ] | to json
    }
  } catch {|error|
    result [
      (text $"Error retrieving ($resource_type): ($error.msg)")
      (text "Suggestions:")
      (text "- Check if resource type is correct")
      (text "- Verify cluster access")
      (text "- Ensure namespace exists")
      (text "- Validate selectors")
    ] --error=true | to json
  }
}

# List available resource types
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

    let full_cmd = (["kubectl"] | append $cmd_args)
    let result = (run-external "kubectl" ...$cmd_args)
    
    result [
      (text $"Operation: list_resource_types")
      (text $"Command: ($full_cmd | str join ' ')")
      (text $"Result:\n($result)")
      (text "Note: Use these resource types with the get_resource tool")
    ] | to json
  } catch {|error|
    result [
      (text $"Error listing resource types: ($error.msg)")
    ] --error=true | to json
  }
}

# Get a summary of resources across the cluster
def get_resource_summary [resource_types: list<string>] {
  let summary_data = ($resource_types | each {|resource_type|
    try {
      let count_result = (run-external "kubectl" "get" $resource_type "--all-namespaces" "-o" "json" | from json | get items | length)
      let namespace_breakdown = (run-external "kubectl" "get" $resource_type "--all-namespaces" "-o" "json" | from json | get items | group-by metadata.namespace | transpose key count | each {|item| {namespace: $item.key, count: ($item.count | length)}})
      
      {
        resource_type: $resource_type
        total_count: ($count_result | default 0)
        namespace_breakdown: $namespace_breakdown
        status: (if $count_result != null { "success" } else { "error" })
      }
    } catch {
      {
        resource_type: $resource_type
        total_count: 0
        namespace_breakdown: []
        status: "error"
      }
    }
  })

  result [
    (text "Operation: get_resource_summary")
    (text $"Resource types: ($resource_types | str join ', ')")
    (text $"Summary:\n($summary_data | to yaml)")
  ] | to json
}