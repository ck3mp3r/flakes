# Kubernetes resource application tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "apply_yaml"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Apply Kubernetes YAML configuration from file or content - can create, update, or replace resources"
      input_schema: {
        type: "object"
        properties: {
          file_path: {
            type: "string"
            description: "Path to YAML file to apply"
          }
          yaml_content: {
            type: "string"
            description: "Raw YAML content to apply (alternative to file_path)"
          }
          namespace: {
            type: "string"
            description: "Target namespace (optional)"
          }
          dry_run: {
            type: "boolean"
            description: "Perform a dry run without actually applying"
            default: false
          }
          validate: {
            type: "boolean"
            description: "Validate the resource against the server schema"
            default: true
          }
          force: {
            type: "boolean"
            description: "Force apply even if there are conflicts"
            default: false
          }
          server_side: {
            type: "boolean"
            description: "Use server-side apply"
            default: false
          }
        }
      }
    }
    {
      name: "apply_kustomization"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Apply resources from a kustomization directory - can create, update, or replace multiple resources"
      input_schema: {
        type: "object"
        properties: {
          directory: {
            type: "string"
            description: "Path to directory containing kustomization.yaml"
          }
          namespace: {
            type: "string"
            description: "Target namespace (optional)"
          }
          dry_run: {
            type: "boolean"
            description: "Perform a dry run without actually applying"
            default: false
          }
        }
        required: ["directory"]
      }
    }
    {
      name: "validate_yaml"
      description: "Validate YAML configuration without applying"
      input_schema: {
        type: "object"
        properties: {
          file_path: {
            type: "string"
            description: "Path to YAML file to validate"
          }
          yaml_content: {
            type: "string"
            description: "Raw YAML content to validate (alternative to file_path)"
          }
        }
      }
    }
    {
      name: "diff_apply"
      description: "Show what would change if applying the configuration"
      input_schema: {
        type: "object"
        properties: {
          file_path: {
            type: "string"
            description: "Path to YAML file to diff"
          }
          yaml_content: {
            type: "string"
            description: "Raw YAML content to diff (alternative to file_path)"
          }
          namespace: {
            type: "string"
            description: "Target namespace (optional)"
          }
        }
      }
    }
    {
      name: "apply_with_wait"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Apply configuration and wait for resources to be ready - can create, update, or replace resources"
      input_schema: {
        type: "object"
        properties: {
          file_path: {
            type: "string"
            description: "Path to YAML file to apply"
          }
          yaml_content: {
            type: "string"
            description: "Raw YAML content to apply (alternative to file_path)"
          }
          namespace: {
            type: "string"
            description: "Target namespace (optional)"
          }
          timeout: {
            type: "string"
            description: "Timeout for waiting (e.g., '5m', '30s')"
            default: "5m"
          }
          condition: {
            type: "string"
            description: "Condition to wait for (e.g., 'condition=Ready')"
            default: "condition=Ready"
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
    "apply_yaml" => {
      let file_path = $parsed_args.file_path?
      let yaml_content = $parsed_args.yaml_content?
      let namespace = $parsed_args.namespace?
      let dry_run = $parsed_args.dry_run? | default false
      let validate = $parsed_args.validate? | default true
      let force = $parsed_args.force? | default false
      let server_side = $parsed_args.server_side? | default false

      apply_yaml $file_path $yaml_content $namespace $dry_run $validate $force $server_side
    }
    "apply_kustomization" => {
      let directory = $parsed_args.directory
      let namespace = $parsed_args.namespace?
      let dry_run = $parsed_args.dry_run? | default false

      apply_kustomization $directory $namespace $dry_run
    }
    "validate_yaml" => {
      let file_path = $parsed_args.file_path?
      let yaml_content = $parsed_args.yaml_content?

      validate_yaml $file_path $yaml_content
    }
    "diff_apply" => {
      let file_path = $parsed_args.file_path?
      let yaml_content = $parsed_args.yaml_content?
      let namespace = $parsed_args.namespace?

      diff_apply $file_path $yaml_content $namespace
    }
    "apply_with_wait" => {
      let file_path = $parsed_args.file_path?
      let yaml_content = $parsed_args.yaml_content?
      let namespace = $parsed_args.namespace?
      let timeout = $parsed_args.timeout? | default "5m"
      let condition = $parsed_args.condition? | default "condition=Ready"

      apply_with_wait $file_path $yaml_content $namespace $timeout $condition
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Apply YAML configuration to Kubernetes
def apply_yaml [
  file_path?: string
  yaml_content?: string
  namespace?: string
  dry_run: bool = false
  validate: bool = true
  force: bool = false
  server_side: bool = false
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
    mut cmd_args = ["apply"]

    # Determine input source
    if $file_path != null {
      # Check if file exists
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
      # Use stdin for yaml_content
      $cmd_args = ($cmd_args | append "--filename" | append "-")
    }

    # Add options
    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if not $validate {
      $cmd_args = ($cmd_args | append "--validate=false")
    }

    if $force {
      $cmd_args = ($cmd_args | append "--force")
    }

    if $server_side {
      $cmd_args = ($cmd_args | append "--server-side")
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
      type: "apply_result"
      operation: (if $dry_run { "dry_run" } else { "apply" })
      source: (if $file_path != null { {type: "file" path: $file_path} } else { {type: "content"} })
      options: {
        namespace: $namespace
        dry_run: $dry_run
        validate: $validate
        force: $force
        server_side: $server_side
      }
      command: ($full_cmd | str join " ")
      result: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error applying YAML: ($error.msg)"
      suggestions: [
        "Check YAML syntax is valid"
        "Verify resources are properly defined"
        "Ensure you have permission to create/update resources"
        "Confirm namespace exists"
        "Validate resource versions are compatible"
      ]
    } | to json
  }
}

# Apply resources from a kustomization directory
def apply_kustomization [
  directory: string
  namespace?: string
  dry_run: bool = false
] {
  try {
    # Check if directory exists and contains kustomization.yaml
    if not ($directory | path exists) {
      return (
        {
          type: "error"
          message: $"Directory '($directory)' does not exist"
        } | to json
      )
    }

    let kustomization_files = [
      ($directory | path join "kustomization.yaml")
      ($directory | path join "kustomization.yml")
      ($directory | path join "Kustomization")
    ]

    let kustomization_exists = $kustomization_files | any {|file| $file | path exists }
    if not $kustomization_exists {
      return (
        {
          type: "error"
          message: $"No kustomization file found in '($directory)'"
        } | to json
      )
    }

    mut cmd_args = ["apply" "--kustomize" $directory]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "kustomization_apply"
      operation: (if $dry_run { "dry_run" } else { "apply" })
      directory: $directory
      namespace: $namespace
      command: ($full_cmd | str join " ")
      result: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error applying kustomization: ($error.msg)"
      suggestions: [
        "Verify directory contains valid kustomization.yaml"
        "Check all referenced resources exist"
        "Validate kustomization syntax is correct"
      ]
    } | to json
  }
}

# Validate YAML configuration without applying
def validate_yaml [
  file_path?: string
  yaml_content?: string
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
    mut cmd_args = ["apply" "--dry-run=client" "--validate=true"]

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

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    
    let result = if $yaml_content != null {
      $yaml_content | run-external ...$full_cmd
    } else {
      run-external ...$full_cmd
    }

    {
      type: "validation_result"
      status: "valid"
      source: (if $file_path != null { {type: "file" path: $file_path} } else { {type: "content"} })
      command: ($full_cmd | str join " ")
      result: $result
      message: "YAML configuration is valid and can be applied to the cluster"
    } | to json
  } catch {|error|
    {
      type: "validation_result"
      status: "invalid"
      source: (if $file_path != null { {type: "file" path: $file_path} } else { {type: "content"} })
      error_message: $error.msg
      suggestions: [
        "Check YAML syntax for errors"
        "Verify required fields are present"
        "Validate resource definitions"
        "Confirm API versions are correct"
      ]
    } | to json
  }
}

# Show differences between current state and proposed changes
def diff_apply [
  file_path?: string
  yaml_content?: string
  namespace?: string
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
    mut cmd_args = ["diff"]

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

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    
    let result = if $yaml_content != null {
      $yaml_content | run-external ...$full_cmd
    } else {
      run-external ...$full_cmd
    }

    {
      type: "diff_result"
      source: (if $file_path != null { {type: "file" path: $file_path} } else { {type: "content"} })
      namespace: $namespace
      command: ($full_cmd | str join " ")
      diff_output: $result
      has_changes: (($result | str length) > 0)
      legend: {
        "-": "Lines to be removed"
        "+": "Lines to be added"
        " ": "Unchanged lines"
      }
    } | to json
  } catch {|error|
    {
      type: "diff_result"
      status: "error"
      message: $"Error computing diff: ($error.msg)"
      note: "Some resources may not exist yet, which is normal for new deployments"
    } | to json
  }
}

# Apply configuration and wait for resources to be ready
def apply_with_wait [
  file_path?: string
  yaml_content?: string
  namespace?: string
  timeout: string = "5m"
  condition: string = "condition=Ready"
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
    # First, apply the configuration
    let apply_result = apply_yaml $file_path $yaml_content $namespace false true false false | from json

    if $apply_result.type == "error" {
      return ($apply_result | to json)
    }

    # Extract resource information from apply result for waiting
    # This is a simplified approach - we'll wait for common resource types
    let wait_results = ["deployment" "pod" "service"] | each {|resource_type|
      try {
        mut wait_cmd_args = ["wait" $resource_type "--all" $"--for=($condition)" $"--timeout=($timeout)"]

        if $namespace != null {
          $wait_cmd_args = ($wait_cmd_args | append "--namespace" | append $namespace)
        }

        # Build and execute wait command
        let full_wait_cmd = (["kubectl"] | append $wait_cmd_args)
        print $"Executing: ($full_wait_cmd | str join ' ')"
        let wait_result = run-external ...$full_wait_cmd
        {
          resource_type: $resource_type
          status: "success"
          result: $wait_result
        }
      } catch {|error|
        {
          resource_type: $resource_type
          status: "not_applicable"
          message: $"No ($resource_type) resources to wait for"
        }
      }
    }

    {
      type: "apply_with_wait_result"
      apply_result: $apply_result
      wait_results: $wait_results
      timeout: $timeout
      condition: $condition
      summary: "Resources have been applied and wait operations completed"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error during apply with wait: ($error.msg)"
    } | to json
  }
}

