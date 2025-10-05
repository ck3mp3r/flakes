#!/usr/bin/env nu

# Kubernetes node management tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "cordon_node"
      description: "[MODIFIES CLUSTER] [DISRUPTIVE] Mark node as unschedulable - prevents new pods from being scheduled on node"
      input_schema: {
        type: "object"
        properties: {
          node_name: {
            type: "string"
            description: "Name of the node to cordon (mandatory for safety)"
          }
          reason: {
            type: "string"
            description: "Reason for cordoning the node"
          }
        }
        required: ["node_name"]
      }
    }
    {
      name: "uncordon_node"
      description: "[MODIFIES CLUSTER] Mark node as schedulable - allows new pods to be scheduled on node"
      input_schema: {
        type: "object"
        properties: {
          node_name: {
            type: "string"
            description: "Name of the node to uncordon (mandatory for safety)"
          }
        }
        required: ["node_name"]
      }
    }
    {
      name: "drain_node"
      description: "[MODIFIES CLUSTER] [HIGHLY DISRUPTIVE] Drain node for maintenance - evicts all pods and cordons node"
      input_schema: {
        type: "object"
        properties: {
          node_name: {
            type: "string"
            description: "Name of the node to drain (mandatory for safety)"
          }
          force: {
            type: "boolean"
            description: "Force drain even if there are pods not managed by a controller"
            default: false
          }
          ignore_daemonsets: {
            type: "boolean"
            description: "Ignore DaemonSet-managed pods"
            default: true
          }
          delete_emptydir_data: {
            type: "boolean"
            description: "Delete pods even if they use emptyDir volumes"
            default: false
          }
          grace_period: {
            type: "integer"
            description: "Grace period for pod termination in seconds"
            default: -1
          }
          timeout: {
            type: "string"
            description: "Timeout for drain operation (e.g., '5m', '30s')"
            default: "0s"
          }
          dry_run: {
            type: "boolean"
            description: "Show what would be drained without actually doing it"
            default: false
          }
        }
        required: ["node_name"]
      }
    }
    {
      name: "taint_node"
      description: "[MODIFIES CLUSTER] [DISRUPTIVE] Add, update, or remove node taints - affects pod scheduling"
      input_schema: {
        type: "object"
        properties: {
          node_name: {
            type: "string"
            description: "Name of the node to taint (mandatory for safety)"
          }
          taints: {
            type: "array"
            items: {type: "string"}
            description: "Taints to add/update in format 'key=value:effect' or 'key:effect'"
          }
          remove_taints: {
            type: "array"
            items: {type: "string"}
            description: "Taints to remove in format 'key' or 'key:effect'"
          }
          overwrite: {
            type: "boolean"
            description: "Overwrite existing taint with same key"
            default: false
          }
        }
        required: ["node_name"]
      }
    }
    {
      name: "get_node_info"
      description: "Get detailed information about a specific node"
      input_schema: {
        type: "object"
        properties: {
          node_name: {
            type: "string"
            description: "Name of the node to get info for"
          }
          show_labels: {
            type: "boolean"
            description: "Include node labels in output"
            default: true
          }
          show_taints: {
            type: "boolean"
            description: "Include node taints in output"
            default: true
          }
          show_allocatable: {
            type: "boolean"
            description: "Include allocatable resources"
            default: true
          }
        }
        required: ["node_name"]
      }
    }
    {
      name: "list_nodes"
      description: "List all nodes with their status and basic information"
      input_schema: {
        type: "object"
        properties: {
          show_labels: {
            type: "boolean"
            description: "Show node labels"
            default: false
          }
          label_selector: {
            type: "string"
            description: "Filter nodes by label selector"
          }
          field_selector: {
            type: "string"
            description: "Filter nodes by field selector"
          }
          output: {
            type: "string"
            description: "Output format"
            enum: ["wide", "json", "yaml"]
            default: "wide"
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
    "cordon_node" => {
      let node_name = $parsed_args.node_name
      let reason = $parsed_args.reason?

      cordon_node $node_name $reason
    }
    "uncordon_node" => {
      let node_name = $parsed_args.node_name

      uncordon_node $node_name
    }
    "drain_node" => {
      let node_name = $parsed_args.node_name
      let force = $parsed_args.force? | default false
      let ignore_daemonsets = $parsed_args.ignore_daemonsets? | default true
      let delete_emptydir_data = $parsed_args.delete_emptydir_data? | default false
      let grace_period = $parsed_args.grace_period? | default -1
      let timeout = $parsed_args.timeout? | default "0s"
      let dry_run = $parsed_args.dry_run? | default false

      drain_node $node_name $force $ignore_daemonsets $delete_emptydir_data $grace_period $timeout $dry_run
    }
    "taint_node" => {
      let node_name = $parsed_args.node_name
      let taints = $parsed_args.taints?
      let remove_taints = $parsed_args.remove_taints?
      let overwrite = $parsed_args.overwrite? | default false

      taint_node $node_name $taints $remove_taints $overwrite
    }
    "get_node_info" => {
      let node_name = $parsed_args.node_name
      let show_labels = $parsed_args.show_labels? | default true
      let show_taints = $parsed_args.show_taints? | default true
      let show_allocatable = $parsed_args.show_allocatable? | default true

      get_node_info $node_name $show_labels $show_taints $show_allocatable
    }
    "list_nodes" => {
      let show_labels = $parsed_args.show_labels? | default false
      let label_selector = $parsed_args.label_selector?
      let field_selector = $parsed_args.field_selector?
      let output = $parsed_args.output? | default "wide"

      list_nodes $show_labels $label_selector $field_selector $output
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Cordon a node (mark as unschedulable)
def cordon_node [
  node_name: string
  reason?: string
] {
  try {
    mut cmd_args = ["cordon" $node_name]

    if $reason != null {
      $cmd_args = ($cmd_args | append "--reason" | append $reason)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "cordon_result"
      operation: "cordon"
      node_name: $node_name
      reason: $reason
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Node '($node_name)' has been cordoned (marked unschedulable)"
      warning: "New pods will not be scheduled on this node until uncordoned"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error cordoning node '($node_name)': ($error.msg)"
      suggestions: [
        "Verify the node name is correct"
        "Ensure you have permission to modify nodes"
        "Check that the node exists in the cluster"
        "Verify connectivity to the cluster"
      ]
    } | to json
  }
}

# Uncordon a node (mark as schedulable)
def uncordon_node [
  node_name: string
] {
  try {
    let cmd_args = ["uncordon" $node_name]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "uncordon_result"
      operation: "uncordon"
      node_name: $node_name
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Node '($node_name)' has been uncordoned (marked schedulable)"
      note: "New pods can now be scheduled on this node"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error uncordoning node '($node_name)': ($error.msg)"
      suggestions: [
        "Verify the node name is correct"
        "Ensure you have permission to modify nodes"
        "Check that the node exists in the cluster"
        "Verify the node was previously cordoned"
      ]
    } | to json
  }
}

# Drain a node for maintenance
def drain_node [
  node_name: string
  force: bool = false
  ignore_daemonsets: bool = true
  delete_emptydir_data: bool = false
  grace_period: int = -1
  timeout: string = "0s"
  dry_run: bool = false
] {
  try {
    mut cmd_args = ["drain" $node_name]

    if $force {
      $cmd_args = ($cmd_args | append "--force")
    }

    if $ignore_daemonsets {
      $cmd_args = ($cmd_args | append "--ignore-daemonsets")
    }

    if $delete_emptydir_data {
      $cmd_args = ($cmd_args | append "--delete-emptydir-data")
    }

    if $grace_period >= 0 {
      $cmd_args = ($cmd_args | append "--grace-period" | append ($grace_period | into string))
    }

    if $timeout != "0s" {
      $cmd_args = ($cmd_args | append "--timeout" | append $timeout)
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "drain_result"
      operation: (if $dry_run { "dry_run_drain" } else { "drain" })
      node_name: $node_name
      options: {
        force: $force
        ignore_daemonsets: $ignore_daemonsets
        delete_emptydir_data: $delete_emptydir_data
        grace_period: $grace_period
        timeout: $timeout
        dry_run: $dry_run
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: (if $dry_run { 
        $"Dry run: Would drain node '($node_name)'" 
      } else { 
        $"Node '($node_name)' has been drained" 
      })
      warning: "Node is now cordoned and pods have been evicted - safe for maintenance"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error draining node '($node_name)': ($error.msg)"
      suggestions: [
        "Check if there are pods that cannot be evicted"
        "Consider using --force for pods not managed by controllers"
        "Use --delete-emptydir-data if pods use emptyDir volumes"
        "Increase timeout for slow pod termination"
        "Verify you have permission to evict pods"
        "Check if there are PodDisruptionBudgets blocking eviction"
      ]
    } | to json
  }
}

# Add, update, or remove node taints
def taint_node [
  node_name: string
  taints?: any
  remove_taints?: any
  overwrite: bool = false
] {
  if $taints == null and $remove_taints == null {
    return ({
      type: "error"
      message: "Must specify either taints to add/update or taints to remove"
    } | to json)
  }

  try {
    mut cmd_args = ["taint" "node" $node_name]

    # Add taints
    if $taints != null {
      for $taint in $taints {
        $cmd_args = ($cmd_args | append $taint)
      }
      
      if $overwrite {
        $cmd_args = ($cmd_args | append "--overwrite")
      }
    }

    # Remove taints
    if $remove_taints != null {
      for $taint in $remove_taints {
        $cmd_args = ($cmd_args | append $"($taint)-")
      }
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "taint_result"
      operation: "taint"
      node_name: $node_name
      added_taints: $taints
      removed_taints: $remove_taints
      options: {
        overwrite: $overwrite
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Node taints updated for '($node_name)'"
      note: "Taints affect which pods can be scheduled on this node"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error updating taints on node '($node_name)': ($error.msg)"
      suggestions: [
        "Check taint format: 'key=value:effect' or 'key:effect'"
        "Valid effects are: NoSchedule, PreferNoSchedule, NoExecute"
        "Use '--overwrite' to update existing taints"
        "Verify you have permission to modify nodes"
        "Check that the node exists"
      ]
    } | to json
  }
}

# Get detailed information about a node
def get_node_info [
  node_name: string
  show_labels: bool = true
  show_taints: bool = true
  show_allocatable: bool = true
] {
  try {
    mut cmd_args = ["get" "node" $node_name "--output" "json"]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd | from json

    # Extract key information
    let node_info = {
      name: $result.metadata.name
      status: $result.status.conditions | where type == "Ready" | get 0.status
      addresses: ($result.status.addresses | each {|addr| {type: $addr.type, address: $addr.address}})
      node_info: $result.status.nodeInfo
      capacity: $result.status.capacity
      allocatable: (if $show_allocatable { $result.status.allocatable } else { null })
      labels: (if $show_labels { $result.metadata.labels } else { null })
      taints: (if $show_taints { $result.spec.taints? } else { null })
      creation_timestamp: $result.metadata.creationTimestamp
    }

    {
      type: "node_info_result"
      operation: "get_node_info"
      node_name: $node_name
      command: ($full_cmd | str join " ")
      node_info: $node_info
      raw_data: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting node info for '($node_name)': ($error.msg)"
      suggestions: [
        "Verify the node name is correct"
        "Check that the node exists in the cluster"
        "Ensure you have permission to view nodes"
        "Verify connectivity to the cluster"
      ]
    } | to json
  }
}

# List all nodes with their status
def list_nodes [
  show_labels: bool = false
  label_selector?: string
  field_selector?: string
  output: string = "wide"
] {
  try {
    mut cmd_args = ["get" "nodes"]

    if $output != "wide" {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    } else {
      $cmd_args = ($cmd_args | append "--output" | append "wide")
    }

    if $show_labels {
      $cmd_args = ($cmd_args | append "--show-labels")
    }

    if $label_selector != null {
      $cmd_args = ($cmd_args | append "--selector" | append $label_selector)
    }

    if $field_selector != null {
      $cmd_args = ($cmd_args | append "--field-selector" | append $field_selector)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "list_nodes_result"
      operation: "list_nodes"
      filters: {
        label_selector: $label_selector
        field_selector: $field_selector
        show_labels: $show_labels
      }
      output_format: $output
      command: ($full_cmd | str join " ")
      nodes: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error listing nodes: ($error.msg)"
      suggestions: [
        "Check label selector syntax if specified"
        "Verify field selector syntax if specified"
        "Ensure you have permission to list nodes"
        "Check connectivity to the cluster"
      ]
    } | to json
  }
}