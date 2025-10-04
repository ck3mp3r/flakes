#!/usr/bin/env nu

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
      description: "[MODIFIES CLUSTER] Apply Kubernetes YAML configuration from file or content"
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
      description: "[MODIFIES CLUSTER] Apply resources from a kustomization directory"
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
      description: "[MODIFIES CLUSTER] Apply configuration and wait for resources to be ready"
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
      let file_path = if "file_path" in $parsed_args { $parsed_args | get file_path } else { null }
      let yaml_content = if "yaml_content" in $parsed_args { $parsed_args | get yaml_content } else { null }
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let dry_run = if "dry_run" in $parsed_args { $parsed_args | get dry_run } else { false }
      let validate = if "validate" in $parsed_args { $parsed_args | get validate } else { true }
      let force = if "force" in $parsed_args { $parsed_args | get force } else { false }
      let server_side = if "server_side" in $parsed_args { $parsed_args | get server_side } else { false }
      
      apply_yaml $file_path $yaml_content $namespace $dry_run $validate $force $server_side
    }
    "apply_kustomization" => {
      let directory = $parsed_args | get directory
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let dry_run = if "dry_run" in $parsed_args { $parsed_args | get dry_run } else { false }
      
      apply_kustomization $directory $namespace $dry_run
    }
    "validate_yaml" => {
      let file_path = if "file_path" in $parsed_args { $parsed_args | get file_path } else { null }
      let yaml_content = if "yaml_content" in $parsed_args { $parsed_args | get yaml_content } else { null }
      
      validate_yaml $file_path $yaml_content
    }
    "diff_apply" => {
      let file_path = if "file_path" in $parsed_args { $parsed_args | get file_path } else { null }
      let yaml_content = if "yaml_content" in $parsed_args { $parsed_args | get yaml_content } else { null }
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      
      diff_apply $file_path $yaml_content $namespace
    }
    "apply_with_wait" => {
      let file_path = if "file_path" in $parsed_args { $parsed_args | get file_path } else { null }
      let yaml_content = if "yaml_content" in $parsed_args { $parsed_args | get yaml_content } else { null }
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let timeout = if "timeout" in $parsed_args { $parsed_args | get timeout } else { "5m" }
      let condition = if "condition" in $parsed_args { $parsed_args | get condition } else { "condition=Ready" }
      
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
    return "Error: Must provide either file_path or yaml_content"
  }
  
  try {
    mut cmd = ["kubectl", "apply"]
    
    # Determine input source
    if $file_path != null {
      # Check if file exists
      if not ($file_path | path exists) {
        return $"Error: File '($file_path)' does not exist"
      }
      $cmd = ($cmd | append "--filename" | append $file_path)
    } else {
      # Use stdin for yaml_content
      $cmd = ($cmd | append "--filename" | append "-")
    }
    
    # Add options
    if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    if $dry_run {
      $cmd = ($cmd | append "--dry-run=client")
    }
    
    if not $validate {
      $cmd = ($cmd | append "--validate=false")
    }
    
    if $force {
      $cmd = ($cmd | append "--force")
    }
    
    if $server_side {
      $cmd = ($cmd | append "--server-side")
    }
    
    # Execute command
    let result = if $yaml_content != null {
      $yaml_content | run-external $cmd.0 ...$cmd.1..
    } else {
      run-external $cmd.0 ...$cmd.1..
    }
    
    let operation = if $dry_run { "Dry Run" } else { "Apply" }
    let source = if $file_path != null { $file_path } else { "YAML content" }
    
    $"Kubernetes ($operation) Result - ($source):
($result)

Command executed: ($cmd | str join ' ')
Options used:
- Dry run: ($dry_run)
- Validate: ($validate)
- Force: ($force)
- Server-side: ($server_side)"
  } catch { |e|
    $"Error applying YAML: ($e.msg)
Please check:
- YAML syntax is valid
- Resources are properly defined
- You have permission to create/update resources
- Namespace exists (if specified)
- Resource versions are compatible"
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
      return $"Error: Directory '($directory)' does not exist"
    }
    
    let kustomization_files = [
      ($directory | path join "kustomization.yaml"),
      ($directory | path join "kustomization.yml"),
      ($directory | path join "Kustomization")
    ]
    
    let kustomization_exists = $kustomization_files | any { |file| $file | path exists }
    if not $kustomization_exists {
      return $"Error: No kustomization file found in '($directory)'"
    }
    
    mut cmd = ["kubectl", "apply", "--kustomize", $directory]
    
    if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    if $dry_run {
      $cmd = ($cmd | append "--dry-run=client")
    }
    
    let result = run-external $cmd.0 ...$cmd.1..
    
    let operation = if $dry_run { "Dry Run" } else { "Apply" }
    
    $"Kubernetes Kustomization ($operation) Result - ($directory):
($result)

Command executed: ($cmd | str join ' ')"
  } catch { |e|
    $"Error applying kustomization: ($e.msg)
Please check:
- Directory contains valid kustomization.yaml
- All referenced resources exist
- Kustomization syntax is correct"
  }
}

# Validate YAML configuration without applying
def validate_yaml [
  file_path?: string
  yaml_content?: string
] {
  if $file_path == null and $yaml_content == null {
    return "Error: Must provide either file_path or yaml_content"
  }
  
  try {
    mut cmd = ["kubectl", "apply", "--dry-run=client", "--validate=true"]
    
    if $file_path != null {
      if not ($file_path | path exists) {
        return $"Error: File '($file_path)' does not exist"
      }
      $cmd = ($cmd | append "--filename" | append $file_path)
    } else {
      $cmd = ($cmd | append "--filename" | append "-")
    }
    
    let result = if $yaml_content != null {
      $yaml_content | run-external $cmd.0 ...$cmd.1..
    } else {
      run-external $cmd.0 ...$cmd.1..
    }
    
    let source = if $file_path != null { $file_path } else { "YAML content" }
    
    $"✅ Validation Successful - ($source):
($result)

The YAML configuration is valid and can be applied to the cluster."
  } catch { |e|
    let source = if $file_path != null { $file_path } else { "YAML content" }
    $"❌ Validation Failed - ($source):
($e.msg)

Common issues:
- Invalid YAML syntax
- Missing required fields
- Invalid resource definitions
- Incorrect API versions"
  }
}

# Show differences between current state and proposed changes
def diff_apply [
  file_path?: string
  yaml_content?: string
  namespace?: string
] {
  if $file_path == null and $yaml_content == null {
    return "Error: Must provide either file_path or yaml_content"
  }
  
  try {
    mut cmd = ["kubectl", "diff"]
    
    if $file_path != null {
      if not ($file_path | path exists) {
        return $"Error: File '($file_path)' does not exist"
      }
      $cmd = ($cmd | append "--filename" | append $file_path)
    } else {
      $cmd = ($cmd | append "--filename" | append "-")
    }
    
    if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    let result = if $yaml_content != null {
      $yaml_content | run-external $cmd.0 ...$cmd.1..
    } else {
      run-external $cmd.0 ...$cmd.1..
    }
    
    let source = if $file_path != null { $file_path } else { "YAML content" }
    
    if ($result | str length) == 0 {
      $"No differences found - ($source):
The configuration matches the current cluster state."
    } else {
      $"Configuration Differences - ($source):
($result)

Legend:
- Lines starting with '-' will be removed
- Lines starting with '+' will be added
- Lines starting with ' ' (space) remain unchanged"
    }
  } catch { |e|
    $"Error computing diff: ($e.msg)
Note: Some resources may not exist yet, which is normal for new deployments."
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
    return "Error: Must provide either file_path or yaml_content"
  }
  
  try {
    # First, apply the configuration
    let apply_result = apply_yaml $file_path $yaml_content $namespace false true false false
    
    # Extract resource names from apply result for waiting
    # This is a simplified approach - in practice, you might want to parse the output more carefully
    print $apply_result
    
    # Try to wait for common resource types
    let resource_types = ["deployment", "pod", "service"]
    
    for resource_type in $resource_types {
      try {
        mut wait_cmd = ["kubectl", "wait", $resource_type, "--all", $"--for=($condition)", $"--timeout=($timeout)"]
        
        if $namespace != null {
          $wait_cmd = ($wait_cmd | append "--namespace" | append $namespace)
        }
        
        let wait_result = run-external $wait_cmd.0 ...$wait_cmd.1..
        print $"Wait result for ($resource_type): ($wait_result)"
      } catch {
        # Resource type might not exist or no resources of this type, continue
      }
    }
    
    $"✅ Apply and Wait Completed
Resources have been applied and are ready (or timeout reached).
Timeout: ($timeout)
Condition: ($condition)"
  } catch { |e|
    $"Error during apply with wait: ($e.msg)"
  }
}