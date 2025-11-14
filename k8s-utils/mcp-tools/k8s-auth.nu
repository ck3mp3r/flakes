# Kubernetes authorization and authentication tool for nu-mcp

use nu-mcp-lib *

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "auth_can_i"
      description: "Check whether an action is allowed for current user or specified user/group"
      input_schema: {
        type: "object"
        properties: {
          verb: {
            type: "string"
            description: "Kubernetes verb to check (get, list, create, update, patch, delete, etc.)"
          }
          resource: {
            type: "string"
            description: "Resource to check permissions for (pods, deployments, services, etc.)"
          }
          resource_name: {
            type: "string"
            description: "Specific resource name to check (optional)"
          }
          namespace: {
            type: "string"
            description: "Namespace to check permissions in (optional - checks cluster-wide if not specified)"
          }
          subresource: {
            type: "string"
            description: "Subresource to check (e.g., status, scale, log)"
          }
          as_user: {
            type: "string"
            description: "Check permissions as a different user"
          }
          as_group: {
            type: "array"
            items: {type: "string"}
            description: "Check permissions as member of specified groups"
          }
          all_namespaces: {
            type: "boolean"
            description: "Check permissions across all namespaces"
            default: false
          }
          quiet: {
            type: "boolean"
            description: "Only return yes/no without explanation"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["verb", "resource"]
      }
    }
    {
      name: "auth_whoami"
      description: "Display information about current user context and authentication"
      input_schema: {
        type: "object"
        properties: {
          output: {
            type: "string"
            description: "Output format"
            enum: ["json", "yaml", "wide"]
            default: "wide"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "auth_reconcile"
      description: "[MODIFIES CLUSTER] Reconcile RBAC resources from file or directory"
      input_schema: {
        type: "object"
        properties: {
          file_path: {
            type: "string"
            description: "Path to RBAC YAML file or directory"
          }
          namespace: {
            type: "string"
            description: "Namespace to reconcile RBAC in (mandatory for safety)"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without making changes"
            default: false
          }
          remove_extra_permissions: {
            type: "boolean"
            description: "Remove permissions not specified in the file"
            default: false
          }
          remove_extra_subjects: {
            type: "boolean"
            description: "Remove subjects not specified in the file"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["file_path", "namespace"]
      }
    }
    {
      name: "auth_can_i_list"
      description: "List all allowed actions for current user in specified namespace or cluster-wide"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to check permissions in (optional - checks cluster-wide if not specified)"
          }
          as_user: {
            type: "string"
            description: "Check permissions as a different user"
          }
          as_group: {
            type: "array"
            items: {type: "string"}
            description: "Check permissions as member of specified groups"
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
    "auth_can_i" => {
      let verb = $parsed_args.verb
      let resource = $parsed_args.resource
      let resource_name = $parsed_args.resource_name?
      let namespace = $parsed_args.namespace?
      let subresource = $parsed_args.subresource?
      let as_user = $parsed_args.as_user?
      let as_group = $parsed_args.as_group?
      let all_namespaces = $parsed_args.all_namespaces? | default false
      let quiet = $parsed_args.quiet? | default false

      let delegate_to = $parsed_args.delegate_to?
      auth_can_i $verb $resource $resource_name $namespace $subresource $as_user $as_group $all_namespaces $quiet $delegate_to
    }
    "auth_whoami" => {
      let output = $parsed_args.output? | default "wide"
      let delegate_to = $parsed_args.delegate_to?
      auth_whoami $output $delegate_to
    }
    "auth_reconcile" => {
      let file_path = $parsed_args.file_path
      let namespace = $parsed_args.namespace
      let dry_run = $parsed_args.dry_run? | default false
      let remove_extra_permissions = $parsed_args.remove_extra_permissions? | default false
      let remove_extra_subjects = $parsed_args.remove_extra_subjects? | default false

      let delegate_to = $parsed_args.delegate_to?
      auth_reconcile $file_path $namespace $dry_run $remove_extra_permissions $remove_extra_subjects $delegate_to
    }
    "auth_can_i_list" => {
      let namespace = $parsed_args.namespace?
      let as_user = $parsed_args.as_user?
      let as_group = $parsed_args.as_group?

      let delegate_to = $parsed_args.delegate_to?
      auth_can_i_list $namespace $as_user $as_group $delegate_to
    }
    _ => {
      result [(text $"Unknown tool: ($tool_name)")] --error=true | to json
    }
  }
}

# Check if an action is allowed
def auth_can_i [
  verb: string
  resource: string
  resource_name?: string
  namespace?: string
  subresource?: string
  as_user?: string
  as_group?: any
  all_namespaces: bool = false
  quiet: bool = false
  delegate_to?: string
] {
  try {
    mut cmd_args = ["auth" "can-i" $verb $resource]

    if $resource_name != null {
      $cmd_args = ($cmd_args | append $resource_name)
    }

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $subresource != null {
      $cmd_args = ($cmd_args | append "--subresource" | append $subresource)
    }

    if $as_user != null {
      $cmd_args = ($cmd_args | append "--as" | append $as_user)
    }

    if $as_group != null {
      for $group in $as_group {
        $cmd_args = ($cmd_args | append "--as-group" | append $group)
      }
    }

    if $all_namespaces {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    }

    if $quiet {
      $cmd_args = ($cmd_args | append "--quiet")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    let allowed = ($result | str trim) == "yes"

    {
      type: "auth_can_i_result"
      operation: "auth_can_i"
      permission_check: {
        verb: $verb
        resource: $resource
        resource_name: $resource_name
        namespace: $namespace
        subresource: $subresource
        as_user: $as_user
        as_group: $as_group
        all_namespaces: $all_namespaces
      }
      allowed: $allowed
      command: ($full_cmd | str join " ")
      result: $result
      message: (if $allowed { 
        $"Action '($verb) ($resource)' is ALLOWED" 
      } else { 
        $"Action '($verb) ($resource)' is DENIED" 
      })
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error checking permissions for '($verb) ($resource)': ($error.msg)"
      suggestions: [
        "Verify the verb is a valid Kubernetes verb"
        "Check the resource name is correct"
        "Ensure you have permission to perform authorization checks"
        "Verify user and group names if specified"
        "Check namespace exists if specified"
      ]
    } | to json
  }
}

# Get current user information
def auth_whoami [
  output: string = "wide"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["auth" "whoami"]

    if $output != "wide" {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "auth_whoami_result"
      operation: "auth_whoami"
      output_format: $output
      command: ($full_cmd | str join " ")
      user_info: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting user information: ($error.msg)"
      suggestions: [
        "Check that you are authenticated to the cluster"
        "Verify kubeconfig is properly configured"
        "Ensure the cluster is reachable"
        "Check that the current context is valid"
      ]
    } | to json
  }
}

# Reconcile RBAC resources
def auth_reconcile [
  file_path: string
  namespace: string
  dry_run: bool = false
  remove_extra_permissions: bool = false
  remove_extra_subjects: bool = false
  delegate_to?: string
] {
  try {
    if not ($file_path | path exists) {
      return (
        {
          type: "error"
          message: $"File or directory '($file_path)' does not exist"
        } | to json
      )
    }

    mut cmd_args = ["auth" "reconcile" "--filename" $file_path "--namespace" $namespace]

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $remove_extra_permissions {
      $cmd_args = ($cmd_args | append "--remove-extra-permissions")
    }

    if $remove_extra_subjects {
      $cmd_args = ($cmd_args | append "--remove-extra-subjects")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "auth_reconcile_result"
      operation: (if $dry_run { "dry_run_auth_reconcile" } else { "auth_reconcile" })
      file_path: $file_path
      namespace: $namespace
      options: {
        dry_run: $dry_run
        remove_extra_permissions: $remove_extra_permissions
        remove_extra_subjects: $remove_extra_subjects
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"RBAC reconciliation completed for namespace '($namespace)'"
      warning: "RBAC changes can affect cluster security - review changes carefully"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error reconciling RBAC from '($file_path)': ($error.msg)"
      suggestions: [
        "Verify RBAC YAML file syntax is correct"
        "Check that you have permission to modify RBAC resources"
        "Ensure namespace exists"
        "Verify all referenced users, groups, and service accounts exist"
        "Check that role and cluster role references are valid"
      ]
    } | to json
  }
}

# List all allowed actions for current user
def auth_can_i_list [
  namespace?: string
  as_user?: string
  as_group?: any
  delegate_to?: string
] {
  try {
    mut cmd_args = ["auth" "can-i" "--list"]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $as_user != null {
      $cmd_args = ($cmd_args | append "--as" | append $as_user)
    }

    if $as_group != null {
      for $group in $as_group {
        $cmd_args = ($cmd_args | append "--as-group" | append $group)
      }
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "auth_can_i_list_result"
      operation: "auth_can_i_list"
      scope: (if $namespace != null { $namespace } else { "cluster-wide" })
      impersonation: {
        as_user: $as_user
        as_group: $as_group
      }
      command: ($full_cmd | str join " ")
      permissions: $result
      message: $"Listed all allowed actions for current context"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error listing permissions: ($error.msg)"
      suggestions: [
        "Check that you are authenticated to the cluster"
        "Verify you have permission to perform authorization checks"
        "Ensure namespace exists if specified"
        "Check user and group names if impersonating"
      ]
    } | to json
  }
}