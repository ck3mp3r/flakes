# Kubernetes API resources and versions tool for nu-mcp

use nu-mcp-lib *

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "api_resources"
      title: "List API Resources"
      description: "List available API resources in the cluster"
      input_schema: {
        type: "object"
        properties: {
          api_group: {
            type: "string"
            description: "Filter by API group (e.g., 'apps', 'extensions', 'networking.k8s.io')"
          }
          namespaced: {
            type: "boolean"
            description: "Filter by namespace scope (true for namespaced, false for cluster-scoped)"
          }
          verbs: {
            type: "array"
            items: {type: "string"}
            description: "Filter resources that support specific verbs (e.g., ['get', 'list', 'create'])"
          }
          output: {
            type: "string"
            description: "Output format"
            enum: ["wide", "name", "json", "yaml"]
            default: "wide"
          }
          sort_by: {
            type: "string"
            description: "Sort resources by field"
            enum: ["name", "apigroup", "kind", "shortnames"]
            default: "name"
          }
          show_kind: {
            type: "boolean"
            description: "Show Kind column"
            default: true
          }
          show_shortnames: {
            type: "boolean"
            description: "Show shortnames column"
            default: true
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
      output_schema: {
        type: "object"
        properties: {
          type: {type: "string"}
          resources: {type: "array", items: {type: "object"}}
          command: {type: "string"}
        }
        required: ["type", "resources", "command"]
      }
    }
    {
      name: "api_versions"
      title: "List API Versions"
      description: "List available API versions in the cluster"
      input_schema: {
        type: "object"
        properties: {
          output: {
            type: "string"
            description: "Output format"
            enum: ["json", "yaml", "wide"]
            default: "wide"
          }
          group: {
            type: "string"
            description: "Filter by specific API group"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "explain_resource"
      title: "Explain Resource"
      description: "Get documentation for Kubernetes resource fields"
      input_schema: {
        type: "object"
        properties: {
          resource: {
            type: "string"
            description: "Resource name or field path (e.g., 'pods' or 'pods.spec.containers')"
          }
          api_version: {
            type: "string"
            description: "API version to use for explanation (e.g., 'apps/v1')"
          }
          recursive: {
            type: "boolean"
            description: "Show all nested fields recursively"
            default: false
          }
          output: {
            type: "string"
            description: "Output format"
            enum: ["plaintext", "plaintext-openapiv2"]
            default: "plaintext"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource"]
      }
    }
    {
      name: "api_resource_info"
      title: "API Resource Info"
      description: "Get detailed information about a specific API resource"
      input_schema: {
        type: "object"
        properties: {
          resource: {
            type: "string"
            description: "Resource name (e.g., 'pods', 'deployments', 'services')"
          }
          api_group: {
            type: "string"
            description: "API group if resource exists in multiple groups"
          }
          show_verbs: {
            type: "boolean"
            description: "Show supported verbs for the resource"
            default: true
          }
          show_categories: {
            type: "boolean"
            description: "Show resource categories"
            default: true
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource"]
      }
    }
    {
      name: "cluster_info"
      title: "Cluster Info"
      description: "Display cluster information and endpoints"
      input_schema: {
        type: "object"
        properties: {
          dump: {
            type: "boolean"
            description: "Dump detailed cluster state for debugging"
            default: false
          }
          output_directory: {
            type: "string"
            description: "Directory to save cluster dump (only used with dump=true)"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "server_version"
      title: "Server Version"
      description: "Get Kubernetes server version and build information"
      input_schema: {
        type: "object"
        properties: {
          output: {
            type: "string"
            description: "Output format"
            enum: ["json", "yaml", "short"]
            default: "json"
          }
          client: {
            type: "boolean"
            description: "Also show client version"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
  ] | to json
}

# Call a specific tool with arguments
def "main call-tool" [
  tool_name: string # Name of the tool to call
  args: any = {} # Arguments as nushell record or JSON string
] {
  let parsed_args = if ($args | describe) == "string" {
    $args | from json
  } else {
    $args
  }

  match $tool_name {
    "api_resources" => {
      let api_group = $parsed_args.api_group?
      let namespaced = $parsed_args.namespaced?
      let verbs = $parsed_args.verbs?
      let output = $parsed_args.output? | default "wide"
      let sort_by = $parsed_args.sort_by? | default "name"
      let show_kind = $parsed_args.show_kind? | default true
      let show_shortnames = $parsed_args.show_shortnames? | default true

      let delegate_to = $parsed_args.delegate_to?
      api_resources $api_group $namespaced $verbs $output $sort_by $show_kind $show_shortnames $delegate_to
    }
    "api_versions" => {
      let output = $parsed_args.output? | default "wide"
      let group = $parsed_args.group?

      let delegate_to = $parsed_args.delegate_to?
      api_versions $output $group $delegate_to
    }
    "explain_resource" => {
      let resource = $parsed_args.resource
      let api_version = $parsed_args.api_version?
      let recursive = $parsed_args.recursive? | default false
      let output = $parsed_args.output? | default "plaintext"

      let delegate_to = $parsed_args.delegate_to?
      explain_resource $resource $api_version $recursive $output $delegate_to
    }
    "api_resource_info" => {
      let resource = $parsed_args.resource
      let api_group = $parsed_args.api_group?
      let show_verbs = $parsed_args.show_verbs? | default true
      let show_categories = $parsed_args.show_categories? | default true

      api_resource_info $resource $api_group $show_verbs $show_categories
    }
    "cluster_info" => {
      let dump = $parsed_args.dump? | default false
      let output_directory = $parsed_args.output_directory?

      cluster_info $dump $output_directory
    }
    "server_version" => {
      let output = $parsed_args.output? | default "json"
      let client = $parsed_args.client? | default false

      server_version $output $client
    }
    _ => {
      result [(text $"Unknown tool: ($tool_name)")] --error=true | to json
    }
  }
}

# List API resources available in the cluster
def api_resources [
  api_group?: string
  namespaced?: any
  verbs?: any
  output: string = "wide"
  sort_by: string = "name"
  show_kind: bool = true
  show_shortnames: bool = true
  delegate_to?: string
] {
  try {
    mut cmd_args = ["api-resources"]

    if $api_group != null {
      $cmd_args = ($cmd_args | append "--api-group" | append $api_group)
    }

    if $namespaced != null {
      if $namespaced {
        $cmd_args = ($cmd_args | append "--namespaced=true")
      } else {
        $cmd_args = ($cmd_args | append "--namespaced=false")
      }
    }

    if $verbs != null {
      let verbs_str = $verbs | str join ","
      $cmd_args = ($cmd_args | append "--verbs" | append $verbs_str)
    }

    if $output != "wide" {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    } else {
      $cmd_args = ($cmd_args | append "--output" | append "wide")
    }

    $cmd_args = ($cmd_args | append "--sort-by" | append $sort_by)

    # Add display options
    if not $show_kind {
      $cmd_args = ($cmd_args | append "--no-headers")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "api_resources_result"
      operation: "api_resources"
      filters: {
        api_group: $api_group
        namespaced: $namespaced
        verbs: $verbs
        sort_by: $sort_by
      }
      display_options: {
        show_kind: $show_kind
        show_shortnames: $show_shortnames
        output_format: $output
      }
      command: ($full_cmd | str join " ")
      resources: $result
      message: "Available API resources in the cluster"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error listing API resources: ($error.msg)"
      suggestions: [
        "Verify cluster connectivity"
        "Check API group name if specified"
        "Ensure you have permission to list API resources"
        "Check verb names are valid if specified"
      ]
    } | to json
  }
}

# List API versions available in the cluster
def api_versions [
  output: string = "wide"
  group?: string
  delegate_to?: string
] {
  try {
    mut cmd_args = ["api-versions"]

    if $output != "wide" {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    # If group filter specified, we'll need to post-process
    let filtered_result = if $group != null {
      $result | str split "\n" | where {|line| $line =~ $group}
    } else {
      $result
    }

    {
      type: "api_versions_result"
      operation: "api_versions"
      filters: {
        group: $group
      }
      output_format: $output
      command: ($full_cmd | str join " ")
      api_versions: (if $group != null { $filtered_result } else { $result })
      note: (if $group != null { $"Filtered for group: ($group)" } else { "All available API versions" })
      message: "Available API versions in the cluster"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error listing API versions: ($error.msg)"
      suggestions: [
        "Verify cluster connectivity"
        "Ensure you have permission to list API versions"
        "Check that the cluster is running"
      ]
    } | to json
  }
}

# Explain resource fields and structure
def explain_resource [
  resource: string
  api_version?: string
  recursive: bool = false
  output: string = "plaintext"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["explain" $resource]

    if $api_version != null {
      $cmd_args = ($cmd_args | append "--api-version" | append $api_version)
    }

    if $recursive {
      $cmd_args = ($cmd_args | append "--recursive")
    }

    if $output != "plaintext" {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "explain_resource_result"
      operation: "explain_resource"
      resource: $resource
      options: {
        api_version: $api_version
        recursive: $recursive
        output: $output
      }
      command: ($full_cmd | str join " ")
      explanation: $result
      message: $"Resource documentation for '($resource)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error explaining resource '($resource)': ($error.msg)"
      suggestions: [
        "Verify the resource name is correct"
        "Check the API version if specified"
        "Ensure the resource exists in the cluster"
        "Try without recursive flag if it's too verbose"
      ]
    } | to json
  }
}

# Get detailed information about a specific API resource
def api_resource_info [
  resource: string
  api_group?: string
  show_verbs: bool = true
  show_categories: bool = true
] {
  try {
    # First get basic resource info
    mut cmd_args = ["api-resources" "--output" "json"]

    if $api_group != null {
      $cmd_args = ($cmd_args | append "--api-group" | append $api_group)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let all_resources = run-external ...$full_cmd | from json

    # Find the specific resource
    let resource_info = $all_resources.resources | where name == $resource or ($resource in shortNames?)

    if ($resource_info | length) == 0 {
      return ({
        type: "error"
        message: $"Resource '($resource)' not found in cluster"
        suggestion: "Use 'api_resources' to list all available resources"
      } | to json)
    }

    let target_resource = $resource_info | first

    # Get additional resource details if needed
    let enhanced_info = {
      name: $target_resource.name
      singularName: $target_resource.singularName
      kind: $target_resource.kind
      group: $target_resource.group
      version: $target_resource.version
      namespaced: $target_resource.namespaced
      shortNames: $target_resource.shortNames?
      verbs: (if $show_verbs { $target_resource.verbs? } else { null })
      categories: (if $show_categories { $target_resource.categories? } else { null })
      storageVersionHash: $target_resource.storageVersionHash?
    }

    {
      type: "api_resource_info_result"
      operation: "api_resource_info"
      resource_name: $resource
      filters: {
        api_group: $api_group
      }
      options: {
        show_verbs: $show_verbs
        show_categories: $show_categories
      }
      command: ($full_cmd | str join " ")
      resource_info: $enhanced_info
      message: $"Detailed information for resource '($resource)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting resource info for '($resource)': ($error.msg)"
      suggestions: [
        "Verify the resource name is correct"
        "Check the API group if specified"
        "Ensure you have permission to list API resources"
        "Try listing all resources first to find the correct name"
      ]
    } | to json
  }
}

# Display cluster information
def cluster_info [
  dump: bool = false
  output_directory?: string
] {
  try {
    mut cmd_args = ["cluster-info"]

    if $dump {
      $cmd_args = ($cmd_args | append "dump")
      
      if $output_directory != null {
        $cmd_args = ($cmd_args | append "--output-directory" | append $output_directory)
      }
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "cluster_info_result"
      operation: (if $dump { "cluster_info_dump" } else { "cluster_info" })
      options: {
        dump: $dump
        output_directory: $output_directory
      }
      command: ($full_cmd | str join " ")
      cluster_info: $result
      message: (if $dump { 
        $"Cluster information dumped" + (if $output_directory != null { $" to ($output_directory)" } else { "" })
      } else { 
        "Cluster information retrieved" 
      })
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting cluster info: ($error.msg)"
      suggestions: [
        "Verify cluster connectivity"
        "Check that you have permission to access cluster info"
        "Ensure output directory exists and is writable if using dump"
        "Verify kubectl is properly configured"
      ]
    } | to json
  }
}

# Get server version information
def server_version [
  output: string = "json"
  client: bool = false
] {
  try {
    mut cmd_args = ["version"]

    if $client {
      $cmd_args = ($cmd_args | append "--client=false")
    } else {
      $cmd_args = ($cmd_args | append "--client=false")
    }

    if $output == "short" {
      $cmd_args = ($cmd_args | append "--short")
    } else {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    let parsed_result = if $output == "json" {
      try { $result | from json } catch { $result }
    } else {
      $result
    }

    {
      type: "server_version_result"
      operation: "server_version"
      options: {
        output: $output
        include_client: $client
      }
      command: ($full_cmd | str join " ")
      version_info: $parsed_result
      message: "Kubernetes server version information"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting server version: ($error.msg)"
      suggestions: [
        "Verify cluster connectivity"
        "Check that the cluster is running"
        "Ensure kubectl is properly configured"
        "Verify you have permission to access version info"
      ]
    } | to json
  }
}