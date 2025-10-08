# Kubernetes configuration management tool for nu-mcp

use nu-mcp-lib *

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "config_view"
      description: "View kubeconfig file or specific parts of it"
      input_schema: {
        type: "object"
        properties: {
          minify: {
            type: "boolean"
            description: "Remove non-essential information from output"
            default: false
          }
          flatten: {
            type: "boolean"
            description: "Flatten the resulting kubeconfig file into self-contained output"
            default: false
          }
          merge: {
            type: "boolean"
            description: "Merge multiple kubeconfig files"
            default: true
          }
          raw: {
            type: "boolean"
            description: "Display raw byte data"
            default: false
          }
          output: {
            type: "string"
            description: "Output format"
            enum: ["json", "yaml"]
            default: "yaml"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "config_current_context"
      description: "Display the current active context"
      input_schema: {
        type: "object"
        properties: {}
      }
    }
    {
      name: "config_get_contexts"
      description: "List all available contexts"
      input_schema: {
        type: "object"
        properties: {
          output: {
            type: "string"
            description: "Output format"
            enum: ["name", "wide"]
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
      name: "config_get_clusters"
      description: "List all clusters defined in kubeconfig"
      input_schema: {
        type: "object"
        properties: {}
      }
    }
    {
      name: "config_get_users"
      description: "List all users defined in kubeconfig"
      input_schema: {
        type: "object"
        properties: {}
      }
    }
    {
      name: "config_use_context"
      description: "[MODIFIES CONFIG] Switch to a different context"
      input_schema: {
        type: "object"
        properties: {
          context_name: {
            type: "string"
            description: "Name of the context to switch to"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["context_name"]
      }
    }
    {
      name: "config_set_context"
      description: "[MODIFIES CONFIG] Set context properties (cluster, namespace, user)"
      input_schema: {
        type: "object"
        properties: {
          context_name: {
            type: "string"
            description: "Name of the context to modify or create"
          }
          cluster: {
            type: "string"
            description: "Cluster name for the context"
          }
          user: {
            type: "string"
            description: "User name for the context"
          }
          namespace: {
            type: "string"
            description: "Default namespace for the context"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["context_name"]
      }
    }
    {
      name: "config_set_cluster"
      description: "[MODIFIES CONFIG] Set cluster properties (server, certificate-authority, etc.)"
      input_schema: {
        type: "object"
        properties: {
          cluster_name: {
            type: "string"
            description: "Name of the cluster to modify or create"
          }
          server: {
            type: "string"
            description: "Server URL for the cluster"
          }
          certificate_authority: {
            type: "string"
            description: "Path to certificate authority file"
          }
          certificate_authority_data: {
            type: "string"
            description: "Base64 encoded certificate authority data"
          }
          insecure_skip_tls_verify: {
            type: "boolean"
            description: "Skip TLS certificate verification"
            default: false
          }
          proxy_url: {
            type: "string"
            description: "Proxy URL for the cluster"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["cluster_name"]
      }
    }
    {
      name: "config_set_credentials"
      description: "[MODIFIES CONFIG] Set user credentials (client-certificate, token, etc.)"
      input_schema: {
        type: "object"
        properties: {
          user_name: {
            type: "string"
            description: "Name of the user to modify or create"
          }
          client_certificate: {
            type: "string"
            description: "Path to client certificate file"
          }
          client_certificate_data: {
            type: "string"
            description: "Base64 encoded client certificate data"
          }
          client_key: {
            type: "string"
            description: "Path to client key file"
          }
          client_key_data: {
            type: "string"
            description: "Base64 encoded client key data"
          }
          token: {
            type: "string"
            description: "Bearer token for authentication"
          }
          username: {
            type: "string"
            description: "Basic auth username"
          }
          password: {
            type: "string"
            description: "Basic auth password"
          }
          auth_provider: {
            type: "string"
            description: "Auth provider name (gcp, azure, etc.)"
          }
          exec_command: {
            type: "string"
            description: "External command for credential plugin"
          }
          exec_args: {
            type: "array"
            items: {type: "string"}
            description: "Arguments for exec command"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["user_name"]
      }
    }
    {
      name: "config_delete_context"
      description: "[MODIFIES CONFIG] Delete a context from kubeconfig"
      input_schema: {
        type: "object"
        properties: {
          context_name: {
            type: "string"
            description: "Name of the context to delete"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["context_name"]
      }
    }
    {
      name: "config_delete_cluster"
      description: "[MODIFIES CONFIG] Delete a cluster from kubeconfig"
      input_schema: {
        type: "object"
        properties: {
          cluster_name: {
            type: "string"
            description: "Name of the cluster to delete"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["cluster_name"]
      }
    }
    {
      name: "config_delete_user"
      description: "[MODIFIES CONFIG] Delete a user from kubeconfig"
      input_schema: {
        type: "object"
        properties: {
          user_name: {
            type: "string"
            description: "Name of the user to delete"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["user_name"]
      }
    }
    {
      name: "config_rename_context"
      description: "[MODIFIES CONFIG] Rename a context in kubeconfig"
      input_schema: {
        type: "object"
        properties: {
          old_name: {
            type: "string"
            description: "Current name of the context"
          }
          new_name: {
            type: "string"
            description: "New name for the context"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["old_name", "new_name"]
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
    "config_view" => {
      let minify = $parsed_args.minify? | default false
      let flatten = $parsed_args.flatten? | default false
      let merge = $parsed_args.merge? | default true
      let raw = $parsed_args.raw? | default false
      let output = $parsed_args.output? | default "yaml"
      let delegate_to = $parsed_args.delegate_to?

      config_view $minify $flatten $merge $raw $output $delegate_to
    }
    "config_current_context" => {
      config_current_context
    }
    "config_get_contexts" => {
      let output = $parsed_args.output? | default "wide"
      let delegate_to = $parsed_args.delegate_to?
      config_get_contexts $output $delegate_to
    }
    "config_get_clusters" => {
      config_get_clusters
    }
    "config_get_users" => {
      config_get_users
    }
    "config_use_context" => {
      let context_name = $parsed_args.context_name
      config_use_context $context_name
    }
    "config_set_context" => {
      let context_name = $parsed_args.context_name
      let cluster = $parsed_args.cluster?
      let user = $parsed_args.user?
      let namespace = $parsed_args.namespace?

      config_set_context $context_name $cluster $user $namespace
    }
    "config_set_cluster" => {
      let cluster_name = $parsed_args.cluster_name
      let server = $parsed_args.server?
      let certificate_authority = $parsed_args.certificate_authority?
      let certificate_authority_data = $parsed_args.certificate_authority_data?
      let insecure_skip_tls_verify = $parsed_args.insecure_skip_tls_verify? | default false
      let proxy_url = $parsed_args.proxy_url?

      config_set_cluster $cluster_name $server $certificate_authority $certificate_authority_data $insecure_skip_tls_verify $proxy_url
    }
    "config_set_credentials" => {
      let user_name = $parsed_args.user_name
      let client_certificate = $parsed_args.client_certificate?
      let client_certificate_data = $parsed_args.client_certificate_data?
      let client_key = $parsed_args.client_key?
      let client_key_data = $parsed_args.client_key_data?
      let token = $parsed_args.token?
      let username = $parsed_args.username?
      let password = $parsed_args.password?
      let auth_provider = $parsed_args.auth_provider?
      let exec_command = $parsed_args.exec_command?
      let exec_args = $parsed_args.exec_args?

      config_set_credentials $user_name $client_certificate $client_certificate_data $client_key $client_key_data $token $username $password $auth_provider $exec_command $exec_args
    }
    "config_delete_context" => {
      let context_name = $parsed_args.context_name
      config_delete_context $context_name
    }
    "config_delete_cluster" => {
      let cluster_name = $parsed_args.cluster_name
      config_delete_cluster $cluster_name
    }
    "config_delete_user" => {
      let user_name = $parsed_args.user_name
      config_delete_user $user_name
    }
    "config_rename_context" => {
      let old_name = $parsed_args.old_name
      let new_name = $parsed_args.new_name
      config_rename_context $old_name $new_name
    }
    _ => {
      result [(text $"Unknown tool: ($tool_name)")] --error=true | to json
    }
  }
}

# View kubeconfig
def config_view [
  minify: bool = false
  flatten: bool = false
  merge: bool = true
  raw: bool = false
  output: string = "yaml"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["config" "view"]

    if $minify {
      $cmd_args = ($cmd_args | append "--minify")
    }

    if $flatten {
      $cmd_args = ($cmd_args | append "--flatten")
    }

    if not $merge {
      $cmd_args = ($cmd_args | append "--merge=false")
    }

    if $raw {
      $cmd_args = ($cmd_args | append "--raw")
    }

    if $output == "json" {
      $cmd_args = ($cmd_args | append "--output" | append "json")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_view_result"
      operation: "config_view"
      options: {
        minify: $minify
        flatten: $flatten
        merge: $merge
        raw: $raw
        output: $output
      }
      command: ($full_cmd | str join " ")
      config: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error viewing kubeconfig: ($error.msg)"
      suggestions: [
        "Check that kubeconfig file exists and is readable"
        "Verify KUBECONFIG environment variable if set"
        "Ensure proper permissions on kubeconfig file"
      ]
    } | to json
  }
}

# Get current context
def config_current_context [] {
  try {
    let cmd_args = ["config" "current-context"]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_current_context_result"
      operation: "config_current_context"
      command: ($full_cmd | str join " ")
      current_context: ($result | str trim)
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting current context: ($error.msg)"
      suggestions: [
        "Check that kubeconfig file exists"
        "Verify at least one context is defined"
        "Ensure kubeconfig file is properly formatted"
      ]
    } | to json
  }
}

# Get contexts
def config_get_contexts [
  output: string = "wide"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["config" "get-contexts"]

    if $output == "name" {
      $cmd_args = ($cmd_args | append "--output" | append "name")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_get_contexts_result"
      operation: "config_get_contexts"
      output_format: $output
      command: ($full_cmd | str join " ")
      contexts: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting contexts: ($error.msg)"
      suggestions: [
        "Check that kubeconfig file exists"
        "Verify kubeconfig file is properly formatted"
        "Ensure contexts are defined in kubeconfig"
      ]
    } | to json
  }
}

# Get clusters
def config_get_clusters [] {
  try {
    let cmd_args = ["config" "get-clusters"]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_get_clusters_result"
      operation: "config_get_clusters"
      command: ($full_cmd | str join " ")
      clusters: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting clusters: ($error.msg)"
      suggestions: [
        "Check that kubeconfig file exists"
        "Verify kubeconfig file is properly formatted"
        "Ensure clusters are defined in kubeconfig"
      ]
    } | to json
  }
}

# Get users
def config_get_users [] {
  try {
    let cmd_args = ["config" "get-users"]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_get_users_result"
      operation: "config_get_users"
      command: ($full_cmd | str join " ")
      users: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting users: ($error.msg)"
      suggestions: [
        "Check that kubeconfig file exists"
        "Verify kubeconfig file is properly formatted"
        "Ensure users are defined in kubeconfig"
      ]
    } | to json
  }
}

# Use context (switch to a different context)
def config_use_context [
  context_name: string
] {
  try {
    let cmd_args = ["config" "use-context" $context_name]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_use_context_result"
      operation: "config_use_context"
      context_name: $context_name
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Switched to context '($context_name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error switching to context '($context_name)': ($error.msg)"
      suggestions: [
        "Verify the context name exists in kubeconfig"
        "Check context spelling and case sensitivity"
        "Use config_get_contexts to list available contexts"
        "Ensure kubeconfig file is writable"
      ]
    } | to json
  }
}

# Set context properties
def config_set_context [
  context_name: string
  cluster?: string
  user?: string
  namespace?: string
] {
  try {
    mut cmd_args = ["config" "set-context" $context_name]

    if $cluster != null {
      $cmd_args = ($cmd_args | append $"--cluster=($cluster)")
    }

    if $user != null {
      $cmd_args = ($cmd_args | append $"--user=($user)")
    }

    if $namespace != null {
      $cmd_args = ($cmd_args | append $"--namespace=($namespace)")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_set_context_result"
      operation: "config_set_context"
      context_name: $context_name
      properties: {
        cluster: $cluster
        user: $user
        namespace: $namespace
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Context '($context_name)' properties updated"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error setting context '($context_name)': ($error.msg)"
      suggestions: [
        "Verify cluster and user names exist if specified"
        "Check namespace name is valid"
        "Ensure kubeconfig file is writable"
        "Verify context name follows naming conventions"
      ]
    } | to json
  }
}

# Set cluster properties
def config_set_cluster [
  cluster_name: string
  server?: string
  certificate_authority?: string
  certificate_authority_data?: string
  insecure_skip_tls_verify: bool = false
  proxy_url?: string
] {
  try {
    mut cmd_args = ["config" "set-cluster" $cluster_name]

    if $server != null {
      $cmd_args = ($cmd_args | append $"--server=($server)")
    }

    if $certificate_authority != null {
      $cmd_args = ($cmd_args | append $"--certificate-authority=($certificate_authority)")
    }

    if $certificate_authority_data != null {
      $cmd_args = ($cmd_args | append $"--certificate-authority-data=($certificate_authority_data)")
    }

    if $insecure_skip_tls_verify {
      $cmd_args = ($cmd_args | append "--insecure-skip-tls-verify=true")
    }

    if $proxy_url != null {
      $cmd_args = ($cmd_args | append $"--proxy-url=($proxy_url)")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_set_cluster_result"
      operation: "config_set_cluster"
      cluster_name: $cluster_name
      properties: {
        server: $server
        certificate_authority: $certificate_authority
        certificate_authority_data: ($certificate_authority_data != null)
        insecure_skip_tls_verify: $insecure_skip_tls_verify
        proxy_url: $proxy_url
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Cluster '($cluster_name)' properties updated"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error setting cluster '($cluster_name)': ($error.msg)"
      suggestions: [
        "Verify server URL is valid and reachable"
        "Check certificate authority file exists if specified"
        "Ensure certificate authority data is valid base64"
        "Verify proxy URL format if specified"
        "Ensure kubeconfig file is writable"
      ]
    } | to json
  }
}

# Set user credentials
def config_set_credentials [
  user_name: string
  client_certificate?: string
  client_certificate_data?: string
  client_key?: string
  client_key_data?: string
  token?: string
  username?: string
  password?: string
  auth_provider?: string
  exec_command?: string
  exec_args?: any
] {
  try {
    mut cmd_args = ["config" "set-credentials" $user_name]

    if $client_certificate != null {
      $cmd_args = ($cmd_args | append $"--client-certificate=($client_certificate)")
    }

    if $client_certificate_data != null {
      $cmd_args = ($cmd_args | append $"--client-certificate-data=($client_certificate_data)")
    }

    if $client_key != null {
      $cmd_args = ($cmd_args | append $"--client-key=($client_key)")
    }

    if $client_key_data != null {
      $cmd_args = ($cmd_args | append $"--client-key-data=($client_key_data)")
    }

    if $token != null {
      $cmd_args = ($cmd_args | append $"--token=($token)")
    }

    if $username != null {
      $cmd_args = ($cmd_args | append $"--username=($username)")
    }

    if $password != null {
      $cmd_args = ($cmd_args | append $"--password=($password)")
    }

    if $auth_provider != null {
      $cmd_args = ($cmd_args | append $"--auth-provider=($auth_provider)")
    }

    if $exec_command != null {
      $cmd_args = ($cmd_args | append $"--exec-command=($exec_command)")
    }

    if $exec_args != null {
      for $arg in $exec_args {
        $cmd_args = ($cmd_args | append $"--exec-arg=($arg)")
      }
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_set_credentials_result"
      operation: "config_set_credentials"
      user_name: $user_name
      properties: {
        client_certificate: $client_certificate
        client_certificate_data: ($client_certificate_data != null)
        client_key: $client_key
        client_key_data: ($client_key_data != null)
        token: ($token != null)
        username: $username
        password: ($password != null)
        auth_provider: $auth_provider
        exec_command: $exec_command
        exec_args: $exec_args
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"User '($user_name)' credentials updated"
      warning: "Credentials contain sensitive data - ensure proper security"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error setting credentials for user '($user_name)': ($error.msg)"
      suggestions: [
        "Verify certificate files exist if specified"
        "Check certificate and key data are valid base64"
        "Ensure token format is correct"
        "Verify auth provider is supported"
        "Check exec command exists and is executable"
        "Ensure kubeconfig file is writable"
      ]
    } | to json
  }
}

# Delete context
def config_delete_context [
  context_name: string
] {
  try {
    let cmd_args = ["config" "delete-context" $context_name]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_delete_context_result"
      operation: "config_delete_context"
      context_name: $context_name
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Context '($context_name)' deleted from kubeconfig"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting context '($context_name)': ($error.msg)"
      suggestions: [
        "Verify the context name exists"
        "Check context name spelling and case"
        "Ensure kubeconfig file is writable"
        "Cannot delete the current context - switch to another first"
      ]
    } | to json
  }
}

# Delete cluster
def config_delete_cluster [
  cluster_name: string
] {
  try {
    let cmd_args = ["config" "delete-cluster" $cluster_name]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_delete_cluster_result"
      operation: "config_delete_cluster"
      cluster_name: $cluster_name
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Cluster '($cluster_name)' deleted from kubeconfig"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting cluster '($cluster_name)': ($error.msg)"
      suggestions: [
        "Verify the cluster name exists"
        "Check cluster name spelling and case"
        "Ensure kubeconfig file is writable"
        "Check if cluster is referenced by contexts"
      ]
    } | to json
  }
}

# Delete user
def config_delete_user [
  user_name: string
] {
  try {
    let cmd_args = ["config" "delete-user" $user_name]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_delete_user_result"
      operation: "config_delete_user"
      user_name: $user_name
      command: ($full_cmd | str join " ")
      result: $result
      message: $"User '($user_name)' deleted from kubeconfig"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error deleting user '($user_name)': ($error.msg)"
      suggestions: [
        "Verify the user name exists"
        "Check user name spelling and case"
        "Ensure kubeconfig file is writable"
        "Check if user is referenced by contexts"
      ]
    } | to json
  }
}

# Rename context
def config_rename_context [
  old_name: string
  new_name: string
] {
  try {
    let cmd_args = ["config" "rename-context" $old_name $new_name]

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "config_rename_context_result"
      operation: "config_rename_context"
      old_name: $old_name
      new_name: $new_name
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Context renamed from '($old_name)' to '($new_name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error renaming context from '($old_name)' to '($new_name)': ($error.msg)"
      suggestions: [
        "Verify the old context name exists"
        "Check that new context name doesn't already exist"
        "Ensure both names follow naming conventions"
        "Verify kubeconfig file is writable"
      ]
    } | to json
  }
}