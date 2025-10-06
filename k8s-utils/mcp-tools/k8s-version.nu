# Kubernetes version information tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "version_client"
      description: "Show kubectl client version information"
      input_schema: {
        type: "object"
        properties: {
          output: {
            type: "string"
            description: "Output format"
            enum: ["json", "yaml", "short"]
            default: "json"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "version_server"
      description: "Show Kubernetes server version information"
      input_schema: {
        type: "object"
        properties: {
          output: {
            type: "string"
            description: "Output format"
            enum: ["json", "yaml", "short"]
            default: "json"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "version_both"
      description: "Show both client and server version information"
      input_schema: {
        type: "object"
        properties: {
          output: {
            type: "string"
            description: "Output format"
            enum: ["json", "yaml", "short"]
            default: "json"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "version_short"
      description: "Show concise version information for both client and server"
      input_schema: {
        type: "object"
        properties: {
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "version_compatibility"
      description: "Check client-server version compatibility and show version skew information"
      input_schema: {
        type: "object"
        properties: {
          show_details: {
            type: "boolean"
            description: "Show detailed compatibility analysis"
            default: true
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "cluster_version_info"
      description: "Get comprehensive cluster version and build information"
      input_schema: {
        type: "object"
        properties: {
          include_nodes: {
            type: "boolean"
            description: "Include node version information"
            default: false
          }
          include_components: {
            type: "boolean"
            description: "Include system component versions"
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
  args: string = "{}" # JSON arguments for the tool
] {
  let parsed_args = $args | from json

  match $tool_name {
    "version_client" => {
      let output = $parsed_args.output? | default "json"
      let delegate_to = $parsed_args.delegate_to?
      version_client $output $delegate_to
    }
    "version_server" => {
      let output = $parsed_args.output? | default "json"
      let delegate_to = $parsed_args.delegate_to?
      version_server $output $delegate_to
    }
    "version_both" => {
      let output = $parsed_args.output? | default "json"
      let delegate_to = $parsed_args.delegate_to?
      version_both $output $delegate_to
    }
    "version_short" => {
      let delegate_to = $parsed_args.delegate_to?
      version_short $delegate_to
    }
    "version_compatibility" => {
      let show_details = $parsed_args.show_details? | default true
      let delegate_to = $parsed_args.delegate_to?
      version_compatibility $show_details $delegate_to
    }
    "cluster_version_info" => {
      let include_nodes = $parsed_args.include_nodes? | default false
      let include_components = $parsed_args.include_components? | default false
      let delegate_to = $parsed_args.delegate_to?
      cluster_version_info $include_nodes $include_components $delegate_to
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Get kubectl client version
def version_client [
  output: string = "json"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["version" "--client=true"]

    if $output == "short" {
      $cmd_args = ($cmd_args | append "--short")
    } else {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "version_client"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          output: $output
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    let parsed_result = if $output == "json" {
      try { $result | from json } catch { $result }
    } else {
      $result
    }

    {
      type: "client_version_result"
      operation: "version_client"
      output_format: $output
      command: $cmd_string
      client_version: $parsed_result
      message: "kubectl client version information"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting client version: ($error.msg)"
      suggestions: [
        "Verify kubectl is installed and in PATH"
        "Check kubectl installation integrity"
      ]
    } | to json
  }
}

# Get Kubernetes server version
def version_server [
  output: string = "json"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["version" "--client=false"]

    if $output == "short" {
      $cmd_args = ($cmd_args | append "--short")
    } else {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "version_server"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          output: $output
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    let parsed_result = if $output == "json" {
      try { $result | from json } catch { $result }
    } else {
      $result
    }

    {
      type: "server_version_result"
      operation: "version_server"
      output_format: $output
      command: $cmd_string
      server_version: $parsed_result
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

# Get both client and server versions
def version_both [
  output: string = "json"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["version"]

    if $output == "short" {
      $cmd_args = ($cmd_args | append "--short")
    } else {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "version_both"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          output: $output
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    let parsed_result = if $output == "json" {
      try { $result | from json } catch { $result }
    } else {
      $result
    }

    {
      type: "version_both_result"
      operation: "version_both"
      output_format: $output
      command: $cmd_string
      version_info: $parsed_result
      message: "Both client and server version information"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting version information: ($error.msg)"
      suggestions: [
        "Verify kubectl is installed and configured"
        "Check cluster connectivity for server version"
        "Ensure you have permission to access cluster"
      ]
    } | to json
  }
}

# Get short version information
def version_short [
  delegate_to?: string
] {
  try {
    let cmd_args = ["version" "--short"]

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "version_short"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {}
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    # Parse the short output to extract versions
    let lines = $result | lines | where {|line| ($line | str length) > 0}
    mut client_version = ""
    mut server_version = ""

    for line in $lines {
      if ($line | str starts-with "Client Version:") {
        $client_version = ($line | str replace "Client Version: " "")
      } else if ($line | str starts-with "Server Version:") {
        $server_version = ($line | str replace "Server Version: " "")
      }
    }

    {
      type: "version_short_result"
      operation: "version_short"
      command: $cmd_string
      client_version: $client_version
      server_version: $server_version
      raw_output: $result
      message: "Short version information"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting short version info: ($error.msg)"
      suggestions: [
        "Verify kubectl is installed"
        "Check cluster connectivity"
        "Ensure proper kubectl configuration"
      ]
    } | to json
  }
}

# Check version compatibility between client and server
def version_compatibility [
  show_details: bool = true
  delegate_to?: string
] {
  try {
    # Get both versions in JSON format for analysis
    let version_cmd = ["version" "--output" "json"]
    let full_cmd = (["kubectl"] | append $version_cmd)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "version_compatibility"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          show_details: $show_details
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let version_result = run-external ...$full_cmd

    let version_info = try { $version_result | from json } catch { 
      return ({
        type: "error"
        message: "Could not parse version information"
        raw_output: $version_result
      } | to json)
    }

    # Extract version numbers
    let client_version = $version_info.clientVersion?.gitVersion? | default "unknown"
    let server_version = $version_info.serverVersion?.gitVersion? | default "unknown"

    # Basic compatibility analysis (simplified)
    let client_parts = $client_version | str replace "v" "" | split row "."
    let server_parts = $server_version | str replace "v" "" | split row "."

    mut compatibility_status = "unknown"
    mut compatibility_notes = []

    if ($client_parts | length) >= 2 and ($server_parts | length) >= 2 {
      let client_major = $client_parts | get 0 | into int
      let client_minor = $client_parts | get 1 | into int
      let server_major = $server_parts | get 0 | into int
      let server_minor = $server_parts | get 1 | into int

      if $client_major == $server_major {
        let minor_diff = ($client_minor - $server_minor | math abs)
        if $minor_diff <= 1 {
          $compatibility_status = "compatible"
          $compatibility_notes = (["Client and server versions are within supported range"])
        } else {
          $compatibility_status = "warning"
          $compatibility_notes = ([$"Version skew detected: ($minor_diff) minor versions apart"])
        }
      } else {
        $compatibility_status = "incompatible"
        $compatibility_notes = (["Major version mismatch - client and server may not work together"])
      }
    }

    let detailed_analysis = if $show_details {
      {
        client_version: $client_version
        server_version: $server_version
        client_build: $version_info.clientVersion?
        server_build: $version_info.serverVersion?
        compatibility_matrix: {
          same_major_version: ($client_parts.0? == $server_parts.0?)
          minor_version_diff: (if ($client_parts | length) >= 2 and ($server_parts | length) >= 2 { 
            ($client_parts.1 | into int) - ($server_parts.1 | into int) 
          } else { 
            null 
          })
          recommended_action: (match $compatibility_status {
            "compatible" => "No action needed"
            "warning" => "Consider updating client or server to reduce version skew"
            "incompatible" => "Update client or server to compatible versions"
            _ => "Unable to determine compatibility"
          })
        }
      }
    } else {
      null
    }

    {
      type: "version_compatibility_result"
      operation: "version_compatibility"
      command: $cmd_string
      compatibility_status: $compatibility_status
      compatibility_notes: $compatibility_notes
      versions: {
        client: $client_version
        server: $server_version
      }
      detailed_analysis: $detailed_analysis
      message: $"Version compatibility check: ($compatibility_status)"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error checking version compatibility: ($error.msg)"
      suggestions: [
        "Verify both client and server are accessible"
        "Check cluster connectivity"
        "Ensure kubectl is properly configured"
      ]
    } | to json
  }
}

# Get comprehensive cluster version information
def cluster_version_info [
  include_nodes: bool = false
  include_components: bool = false
  delegate_to?: string
] {
  try {
    # Get basic version info
    let version_cmd = ["version" "--output" "json"]
    let version_full_cmd = (["kubectl"] | append $version_cmd)
    let version_cmd_string = $version_full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "cluster_version_info"
        command: $version_cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          include_nodes: $include_nodes
          include_components: $include_components
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($version_cmd_string)"
    let version_result = run-external ...$version_full_cmd

    let version_info = try { $version_result | from json } catch { $version_result }

    mut cluster_info = {
      kubectl_version: $version_info.clientVersion?
      kubernetes_version: $version_info.serverVersion?
    }

    # Get node information if requested
    if $include_nodes {
      let node_info = try {
        let nodes_cmd = ["get" "nodes" "--output" "json"]
        let nodes_full_cmd = (["kubectl"] | append $nodes_cmd)
        let nodes_cmd_string = $nodes_full_cmd | str join " "
        print $"Executing: ($nodes_cmd_string)"
        let nodes_result = run-external ...$nodes_full_cmd | from json

        let node_versions = $nodes_result.items | each {|node|
          {
            name: $node.metadata.name
            kubelet_version: $node.status.nodeInfo.kubeletVersion
            kube_proxy_version: $node.status.nodeInfo.kubeProxyVersion
            container_runtime: $node.status.nodeInfo.containerRuntimeVersion
            os_image: $node.status.nodeInfo.osImage
            kernel_version: $node.status.nodeInfo.kernelVersion
          }
        }
        {node_versions: $node_versions}
      } catch {
        {node_versions_error: "Could not retrieve node version information"}
      }
      
      $cluster_info = ($cluster_info | merge $node_info)
    }

    # Get component information if requested
    if $include_components {
      let component_info = try {
        let components_cmd = ["get" "componentstatuses" "--output" "json"]
        let components_full_cmd = (["kubectl"] | append $components_cmd)
        let components_cmd_string = $components_full_cmd | str join " "
        print $"Executing: ($components_cmd_string)"
        let components_result = run-external ...$components_full_cmd | from json

        let comp_status = $components_result.items | each {|comp|
          {
            name: $comp.metadata.name
            conditions: $comp.conditions
          }
        }
        {component_status: $comp_status}
      } catch {
        {component_status_error: "Could not retrieve component status information"}
      }
      
      $cluster_info = ($cluster_info | merge $component_info)
    }

    {
      type: "cluster_version_info_result"
      operation: "cluster_version_info"
      options: {
        include_nodes: $include_nodes
        include_components: $include_components
      }
      commands_executed: [$version_cmd_string]
      cluster_version_info: $cluster_info
      message: "Comprehensive cluster version information"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting cluster version info: ($error.msg)"
      suggestions: [
        "Verify cluster connectivity"
        "Check kubectl configuration"
        "Ensure you have permission to access cluster resources"
        "Try with reduced options if some information is not accessible"
      ]
    } | to json
  }
}