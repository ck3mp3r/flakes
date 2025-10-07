# Kubernetes resource creation tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "create_from_file"
      title: "Create from File"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Create resources from YAML/JSON file - can create new cluster resources"
      input_schema: {
        type: "object"
        properties: {
          file_path: {
            type: "string"
            description: "Path to YAML or JSON file containing resource definitions"
          }
          namespace: {
            type: "string"
            description: "Namespace to create resources in (mandatory for safety)"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without creating resources"
            default: false
          }
          validate: {
            type: "boolean"
            description: "Validate resources against server schema"
            default: true
          }
          save_config: {
            type: "boolean"
            description: "Save configuration for future kubectl apply calls"
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
      name: "create_namespace"
      title: "Create Namespace"
      description: "[MODIFIES CLUSTER] Create a new namespace"
      input_schema: {
        type: "object"
        properties: {
          name: {
            type: "string"
            description: "Name of the namespace to create"
          }
          labels: {
            type: "object"
            description: "Labels to apply to the namespace"
          }
          annotations: {
            type: "object"
            description: "Annotations to apply to the namespace"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without creating"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["name"]
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
      name: "create_configmap"
      title: "Create ConfigMap"
      description: "[MODIFIES CLUSTER] Create configmap from files or literal values"
      input_schema: {
        type: "object"
        properties: {
          name: {
            type: "string"
            description: "Name of the configmap"
          }
          namespace: {
            type: "string"
            description: "Namespace to create configmap in (mandatory for safety)"
          }
          from_literal: {
            type: "object"
            description: "Key-value pairs for configmap data"
          }
          from_file: {
            type: "array"
            items: {type: "string"}
            description: "Array of file paths to include in configmap"
          }
          from_env_file: {
            type: "string"
            description: "Path to env file to load as configmap data"
          }
          labels: {
            type: "object"
            description: "Labels to apply to the configmap"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without creating"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["name", "namespace"]
      }
    }
    {
      name: "create_secret"
      title: "Create Secret"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Create secret with sensitive data"
      input_schema: {
        type: "object"
        properties: {
          name: {
            type: "string"
            description: "Name of the secret"
          }
          namespace: {
            type: "string"
            description: "Namespace to create secret in (mandatory for safety)"
          }
          secret_type: {
            type: "string"
            description: "Type of secret to create"
            enum: ["generic", "docker-registry", "tls"]
            default: "generic"
          }
          from_literal: {
            type: "object"
            description: "Key-value pairs for secret data"
          }
          from_file: {
            type: "array"
            items: {type: "string"}
            description: "Array of file paths to include in secret"
          }
          docker_server: {
            type: "string"
            description: "Docker registry server (for docker-registry type)"
          }
          docker_username: {
            type: "string"
            description: "Docker registry username"
          }
          docker_password: {
            type: "string"
            description: "Docker registry password"
          }
          docker_email: {
            type: "string"
            description: "Docker registry email"
          }
          tls_cert: {
            type: "string"
            description: "Path to TLS certificate file"
          }
          tls_key: {
            type: "string"
            description: "Path to TLS private key file"
          }
          labels: {
            type: "object"
            description: "Labels to apply to the secret"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without creating"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["name", "namespace"]
      }
    }
    {
      name: "create_deployment"
      title: "Create Deployment"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Create deployment with specified image"
      input_schema: {
        type: "object"
        properties: {
          name: {
            type: "string"
            description: "Name of the deployment"
          }
          namespace: {
            type: "string"
            description: "Namespace to create deployment in (mandatory for safety)"
          }
          image: {
            type: "string"
            description: "Container image to deploy"
          }
          replicas: {
            type: "integer"
            description: "Number of replicas"
            default: 1
          }
          port: {
            type: "integer"
            description: "Container port to expose"
          }
          env: {
            type: "object"
            description: "Environment variables for the container"
          }
          labels: {
            type: "object"
            description: "Labels to apply to the deployment"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without creating"
            default: false
          }
          save_config: {
            type: "boolean"
            description: "Save configuration for future kubectl apply calls"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["name", "namespace", "image"]
      }
    }
    {
      name: "create_service"
      title: "Create Service"
      description: "[MODIFIES CLUSTER] Create service to expose deployments or pods"
      input_schema: {
        type: "object"
        properties: {
          name: {
            type: "string"
            description: "Name of the service"
          }
          namespace: {
            type: "string"
            description: "Namespace to create service in (mandatory for safety)"
          }
          service_type: {
            type: "string"
            description: "Type of service"
            enum: ["ClusterIP", "NodePort", "LoadBalancer", "ExternalName"]
            default: "ClusterIP"
          }
          selector: {
            type: "object"
            description: "Label selector for pods"
          }
          ports: {
            type: "array"
            items: {
              type: "object"
              properties: {
                port: {type: "integer"}
                target_port: {type: "integer"}
                protocol: {type: "string", default: "TCP"}
                name: {type: "string"}
              }
            }
            description: "Port mappings for the service"
          }
          external_name: {
            type: "string"
            description: "External name for ExternalName service type"
          }
          labels: {
            type: "object"
            description: "Labels to apply to the service"
          }
          dry_run: {
            type: "boolean"
            description: "Perform dry run without creating"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["name", "namespace"]
      }
    }
  ] | to json
}

# Call a specific tool with arguments
def "main call-tool" [
  tool_name: string # Name of the tool to call
  args: any = {} # Arguments as nushell record or JSON string
] {
  let parsed_args = $args | from json

  match $tool_name {
    "create_from_file" => {
      let file_path = $parsed_args.file_path
      let namespace = $parsed_args.namespace
      let dry_run = $parsed_args.dry_run? | default false
      let validate = $parsed_args.validate? | default true
      let save_config = $parsed_args.save_config? | default false
      let delegate_to = $parsed_args.delegate_to?

      create_from_file $file_path $namespace $dry_run $validate $save_config $delegate_to
    }
    "create_namespace" => {
      let name = $parsed_args.name
      let labels = $parsed_args.labels?
      let annotations = $parsed_args.annotations?
      let dry_run = $parsed_args.dry_run? | default false
      let delegate_to = $parsed_args.delegate_to?

      create_namespace $name $labels $annotations $dry_run $delegate_to
    }
    "create_configmap" => {
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let from_literal = $parsed_args.from_literal?
      let from_file = $parsed_args.from_file?
      let from_env_file = $parsed_args.from_env_file?
      let labels = $parsed_args.labels?
      let dry_run = $parsed_args.dry_run? | default false
      let delegate_to = $parsed_args.delegate_to?

      create_configmap $name $namespace $from_literal $from_file $from_env_file $labels $dry_run $delegate_to
    }
    "create_secret" => {
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let secret_type = $parsed_args.secret_type? | default "generic"
      let from_literal = $parsed_args.from_literal?
      let from_file = $parsed_args.from_file?
      let docker_server = $parsed_args.docker_server?
      let docker_username = $parsed_args.docker_username?
      let docker_password = $parsed_args.docker_password?
      let docker_email = $parsed_args.docker_email?
      let tls_cert = $parsed_args.tls_cert?
      let tls_key = $parsed_args.tls_key?
      let labels = $parsed_args.labels?
      let dry_run = $parsed_args.dry_run? | default false
      let delegate_to = $parsed_args.delegate_to?

      create_secret $name $namespace $secret_type $from_literal $from_file $docker_server $docker_username $docker_password $docker_email $tls_cert $tls_key $labels $dry_run $delegate_to
    }
    "create_deployment" => {
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let image = $parsed_args.image
      let replicas = $parsed_args.replicas? | default 1
      let port = $parsed_args.port?
      let env_vars = $parsed_args.env?
      let labels = $parsed_args.labels?
      let dry_run = $parsed_args.dry_run? | default false
      let save_config = $parsed_args.save_config? | default false
      let delegate_to = $parsed_args.delegate_to?

      create_deployment $name $namespace $image $replicas $port $env_vars $labels $dry_run $save_config $delegate_to
    }
    "create_service" => {
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace
      let service_type = $parsed_args.service_type? | default "ClusterIP"
      let selector = $parsed_args.selector?
      let ports = $parsed_args.ports?
      let external_name = $parsed_args.external_name?
      let labels = $parsed_args.labels?
      let dry_run = $parsed_args.dry_run? | default false
      let delegate_to = $parsed_args.delegate_to?

      create_service $name $namespace $service_type $selector $ports $external_name $labels $dry_run $delegate_to
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Create resources from YAML/JSON file
def create_from_file [
  file_path: string
  namespace: string
  dry_run: bool = false
  validate: bool = true
  save_config: bool = false
  delegate_to?: string
] {
  try {
    if not ($file_path | path exists) {
      return (
        {
          type: "error"
          message: $"File '($file_path)' does not exist"
        } | to json
      )
    }

    mut cmd_args = ["create" "--filename" $file_path "--namespace" $namespace]

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if not $validate {
      $cmd_args = ($cmd_args | append "--validate=false")
    }

    if $save_config {
      $cmd_args = ($cmd_args | append "--save-config")
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "create_from_file"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          file_path: $file_path
          namespace: $namespace
          dry_run: $dry_run
          validate: $validate
          save_config: $save_config
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "create_from_file_result"
      operation: (if $dry_run { "dry_run_create" } else { "create_from_file" })
      file_path: $file_path
      namespace: $namespace
      options: {
        dry_run: $dry_run
        validate: $validate
        save_config: $save_config
      }
      command: $cmd_string
      result: $result
      message: $"Resources created from file '($file_path)' in namespace '($namespace)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating resources from file '($file_path)': ($error.msg)"
      suggestions: [
        "Verify file syntax is valid YAML or JSON"
        "Check that all required fields are present in resource definitions"
        "Ensure you have permission to create resources in the namespace"
        "Verify the namespace exists"
        "Check resource API versions are supported by the cluster"
      ]
    } | to json
  }
}

# Create namespace
def create_namespace [
  name: string
  labels?: any
  annotations?: any
  dry_run: bool = false
  delegate_to?: string
] {
  try {
    mut cmd_args = ["create" "namespace" $name]

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "create_namespace"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          name: $name
          labels: $labels
          annotations: $annotations
          dry_run: $dry_run
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    # Apply labels and annotations if provided (only if not dry run)
    if not $dry_run {
      if $labels != null {
        let label_pairs = $labels | items {|key, value| $"($key)=($value)" }
        for $label in $label_pairs {
          let label_cmd = ["label" "namespace" $name $label]
          let full_label_cmd = (["kubectl"] | append $label_cmd)
          print $"Executing: ($full_label_cmd | str join ' ')"
          run-external ...$full_label_cmd | ignore
        }
      }

      if $annotations != null {
        let annotation_pairs = $annotations | items {|key, value| $"($key)=($value)" }
        for $annotation in $annotation_pairs {
          let annotate_cmd = ["annotate" "namespace" $name $annotation]
          let full_annotate_cmd = (["kubectl"] | append $annotate_cmd)
          print $"Executing: ($full_annotate_cmd | str join ' ')"
          run-external ...$full_annotate_cmd | ignore
        }
      }
    }

    {
      type: "create_namespace_result"
      operation: (if $dry_run { "dry_run_create_namespace" } else { "create_namespace" })
      namespace: $name
      metadata: {
        labels: $labels
        annotations: $annotations
      }
      command: $cmd_string
      result: $result
      message: $"Namespace '($name)' created successfully"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating namespace '($name)': ($error.msg)"
      suggestions: [
        "Verify you have permission to create namespaces"
        "Check that the namespace name doesn't already exist"
        "Ensure namespace name follows Kubernetes naming conventions"
        "Try without labels/annotations if they are causing issues"
      ]
    } | to json
  }
}

# Create configmap
def create_configmap [
  name: string
  namespace: string
  from_literal?: any
  from_file?: any
  from_env_file?: string
  labels?: any
  dry_run: bool = false
  delegate_to?: string
] {
  try {
    mut cmd_args = ["create" "configmap" $name "--namespace" $namespace]

    # Add data sources
    if $from_literal != null {
      let literal_pairs = $from_literal | items {|key, value| $"($key)=($value)" }
      for $pair in $literal_pairs {
        $cmd_args = ($cmd_args | append "--from-literal" | append $pair)
      }
    }

    if $from_file != null {
      for $file in $from_file {
        if not ($file | path exists) {
          return (
            {
              type: "error"
              message: $"File '($file)' does not exist"
            } | to json
          )
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        $cmd_args = ($cmd_args | append "--from-file" | append $file)
      }
    }

    if $from_env_file != null {
      if not ($from_env_file | path exists) {
        return (
          {
            type: "error"
            message: $"Env file '($from_env_file)' does not exist"
          } | to json
        )
      }
      $cmd_args = ($cmd_args | append "--from-env-file" | append $from_env_file)
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "create_configmap_result"
      operation: (if $dry_run { "dry_run_create_configmap" } else { "create_configmap" })
      configmap: $name
      namespace: $namespace
      data_sources: {
        from_literal: $from_literal
        from_file: $from_file
        from_env_file: $from_env_file
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"ConfigMap '($name)' created in namespace '($namespace)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating configmap '($name)': ($error.msg)"
      suggestions: [
        "Verify you have permission to create configmaps in the namespace"
        "Check that all source files exist and are readable"
        "Ensure configmap name doesn't already exist"
        "Verify namespace exists"
        "Check that data sources are properly formatted"
      ]
    } | to json
  }
}

# Create secret (simplified for security - full implementation would need more careful handling)
def create_secret [
  name: string
  namespace: string
  secret_type: string = "generic"
  from_literal?: any
  from_file?: any
  docker_server?: string
  docker_username?: string
  docker_password?: string
  docker_email?: string
  tls_cert?: string
  tls_key?: string
  labels?: any
  dry_run: bool = false
] {
  try {
    mut cmd_args = ["create" "secret" $secret_type $name "--namespace" $namespace]

    # Handle different secret types
    match $secret_type {
      "generic" => {
        if $from_literal != null {
          let literal_pairs = $from_literal | items {|key, value| $"($key)=($value)" }
          for $pair in $literal_pairs {
            $cmd_args = ($cmd_args | append "--from-literal" | append $pair)
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }

        if $from_file != null {
          for $file in $from_file {
            if not ($file | path exists) {
              return (
                {
                  type: "error"
                  message: $"File '($file)' does not exist"
                } | to json
              )
            }
            $cmd_args = ($cmd_args | append "--from-file" | append $file)
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
      "docker-registry" => {
        if $docker_server != null { $cmd_args = ($cmd_args | append "--docker-server" | append $docker_server) }
        if $docker_username != null { $cmd_args = ($cmd_args | append "--docker-username" | append $docker_username) }
        if $docker_password != null { $cmd_args = ($cmd_args | append "--docker-password" | append $docker_password) }
        if $docker_email != null { $cmd_args = ($cmd_args | append "--docker-email" | append $docker_email) }
      }
      "tls" => {
        if $tls_cert != null { $cmd_args = ($cmd_args | append "--cert" | append $tls_cert) }
        if $tls_key != null { $cmd_args = ($cmd_args | append "--key" | append $tls_key) }
      }
      _ => {
        return (
          {
            type: "error"
            message: $"Unsupported secret type: ($secret_type)"
          } | to json
        )
      }
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "create_secret_result"
      operation: (if $dry_run { "dry_run_create_secret" } else { "create_secret" })
      secret: $name
      namespace: $namespace
      secret_type: $secret_type
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Secret '($name)' of type '($secret_type)' created in namespace '($namespace)'"
      warning: "Secret contains sensitive data - ensure proper access controls"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating secret '($name)': ($error.msg)"
      suggestions: [
        "Verify you have permission to create secrets in the namespace"
        "Check that all required parameters for the secret type are provided"
        "Ensure secret name doesn't already exist"
        "Verify namespace exists"
        "For TLS secrets, ensure cert and key files are valid"
      ]
    } | to json
  }
}

# Create deployment
def create_deployment [
  name: string
  namespace: string
  image: string
  replicas: int = 1
  port?: int
  env_vars?: any
  labels?: any
  dry_run: bool = false
  save_config: bool = false
] {
  try {
    mut cmd_args = ["create" "deployment" $name "--image" $image "--namespace" $namespace "--replicas" ($replicas | into string)]

    if $port != null {
      $cmd_args = ($cmd_args | append "--port" | append ($port | into string))
    }

    if $env_vars != null {
      let env_pairs = $env_vars | items {|key, value| $"($key)=($value)" }
      for $env_var in $env_pairs {
        $cmd_args = ($cmd_args | append "--env" | append $env_var)
      }
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $save_config {
      $cmd_args = ($cmd_args | append "--save-config")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "create_deployment_result"
      operation: (if $dry_run { "dry_run_create_deployment" } else { "create_deployment" })
      deployment: $name
      namespace: $namespace
      image: $image
      configuration: {
        replicas: $replicas
        port: $port
        env: $env_vars
        labels: $labels
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Deployment '($name)' created with image '($image)' in namespace '($namespace)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating deployment '($name)': ($error.msg)"
      suggestions: [
        "Verify you have permission to create deployments in the namespace"
        "Check that the container image exists and is accessible"
        "Ensure deployment name doesn't already exist"
        "Verify namespace exists"
        "Check that environment variables are properly formatted"
      ]
    } | to json
  }
}

# Create service
def create_service [
  name: string
  namespace: string
  service_type: string = "ClusterIP"
  selector?: any
  ports?: any
  external_name?: string
  labels?: any
  dry_run: bool = false
] {
  try {
    mut cmd_args = ["create" "service" ($service_type | str downcase) $name "--namespace" $namespace]

    # Handle service-specific parameters
    match ($service_type | str downcase) {
      "externalname" => {
        if $external_name != null {
          $cmd_args = ($cmd_args | append "--external-name" | append $external_name)
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
      _ => {
        # For ClusterIP, NodePort, LoadBalancer
        if $ports != null and ($ports | length) > 0 {
          let first_port = $ports | first
          if $first_port.port? != null {
            $cmd_args = ($cmd_args | append "--tcp" | append $"($first_port.port):($first_port.target_port? | default $first_port.port)")
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "create_service_result"
      operation: (if $dry_run { "dry_run_create_service" } else { "create_service" })
      service: $name
      namespace: $namespace
      service_type: $service_type
      configuration: {
        selector: $selector
        ports: $ports
        external_name: $external_name
        labels: $labels
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Service '($name)' of type '($service_type)' created in namespace '($namespace)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating service '($name)': ($error.msg)"
      suggestions: [
        "Verify you have permission to create services in the namespace"
        "Check that the service name doesn't already exist"
        "Ensure port configurations are valid"
        "Verify namespace exists"
        "For ExternalName services, ensure external-name is provided"
      ]
    } | to json
  }
}