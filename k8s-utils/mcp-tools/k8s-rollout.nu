# Kubernetes rollout management tool for nu-mcp

use nu-mcp-lib *

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "rollout_history"
      title: "Rollout History"
      description: "View rollout history for deployments, daemonsets, or statefulsets"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (deployment, daemonset, statefulset)"
            enum: ["deployment", "daemonset", "statefulset"]
          }
          name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          revision: {
            type: "integer"
            description: "Show details for specific revision"
          }
          limit: {
            type: "integer"
            description: "Limit the number of revisions to show"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "rollout_status"
      title: "Rollout Status"
      description: "Check rollout status of deployment, daemonset, or statefulset"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (deployment, daemonset, statefulset)"
            enum: ["deployment", "daemonset", "statefulset"]
          }
          name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
      output_schema: {
        type: "object"
        properties: {
          type: {type: "string"}
          operation: {type: "string"}
          command: {type: "string"}
          result: {type: "string"}
        }
        required: ["type", "operation", "command"]
      }
    }
    {
      name: "rollout_pause"
      title: "Pause Rollout"
      description: "[MODIFIES CLUSTER] [DISRUPTIVE] Pause a rollout to prevent further updates"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (deployment, daemonset, statefulset)"
            enum: ["deployment", "daemonset", "statefulset"]
          }
          name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "rollout_resume"
      title: "Resume Rollout"
      description: "[MODIFIES CLUSTER] [DISRUPTIVE] Resume a paused rollout"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (deployment, daemonset, statefulset)"
            enum: ["deployment", "daemonset", "statefulset"]
          }
          name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "rollout_restart"
      title: "Restart Rollout"
      description: "[MODIFIES CLUSTER] [HIGHLY DISRUPTIVE] Restart a rollout by triggering a new deployment"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (deployment, daemonset, statefulset)"
            enum: ["deployment", "daemonset", "statefulset"]
          }
          name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          wait: {
            type: "boolean"
            description: "Wait for the restart to complete"
            default: false
          }
          timeout: {
            type: "string"
            description: "Timeout for waiting (e.g., '10m', '5m')"
            default: "10m"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "rollout_undo"
      title: "Undo Rollout"
      description: "[MODIFIES CLUSTER] [HIGHLY DISRUPTIVE] Undo a rollout to previous revision"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (deployment, daemonset, statefulset)"
            enum: ["deployment", "daemonset", "statefulset"]
          }
          name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          to_revision: {
            type: "integer"
            description: "Revision number to roll back to (optional - uses previous if not specified)"
          }
          wait: {
            type: "boolean"
            description: "Wait for the rollback to complete"
            default: false
          }
          timeout: {
            type: "string"
            description: "Timeout for waiting (e.g., '10m', '5m')"
            default: "10m"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "name", "namespace"]
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
    "rollout_history" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let revision = $parsed_args.revision?
      let limit = $parsed_args.limit?
      let delegate_to = $parsed_args.delegate_to?

      rollout_history $resource_type $name $namespace $revision $limit $delegate_to
    }
    "rollout_status" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let delegate_to = $parsed_args.delegate_to?
      
      rollout_status $resource_type $name $namespace $delegate_to
    }
    "rollout_pause" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let delegate_to = $parsed_args.delegate_to?

      rollout_pause $resource_type $name $namespace $delegate_to
    }
    "rollout_resume" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let delegate_to = $parsed_args.delegate_to?

      rollout_resume $resource_type $name $namespace $delegate_to
    }
    "rollout_restart" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let wait = $parsed_args.wait? | default false
      let timeout = $parsed_args.timeout? | default "10m"
      let delegate_to = $parsed_args.delegate_to?

      rollout_restart $resource_type $name $namespace $wait $timeout $delegate_to
    }
    "rollout_undo" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let to_revision = $parsed_args.to_revision?
      let wait = $parsed_args.wait? | default false
      let timeout = $parsed_args.timeout? | default "10m"
      let delegate_to = $parsed_args.delegate_to?

      rollout_undo $resource_type $name $namespace $to_revision $wait $timeout $delegate_to
    }
    _ => {
      result [(text $"Unknown tool: ($tool_name)")] --error=true | to json
    }
  }
}

# View rollout history
def rollout_history [
  resource_type: string
  name: string
  namespace: string
  revision?: int
  limit?: int
  delegate_to?: string
] {
  try {
    mut cmd_args = ["rollout" "history" $"($resource_type)/($name)" "--namespace" $namespace]

    if $revision != null {
      $cmd_args = ($cmd_args | append $"--revision=($revision)")
    }

    if $limit != null {
      $cmd_args = ($cmd_args | append $"--limit=($limit)")
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "rollout_history"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          resource_type: $resource_type
          name: $name
          namespace: $namespace
          revision: $revision
          limit: $limit
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "rollout_history_result"
      operation: "rollout_history"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      filters: {
        revision: $revision
        limit: $limit
      }
      command: $cmd_string
      result: $result
      message: $"Rollout history for ($resource_type) '($name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting rollout history for ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to view it"
        "Check that the resource type supports rollout operations"
        "Ensure the namespace is correct"
        "Try without revision filter if specified"
      ]
    } | to json
  }
}

# Check rollout status
def rollout_status [
  resource_type: string
  name: string
  namespace: string
  delegate_to?: string
] {
  try {
    let cmd_args = ["rollout" "status" $"($resource_type)/($name)" "--namespace" $namespace]

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "rollout_status"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          resource_type: $resource_type
          name: $name
          namespace: $namespace
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "rollout_status_result"
      operation: "rollout_status"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      command: $cmd_string
      result: $result
      message: $"Rollout status for ($resource_type) '($name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting rollout status for ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to view it"
        "Check that the resource type supports rollout operations"
        "Ensure the namespace is correct"
      ]
    } | to json
  }
}

# Pause a rollout
def rollout_pause [
  resource_type: string
  name: string
  namespace: string
  delegate_to?: string
] {
  try {
    let cmd_args = ["rollout" "pause" $"($resource_type)/($name)" "--namespace" $namespace]

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "rollout_pause"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          resource_type: $resource_type
          name: $name
          namespace: $namespace
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "rollout_pause_result"
      operation: "rollout_pause"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      command: $cmd_string
      result: $result
      message: $"Paused rollout for ($resource_type) '($name)' - no further updates will occur until resumed"
      warning: "The rollout is now paused. Use rollout_resume to continue updates."
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error pausing rollout for ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to modify it"
        "Check that the resource type supports pause operations"
        "Ensure the namespace is correct"
        "Verify the rollout is not already paused"
      ]
    } | to json
  }
}

# Resume a paused rollout
def rollout_resume [
  resource_type: string
  name: string
  namespace: string
  delegate_to?: string
] {
  try {
    let cmd_args = ["rollout" "resume" $"($resource_type)/($name)" "--namespace" $namespace]

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "rollout_resume"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          resource_type: $resource_type
          name: $name
          namespace: $namespace
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "rollout_resume_result"
      operation: "rollout_resume"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      command: $cmd_string
      result: $result
      message: $"Resumed rollout for ($resource_type) '($name)' - updates will now continue"
      note: "The rollout is now active. Monitor with rollout_status to track progress."
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error resuming rollout for ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to modify it"
        "Check that the resource type supports resume operations"
        "Ensure the namespace is correct"
        "Verify the rollout was previously paused"
      ]
    } | to json
  }
}

# Restart a rollout
def rollout_restart [
  resource_type: string
  name: string
  namespace: string
  wait: bool = false
  timeout: string = "10m"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["rollout" "restart" $"($resource_type)/($name)" "--namespace" $namespace]

    if $wait {
      $cmd_args = ($cmd_args | append "--wait=true" | append $"--timeout=($timeout)")
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "rollout_restart"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          resource_type: $resource_type
          name: $name
          namespace: $namespace
          wait: $wait
          timeout: $timeout
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "rollout_restart_result"
      operation: "rollout_restart"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      options: {
        wait: $wait
        timeout: $timeout
      }
      command: $cmd_string
      result: $result
      message: $"Restarted rollout for ($resource_type) '($name)' - all pods will be recreated"
      warning: "This operation causes service disruption as all pods are restarted"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error restarting rollout for ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to modify it"
        "Check that the resource type supports restart operations"
        "Ensure the namespace is correct"
        "Try without wait option if operation times out"
      ]
    } | to json
  }
}

# Undo a rollout to previous revision
def rollout_undo [
  resource_type: string
  name: string
  namespace: string
  to_revision?: int
  wait: bool = false
  timeout: string = "10m"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["rollout" "undo" $"($resource_type)/($name)" "--namespace" $namespace]

    if $to_revision != null {
      $cmd_args = ($cmd_args | append $"--to-revision=($to_revision)")
    }

    if $wait {
      $cmd_args = ($cmd_args | append "--wait=true" | append $"--timeout=($timeout)")
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "rollout_undo"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          resource_type: $resource_type
          name: $name
          namespace: $namespace
          to_revision: $to_revision
          wait: $wait
          timeout: $timeout
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "rollout_undo_result"
      operation: "rollout_undo"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      to_revision: $to_revision
      options: {
        wait: $wait
        timeout: $timeout
      }
      command: $cmd_string
      result: $result
      message: (if $to_revision != null { 
        $"Rolled back ($resource_type) '($name)' to revision ($to_revision)" 
      } else { 
        $"Rolled back ($resource_type) '($name)' to previous revision" 
      })
      warning: "This operation causes service disruption during the rollback process"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error undoing rollout for ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to modify it"
        "Check that there are previous revisions available"
        "Ensure the specified revision exists (if provided)"
        "Verify the namespace is correct"
        "Use rollout_history to see available revisions"
      ]
    } | to json
  }
}