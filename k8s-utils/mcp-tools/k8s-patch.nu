#!/usr/bin/env nu

# Kubernetes resource patching tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "patch_strategic"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Apply strategic merge patch to resource - can modify resource configuration"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource to patch (e.g., deployment, pod, service)"
          }
          name: {
            type: "string"
            description: "Name of the resource to patch"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          patch: {
            type: "object"
            description: "Strategic merge patch data as JSON object"
          }
          patch_file: {
            type: "string"
            description: "Path to file containing patch data (alternative to patch)"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without applying changes"
            default: false
          }
          record: {
            type: "boolean"
            description: "Record the command in resource annotations"
            default: false
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "patch_merge"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Apply JSON merge patch to resource - can modify resource configuration"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource to patch"
          }
          name: {
            type: "string"
            description: "Name of the resource to patch"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          patch: {
            type: "object"
            description: "JSON merge patch data as JSON object"
          }
          patch_file: {
            type: "string"
            description: "Path to file containing patch data (alternative to patch)"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without applying changes"
            default: false
          }
          record: {
            type: "boolean"
            description: "Record the command in resource annotations"
            default: false
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "patch_json"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Apply JSON patch (RFC 6902) to resource - can modify resource configuration"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource to patch"
          }
          name: {
            type: "string"
            description: "Name of the resource to patch"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          patch: {
            type: "array"
            description: "JSON patch operations array (RFC 6902 format)"
            items: {
              type: "object"
              properties: {
                op: {
                  type: "string"
                  enum: ["add", "remove", "replace", "move", "copy", "test"]
                }
                path: {
                  type: "string"
                }
                value: {}
                from: {
                  type: "string"
                }
              }
            }
          }
          patch_file: {
            type: "string"
            description: "Path to file containing JSON patch operations"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without applying changes"
            default: false
          }
          record: {
            type: "boolean"
            description: "Record the command in resource annotations"
            default: false
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "patch_subresource"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Patch a subresource like status or scale - can modify resource state"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (e.g., deployment, pod)"
          }
          name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          subresource: {
            type: "string"
            description: "Subresource to patch (e.g., status, scale)"
            enum: ["status", "scale"]
          }
          patch: {
            type: "object"
            description: "Patch data for the subresource"
          }
          patch_type: {
            type: "string"
            description: "Type of patch to apply"
            enum: ["strategic", "merge", "json"]
            default: "strategic"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without applying changes"
            default: false
          }
        }
        required: ["resource_type", "name", "namespace", "subresource"]
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
    "patch_strategic" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let patch = $parsed_args.patch?
      let patch_file = $parsed_args.patch_file?
      let dry_run = $parsed_args.dry_run? | default false
      let record = $parsed_args.record? | default false

      patch_strategic $resource_type $name $namespace $patch $patch_file $dry_run $record
    }
    "patch_merge" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let patch = $parsed_args.patch?
      let patch_file = $parsed_args.patch_file?
      let dry_run = $parsed_args.dry_run? | default false
      let record = $parsed_args.record? | default false

      patch_merge $resource_type $name $namespace $patch $patch_file $dry_run $record
    }
    "patch_json" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let patch = $parsed_args.patch?
      let patch_file = $parsed_args.patch_file?
      let dry_run = $parsed_args.dry_run? | default false
      let record = $parsed_args.record? | default false

      patch_json $resource_type $name $namespace $patch $patch_file $dry_run $record
    }
    "patch_subresource" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let subresource = $parsed_args.subresource
      let patch = $parsed_args.patch?
      let patch_type = $parsed_args.patch_type? | default "strategic"
      let dry_run = $parsed_args.dry_run? | default false

      patch_subresource $resource_type $name $namespace $subresource $patch $patch_type $dry_run
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Apply strategic merge patch to resource
def patch_strategic [
  resource_type: string
  name: string
  namespace: string
  patch?: any
  patch_file?: string
  dry_run: bool = false
  record: bool = false
] {
  if $patch == null and $patch_file == null {
    return (
      {
        type: "error"
        message: "Must provide either patch data or patch_file"
      } | to json
    )
  }

  try {
    mut cmd_args = ["patch" $resource_type $name "--namespace" $namespace "--type" "strategic"]

    # Determine patch source
    if $patch_file != null {
      if not ($patch_file | path exists) {
        return (
          {
            type: "error"
            message: $"Patch file '($patch_file)' does not exist"
          } | to json
        )
      }
      $cmd_args = ($cmd_args | append "--patch-file" | append $patch_file)
    } else {
      let patch_json = $patch | to json
      $cmd_args = ($cmd_args | append "--patch" | append $patch_json)
    }

    # Add options
    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $record {
      $cmd_args = ($cmd_args | append "--record")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "patch_strategic_result"
      operation: (if $dry_run { "dry_run_patch" } else { "patch_strategic" })
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      patch_source: (if $patch_file != null { {type: "file" path: $patch_file} } else { {type: "data"} })
      options: {
        dry_run: $dry_run
        record: $record
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Strategic merge patch applied to ($resource_type) '($name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error applying strategic patch to ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to modify it"
        "Check patch syntax is valid for strategic merge"
        "Ensure patch fields are compatible with the resource schema"
        "Try with dry-run first to validate the patch"
        "Verify namespace is correct"
      ]
    } | to json
  }
}

# Apply JSON merge patch to resource
def patch_merge [
  resource_type: string
  name: string
  namespace: string
  patch?: any
  patch_file?: string
  dry_run: bool = false
  record: bool = false
] {
  if $patch == null and $patch_file == null {
    return (
      {
        type: "error"
        message: "Must provide either patch data or patch_file"
      } | to json
    )
  }

  try {
    mut cmd_args = ["patch" $resource_type $name "--namespace" $namespace "--type" "merge"]

    # Determine patch source
    if $patch_file != null {
      if not ($patch_file | path exists) {
        return (
          {
            type: "error"
            message: $"Patch file '($patch_file)' does not exist"
          } | to json
        )
      }
      $cmd_args = ($cmd_args | append "--patch-file" | append $patch_file)
    } else {
      let patch_json = $patch | to json
      $cmd_args = ($cmd_args | append "--patch" | append $patch_json)
    }

    # Add options
    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $record {
      $cmd_args = ($cmd_args | append "--record")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "patch_merge_result"
      operation: (if $dry_run { "dry_run_patch" } else { "patch_merge" })
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      patch_source: (if $patch_file != null { {type: "file" path: $patch_file} } else { {type: "data"} })
      options: {
        dry_run: $dry_run
        record: $record
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"JSON merge patch applied to ($resource_type) '($name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error applying merge patch to ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to modify it"
        "Check patch syntax is valid JSON"
        "Ensure patch follows JSON merge patch semantics"
        "Try with dry-run first to validate the patch"
        "Verify namespace is correct"
      ]
    } | to json
  }
}

# Apply JSON patch (RFC 6902) to resource
def patch_json [
  resource_type: string
  name: string
  namespace: string
  patch?: any
  patch_file?: string
  dry_run: bool = false
  record: bool = false
] {
  if $patch == null and $patch_file == null {
    return (
      {
        type: "error"
        message: "Must provide either patch operations or patch_file"
      } | to json
    )
  }

  try {
    mut cmd_args = ["patch" $resource_type $name "--namespace" $namespace "--type" "json"]

    # Determine patch source
    if $patch_file != null {
      if not ($patch_file | path exists) {
        return (
          {
            type: "error"
            message: $"Patch file '($patch_file)' does not exist"
          } | to json
        )
      }
      $cmd_args = ($cmd_args | append "--patch-file" | append $patch_file)
    } else {
      let patch_json = $patch | to json
      $cmd_args = ($cmd_args | append "--patch" | append $patch_json)
    }

    # Add options
    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $record {
      $cmd_args = ($cmd_args | append "--record")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "patch_json_result"
      operation: (if $dry_run { "dry_run_patch" } else { "patch_json" })
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      patch_source: (if $patch_file != null { {type: "file" path: $patch_file} } else { {type: "operations"} })
      options: {
        dry_run: $dry_run
        record: $record
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"JSON patch (RFC 6902) applied to ($resource_type) '($name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error applying JSON patch to ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      suggestions: [
        "Verify the resource exists and you have permission to modify it"
        "Check patch operations follow RFC 6902 format"
        "Ensure all patch paths exist or are valid for the operation"
        "Validate patch operations syntax (op, path, value, from)"
        "Try with dry-run first to validate the patch"
        "Verify namespace is correct"
      ]
    } | to json
  }
}

# Patch a subresource like status or scale
def patch_subresource [
  resource_type: string
  name: string
  namespace: string
  subresource: string
  patch?: any
  patch_type: string = "strategic"
  dry_run: bool = false
] {
  if $patch == null {
    return (
      {
        type: "error"
        message: "Must provide patch data for subresource"
      } | to json
    )
  }

  try {
    let patch_json = $patch | to json
    mut cmd_args = ["patch" $resource_type $name "--namespace" $namespace "--subresource" $subresource "--type" $patch_type "--patch" $patch_json]

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "patch_subresource_result"
      operation: (if $dry_run { "dry_run_patch_subresource" } else { "patch_subresource" })
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
        subresource: $subresource
      }
      patch_type: $patch_type
      options: {
        dry_run: $dry_run
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Subresource '($subresource)' patched on ($resource_type) '($name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error patching subresource '($subresource)' on ($resource_type) '($name)': ($error.msg)"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
        subresource: $subresource
      }
      suggestions: [
        "Verify the resource exists and supports the subresource"
        "Check you have permission to modify the subresource"
        "Ensure patch data is compatible with the subresource schema"
        "Verify the subresource name is correct (status, scale)"
        "Try with dry-run first to validate the patch"
      ]
    } | to json
  }
}