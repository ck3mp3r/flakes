#!/usr/bin/env nu

# Kubernetes resource deletion tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "delete_resource"
      description: "[MODIFIES CLUSTER] [DESTRUCTIVE] Delete a specific Kubernetes resource by name and type"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource to delete (e.g., pod, deployment, service)"
          }
          name: {
            type: "string"
            description: "Name of the resource to delete"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          grace_period: {
            type: "integer"
            description: "Grace period in seconds for pod termination"
          }
          force: {
            type: "boolean"
            description: "Force delete immediately (bypasses graceful deletion)"
            default: false
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "delete_by_selector"
      description: "[MODIFIES CLUSTER] [HIGHLY DESTRUCTIVE] Delete multiple resources matching label selector"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource to delete (e.g., pod, deployment)"
          }
          selector: {
            type: "string"
            description: "Label selector (e.g., 'app=nginx,env=prod')"
          }
          namespace: {
            type: "string"
            description: "Namespace to delete from (mandatory for safety)"
          }
          all_namespaces: {
            type: "boolean"
            description: "Delete from all namespaces (use with extreme caution)"
            default: false
          }
          dry_run: {
            type: "boolean"
            description: "Show what would be deleted without actually deleting"
            default: false
          }
          wait: {
            type: "boolean"
            description: "Wait for all resources to be fully deleted"
            default: false
          }
          timeout: {
            type: "string"
            description: "Timeout for wait operation"
            default: "1m"
          }
        }
        required: ["resource_type", "selector", "namespace"]
      }
    }
    {
      name: "delete_by_file"
      description: "[MODIFIES CLUSTER] [DESTRUCTIVE] Delete resources defined in YAML file"
      input_schema: {
        type: "object"
        properties: {
          file_path: {
            type: "string"
            description: "Path to YAML file containing resources to delete"
          }
          yaml_content: {
            type: "string"
            description: "Raw YAML content defining resources to delete (alternative to file_path)"
          }
          namespace: {
            type: "string"
            description: "Override namespace for resources (optional)"
          }
          wait: {
            type: "boolean"
            description: "Wait for all resources to be fully deleted"
            default: false
          }
          timeout: {
            type: "string"
            description: "Timeout for wait operation"
            default: "1m"
          }
          ignore_not_found: {
            type: "boolean"
            description: "Ignore errors when resources don't exist"
            default: true
          }
        }
      }
    }
    {
      name: "delete_all_in_namespace"
      description: "[MODIFIES CLUSTER] [HIGHLY DESTRUCTIVE] Delete all resources of a specific type in namespace"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource to delete (e.g., pods, deployments)"
          }
          namespace: {
            type: "string"
            description: "Namespace to delete from (mandatory for safety)"
          }
          dry_run: {
            type: "boolean"
            description: "Show what would be deleted without actually deleting"
            default: false
          }
          wait: {
            type: "boolean"
            description: "Wait for all resources to be fully deleted"
            default: false
          }
          timeout: {
            type: "string"
            description: "Timeout for wait operation"
            default: "2m"
          }
        }
        required: ["resource_type", "namespace"]
      }
    }
    {
      name: "delete_with_cascade"
      description: "[MODIFIES CLUSTER] [HIGHLY DESTRUCTIVE] Delete resource with specific cascade policy"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource to delete"
          }
          name: {
            type: "string"
            description: "Name of the resource to delete"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (mandatory for safety)"
          }
          cascade: {
            type: "string"
            description: "Cascade deletion policy"
            enum: ["background", "orphan", "foreground"]
            default: "background"
          }
          wait: {
            type: "boolean"
            description: "Wait for the resource to be fully deleted"
            default: false
          }
          timeout: {
            type: "string"
            description: "Timeout for wait operation"
            default: "1m"
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
  args: string = "{}" # JSON arguments for the tool
] {
  let parsed_args = $args | from json

  match $tool_name {
    "delete_resource" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let wait = $parsed_args.wait? | default false
      let timeout = $parsed_args.timeout? | default "30s"
      let grace_period = $parsed_args.grace_period?
      let force = $parsed_args.force? | default false

      delete_resource $resource_type $name $namespace $wait $timeout $grace_period $force
    }
    "delete_by_selector" => {
      let resource_type = $parsed_args.resource_type
      let selector = $parsed_args.selector
      let namespace = $parsed_args.namespace
      let all_namespaces = $parsed_args.all_namespaces? | default false
      let dry_run = $parsed_args.dry_run? | default false
      let wait = $parsed_args.wait? | default false
      let timeout = $parsed_args.timeout? | default "1m"

      delete_by_selector $resource_type $selector $namespace $all_namespaces $dry_run $wait $timeout
    }
    "delete_by_file" => {
      let file_path = $parsed_args.file_path?
      let yaml_content = $parsed_args.yaml_content?
      let namespace = $parsed_args.namespace?
      let wait = $parsed_args.wait? | default false
      let timeout = $parsed_args.timeout? | default "1m"
      let ignore_not_found = $parsed_args.ignore_not_found? | default true

      delete_by_file $file_path $yaml_content $namespace $wait $timeout $ignore_not_found
    }
    "delete_all_in_namespace" => {
      let resource_type = $parsed_args.resource_type
      let namespace = $parsed_args.namespace
      let dry_run = $parsed_args.dry_run? | default false
      let wait = $parsed_args.wait? | default false
      let timeout = $parsed_args.timeout? | default "2m"

      delete_all_in_namespace $resource_type $namespace $dry_run $wait $timeout
    }
    "delete_with_cascade" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let cascade = $parsed_args.cascade? | default "background"
      let wait = $parsed_args.wait? | default false
      let timeout = $parsed_args.timeout? | default "1m"

      delete_with_cascade $resource_type $name $namespace $cascade $wait $timeout
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Delete a specific resource by name and type
def delete_resource [
  resource_type: string
  name: string
  namespace: string
  wait: bool = false
  timeout: string = "30s"
  grace_period?: int
  force: bool = false
] {
  try {
    mut cmd_args = ["delete" $resource_type $name "--namespace" $namespace]

    if $grace_period != null {
      $cmd_args = ($cmd_args | append $"--grace-period=($grace_period)")
    }

    if $force {
      $cmd_args = ($cmd_args | append "--force")
    }

    if $wait {
      $cmd_args = ($cmd_args | append "--wait=true" | append $"--timeout=($timeout)")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "delete_result"
      operation: "delete_resource"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      options: {
        wait: $wait
        timeout: $timeout
        grace_period: $grace_period
        force: $force
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Successfully deleted ($resource_type) '($name)' in namespace '($namespace)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to delete it"
        "Check if the resource is being used by other resources"
        "Try using --force flag for stuck resources"
        "Ensure the namespace is correct"
      ]
    } | to json
  }
}

# Delete multiple resources by label selector
def delete_by_selector [
  resource_type: string
  selector: string
  namespace: string
  all_namespaces: bool = false
  dry_run: bool = false
  wait: bool = false
  timeout: string = "1m"
] {
  try {
    mut cmd_args = ["delete" $resource_type "--selector" $selector]

    if $all_namespaces {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    } else {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $wait {
      $cmd_args = ($cmd_args | append "--wait=true" | append $"--timeout=($timeout)")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "delete_by_selector_result"
      operation: (if $dry_run { "dry_run_delete" } else { "delete_by_selector" })
      resource_type: $resource_type
      selector: $selector
      scope: (if $all_namespaces { "all_namespaces" } else { $namespace })
      options: {
        dry_run: $dry_run
        wait: $wait
        timeout: $timeout
      }
      command: ($full_cmd | str join " ")
      result: $result
      warning: "Multiple resources may have been affected by this operation"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting resources with selector '($selector)': ($error.msg)"
      selector: $selector
      resource_type: $resource_type
      suggestions: [
        "Verify the label selector syntax is correct"
        "Check that resources with this selector exist"
        "Use dry-run first to see what would be deleted"
        "Ensure you have permission to delete the resources"
      ]
    } | to json
  }
}

# Delete resources defined in a YAML file
def delete_by_file [
  file_path?: string
  yaml_content?: string
  namespace?: string
  wait: bool = false
  timeout: string = "1m"
  ignore_not_found: bool = true
] {
  if $file_path == null and $yaml_content == null {
    return (
      {
        type: "error"
        message: "Must provide either file_path or yaml_content"
      } | to json
    )
  }

  try {
    mut cmd_args = ["delete"]

    # Determine input source
    if $file_path != null {
      if not ($file_path | path exists) {
        return (
          {
            type: "error"
            message: $"File '($file_path)' does not exist"
          } | to json
        )
      }
      $cmd_args = ($cmd_args | append "--filename" | append $file_path)
    } else {
      $cmd_args = ($cmd_args | append "--filename" | append "-")
    }

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $ignore_not_found {
      $cmd_args = ($cmd_args | append "--ignore-not-found=true")
    }

    if $wait {
      $cmd_args = ($cmd_args | append "--wait=true" | append $"--timeout=($timeout)")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    
    let result = if $yaml_content != null {
      $yaml_content | run-external ...$full_cmd
    } else {
      run-external ...$full_cmd
    }

    {
      type: "delete_by_file_result"
      operation: "delete_by_file"
      source: (if $file_path != null { {type: "file" path: $file_path} } else { {type: "content"} })
      namespace: $namespace
      options: {
        wait: $wait
        timeout: $timeout
        ignore_not_found: $ignore_not_found
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: "Resources from file have been deleted"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting resources from file: ($error.msg)"
      suggestions: [
        "Verify the YAML file syntax is correct"
        "Check that the resources exist in the cluster"
        "Ensure you have permission to delete the resources"
        "Try with --ignore-not-found=true for missing resources"
      ]
    } | to json
  }
}

# Delete all resources of a type in namespace
def delete_all_in_namespace [
  resource_type: string
  namespace: string
  dry_run: bool = false
  wait: bool = false
  timeout: string = "2m"
] {
  try {
    mut cmd_args = ["delete" $resource_type "--all" "--namespace" $namespace]

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $wait {
      $cmd_args = ($cmd_args | append "--wait=true" | append $"--timeout=($timeout)")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "delete_all_result"
      operation: (if $dry_run { "dry_run_delete_all" } else { "delete_all" })
      resource_type: $resource_type
      namespace: $namespace
      options: {
        dry_run: $dry_run
        wait: $wait
        timeout: $timeout
      }
      command: ($full_cmd | str join " ")
      result: $result
      warning: $"ALL ($resource_type) resources in namespace '($namespace)' have been affected"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting all ($resource_type) in namespace '($namespace)': ($error.msg)"
      suggestions: [
        "Verify you have permission to delete resources in this namespace"
        "Check that the resource type exists and is valid"
        "Use dry-run first to see what would be deleted"
        "Ensure the namespace exists"
      ]
    } | to json
  }
}

# Delete resource with specific cascade policy
def delete_with_cascade [
  resource_type: string
  name: string
  namespace: string
  cascade: string = "background"
  wait: bool = false
  timeout: string = "1m"
] {
  try {
    mut cmd_args = ["delete" $resource_type $name "--namespace" $namespace $"--cascade=($cascade)"]

    if $wait {
      $cmd_args = ($cmd_args | append "--wait=true" | append $"--timeout=($timeout)")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "delete_cascade_result"
      operation: "delete_with_cascade"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      cascade_policy: $cascade
      options: {
        wait: $wait
        timeout: $timeout
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Successfully deleted ($resource_type) '($name)' with cascade policy '($cascade)'"
      cascade_explanation: (match $cascade {
        "background" => "Dependent objects will be deleted in the background"
        "foreground" => "Dependent objects will be deleted before the owner"
        "orphan" => "Dependent objects will be orphaned (not deleted)"
        _ => "Custom cascade policy applied"
      })
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting ($resource_type) '($name)' with cascade '($cascade)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to delete it"
        "Check if the cascade policy is valid"
        "Try a different cascade policy if needed"
        "Use --wait=false if the operation is taking too long"
      ]
    } | to json
  }
}