#!/usr/bin/env nu

# Kubernetes exec tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "exec_command"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Execute command in a container - can modify files, processes, or container state"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type (pod, deployment, service)"
            default: "pod"
          }
          name: {
            type: "string"
            description: "Resource name to execute command in"
          }
          namespace: {
            type: "string"
            description: "Namespace (required for safety)"
          }
          container: {
            type: "string"
            description: "Container name (required for explicit targeting)"
          }
          command: {
            type: "array"
            items: {type: "string"}
            description: "Command and arguments to execute"
          }
          quiet: {
            type: "boolean"
            description: "Only print output from the remote session"
            default: false
          }
          pod_running_timeout: {
            type: "string"
            description: "Timeout to wait for pod to be running"
            default: "1m0s"
          }
        }
        required: ["name", "namespace", "container", "command"]
      }
    }
    {
      name: "exec_script"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Execute script content in container - can modify files, processes, or container state"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type"
            default: "pod"
          }
          name: {
            type: "string"
            description: "Resource name"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          container: {
            type: "string"
            description: "Container name"
          }
          script_content: {
            type: "string"
            description: "Script content to execute"
          }
          interpreter: {
            type: "string"
            description: "Script interpreter (/bin/bash, /bin/sh, python, etc.)"
            default: "/bin/bash"
          }
          working_directory: {
            type: "string"
            description: "Working directory for script execution"
          }
        }
        required: ["name", "namespace", "container", "script_content"]
      }
    }
    {
      name: "exec_multiple"
      description: "[MODIFIES CLUSTER] [HIGHLY DESTRUCTIVE] Execute same command across multiple pods - can modify multiple containers simultaneously"
      input_schema: {
        type: "object"
        properties: {
          selector: {
            type: "string"
            description: "Label selector to match pods"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          all_namespaces: {
            type: "boolean"
            description: "Execute across all namespaces"
            default: false
          }
          container: {
            type: "string"
            description: "Container name"
          }
          command: {
            type: "array"
            items: {type: "string"}
            description: "Command and arguments to execute"
          }
          max_concurrent: {
            type: "integer"
            description: "Maximum concurrent executions"
            default: 5
          }
          continue_on_error: {
            type: "boolean"
            description: "Continue if execution fails on some pods"
            default: true
          }
        }
        required: ["selector", "namespace", "container", "command"]
      }
    }
    {
      name: "exec_file_transfer"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Execute commands for file operations - can create, modify, or delete files in containers"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type"
            default: "pod"
          }
          name: {
            type: "string"
            description: "Resource name"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          container: {
            type: "string"
            description: "Container name"
          }
          operation: {
            type: "string"
            description: "File operation (list, cat, write, delete)"
            enum: ["list", "cat", "write", "delete", "mkdir", "chmod"]
          }
          path: {
            type: "string"
            description: "Target path in container"
          }
          content: {
            type: "string"
            description: "Content for write operations"
          }
          permissions: {
            type: "string"
            description: "Permissions for chmod operations"
          }
        }
        required: ["name", "namespace", "container", "operation", "path"]
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
    "exec_command" => {
      let resource_type = $parsed_args.resource_type? | default "pod"
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let container = $parsed_args.container
      let command = $parsed_args.command
      let quiet = $parsed_args.quiet? | default false
      let pod_running_timeout = $parsed_args.pod_running_timeout? | default "1m0s"

      exec_command $resource_type $name $namespace $container $command $quiet $pod_running_timeout
    }
    "exec_script" => {
      let resource_type = $parsed_args.resource_type? | default "pod"
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let container = $parsed_args.container
      let script_content = $parsed_args.script_content
      let interpreter = $parsed_args.interpreter? | default "/bin/bash"
      let working_directory = $parsed_args.working_directory?

      exec_script $resource_type $name $namespace $container $script_content $interpreter $working_directory
    }
    "exec_multiple" => {
      let selector = $parsed_args.selector
      let namespace = $parsed_args.namespace
      let all_namespaces = $parsed_args.all_namespaces? | default false
      let container = $parsed_args.container
      let command = $parsed_args.command
      let max_concurrent = $parsed_args.max_concurrent? | default 5
      let continue_on_error = $parsed_args.continue_on_error? | default true

      exec_multiple $selector $command $namespace $all_namespaces $container $max_concurrent $continue_on_error
    }
    "exec_file_transfer" => {
      let resource_type = $parsed_args.resource_type? | default "pod"
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let container = $parsed_args.container
      let operation = $parsed_args.operation
      let path = $parsed_args.path
      let content = $parsed_args.content?
      let permissions = $parsed_args.permissions?

      exec_file_transfer $resource_type $name $namespace $container $operation $path $content $permissions
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Execute command in a Kubernetes container
def exec_command [
  resource_type: string
  name: string
  namespace: string
  container: string
  command: list<string>
  quiet: bool = false
  pod_running_timeout: string = "1m0s"
] {
  try {
    mut cmd_args = ["exec"]

    # Add resource type and name
    if $resource_type != "pod" {
      $cmd_args = ($cmd_args | append $"($resource_type)/($name)")
    } else {
      $cmd_args = ($cmd_args | append $name)
    }

    # Add namespace (always required)
    $cmd_args = ($cmd_args | append "--namespace" | append $namespace)

    # Add container (always required)
    $cmd_args = ($cmd_args | append "--container" | append $container)

    # Add flags
    if $quiet {
      $cmd_args = ($cmd_args | append "--quiet")
    }

    # Add timeout
    $cmd_args = ($cmd_args | append "--pod-running-timeout" | append $pod_running_timeout)

    # Add command separator and command
    $cmd_args = ($cmd_args | append "--")
    $cmd_args = ($cmd_args | append $command)

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "exec_result"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
        container: $container
      }
      executed_command: $command
      options: {
        quiet: $quiet
        pod_running_timeout: $pod_running_timeout
      }
      command: ($full_cmd | str join " ")
      output: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error executing command in ($resource_type)/($name): ($error.msg)"
      suggestions: [
        "Verify resource exists and is running"
        "Check container name for multi-container pods"
        "Ensure command exists in container"
        "Verify you have exec permissions"
        "Check if pod is in Ready state"
      ]
    } | to json
  }
}


# Execute script content in container
def exec_script [
  resource_type: string
  name: string
  namespace: string
  container: string
  script_content: string
  interpreter: string = "/bin/bash"
  working_directory?: string
] {
  try {
    # Prepare the script execution command
    mut script_cmd = []
    
    if $working_directory != null {
      $script_cmd = ([$interpreter "-c" $"cd ($working_directory) && ($script_content)"])
    } else {
      $script_cmd = ([$interpreter "-c" $script_content])
    }

    mut cmd_args = ["exec"]

    # Add resource type and name
    if $resource_type != "pod" {
      $cmd_args = ($cmd_args | append $"($resource_type)/($name)")
    } else {
      $cmd_args = ($cmd_args | append $name)
    }

    # Add namespace (always required)
    $cmd_args = ($cmd_args | append "--namespace" | append $namespace)

    # Add container (always required)
    $cmd_args = ($cmd_args | append "--container" | append $container)

    # Add command separator and script command
    $cmd_args = ($cmd_args | append "--")
    $cmd_args = ($cmd_args | append $script_cmd)

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "script_exec_result"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
        container: $container
      }
      script: {
        interpreter: $interpreter
        working_directory: $working_directory
        content_length: ($script_content | str length)
        content_preview: ($script_content | str substring 0..100)
      }
      command: ($full_cmd | str join " ")
      output: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error executing script in ($resource_type)/($name): ($error.msg)"
      suggestions: [
        "Verify script syntax is correct"
        "Check if interpreter exists in container"
        "Ensure working directory exists if specified"
        "Verify script has necessary permissions"
        "Check for script execution policies"
      ]
    } | to json
  }
}

# Execute command across multiple pods
def exec_multiple [
  selector: string
  command: list<string>
  namespace: string
  all_namespaces: bool = false
  container: string
  max_concurrent: int = 5
  continue_on_error: bool = true
] {
  try {
    # First, get list of pods matching selector
    mut get_pods_args = ["get" "pods" "--selector" $selector "--output" "json"]

    if $all_namespaces {
      $get_pods_args = ($get_pods_args | append "--all-namespaces")
    } else {
      $get_pods_args = ($get_pods_args | append "--namespace" | append $namespace)
    }

    # Build and execute pod listing command
    let full_get_cmd = (["kubectl"] | append $get_pods_args)
    print $"Executing: ($full_get_cmd | str join ' ')"
    let pods_result = run-external ...$full_get_cmd | from json

    let pods = $pods_result.items | each {|pod|
      {
        name: $pod.metadata.name
        namespace: $pod.metadata.namespace
        status: $pod.status.phase
      }
    }

    if ($pods | length) == 0 {
      return ({
        type: "error"
        message: $"No pods found matching selector: ($selector)"
        suggestions: [
          "Check label selector syntax"
          "Verify pods exist with matching labels"
          "Ensure correct namespace"
        ]
      } | to json)
    }

    # Execute command on each pod
    let execution_results = $pods | each {|pod|
      try {
        mut exec_args = ["exec" $pod.name]
        
        if $pod.namespace != null {
          $exec_args = ($exec_args | append "--namespace" | append $pod.namespace)
        }

        if $container != null {
          $exec_args = ($exec_args | append "--container" | append $container)
        }

        $exec_args = ($exec_args | append "--")
        $exec_args = ($exec_args | append $command)

        let full_exec_cmd = (["kubectl"] | append $exec_args)
        print $"Executing on ($pod.name): ($full_exec_cmd | str join ' ')"
        let result = run-external ...$full_exec_cmd

        {
          pod: $pod.name
          namespace: $pod.namespace
          status: "success"
          output: $result
          command: ($full_exec_cmd | str join " ")
        }
      } catch {|error|
        {
          pod: $pod.name
          namespace: $pod.namespace
          status: "error"
          error_message: $error.msg
          command: "failed_to_execute"
        }
      }
    }

    let successful_executions = $execution_results | where status == "success" | length
    let failed_executions = $execution_results | where status == "error" | length

    {
      type: "multiple_exec_result"
      selector: $selector
      total_pods: ($pods | length)
      successful: $successful_executions
      failed: $failed_executions
      options: {
        namespace: $namespace
        all_namespaces: $all_namespaces
        container: $container
        max_concurrent: $max_concurrent
        continue_on_error: $continue_on_error
      }
      executed_command: $command
      results: $execution_results
      summary: $"Executed on ($successful_executions) pods successfully, ($failed_executions) failed"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error executing command across multiple pods: ($error.msg)"
      suggestions: [
        "Check label selector syntax"
        "Verify kubectl access to cluster"
        "Ensure pods are in running state"
      ]
    } | to json
  }
}

# Execute file operations in container
def exec_file_transfer [
  resource_type: string
  name: string
  namespace: string
  container: string
  operation: string
  path: string
  content?: string
  permissions?: string
] {
  try {
    let file_command = match $operation {
      "list" => ["ls" "-la" $path]
      "cat" => ["cat" $path]
      "write" => {
        if $content == null {
          error make {msg: "Content required for write operation"}
        }
        ["sh" "-c" $"echo '($content)' > ($path)"]
      }
      "delete" => ["rm" "-f" $path]
      "mkdir" => ["mkdir" "-p" $path]
      "chmod" => {
        if $permissions == null {
          error make {msg: "Permissions required for chmod operation"}
        }
        ["chmod" $permissions $path]
      }
      _ => {
        error make {msg: $"Unknown operation: ($operation)"}
      }
    }

    mut cmd_args = ["exec"]

    # Add resource type and name
    if $resource_type != "pod" {
      $cmd_args = ($cmd_args | append $"($resource_type)/($name)")
    } else {
      $cmd_args = ($cmd_args | append $name)
    }

    # Add namespace (always required)
    $cmd_args = ($cmd_args | append "--namespace" | append $namespace)

    # Add container (always required)
    $cmd_args = ($cmd_args | append "--container" | append $container)

    # Add command separator and file operation command
    $cmd_args = ($cmd_args | append "--")
    $cmd_args = ($cmd_args | append $file_command)

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "file_operation_result"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
        container: $container
      }
      operation: {
        type: $operation
        path: $path
        content_length: (if $content != null { $content | str length } else { null })
        permissions: $permissions
      }
      command: ($full_cmd | str join " ")
      output: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error performing ($operation) on ($path) in ($resource_type)/($name): ($error.msg)"
      suggestions: [
        "Verify path exists for read operations"
        "Check write permissions for write operations"
        "Ensure container has required tools (ls, cat, chmod, etc.)"
        "Verify directory exists for file operations"
      ]
    } | to json
  }
}