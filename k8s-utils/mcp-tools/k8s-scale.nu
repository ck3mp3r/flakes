# Kubernetes scaling tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "scale_resource"
      description: "[MODIFIES CLUSTER] [DISRUPTIVE] Scale deployments, replica sets, or stateful sets - can cause service disruption"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type to scale (deployment, replicaset, statefulset)"
            enum: ["deployment" "replicaset" "statefulset" "replicationcontroller"]
          }
          name: {
            type: "string"
            description: "Resource name to scale"
          }
          replicas: {
            type: "integer"
            description: "Target number of replicas"
            minimum: 0
          }
          namespace: {
            type: "string"
            description: "Namespace (optional - uses current context if not specified)"
          }
          current_replicas: {
            type: "integer"
            description: "Current expected replica count (precondition)"
          }
          timeout: {
            type: "string"
            description: "Timeout for the scaling operation (e.g., '5m', '30s')"
            default: "5m"
          }
        }
        required: ["resource_type", "name", "namespace", "replicas"]
      }
    }
    {
      name: "scale_multiple"
      description: "[MODIFIES CLUSTER] [HIGHLY DISRUPTIVE] Scale multiple resources at once - can cause widespread service disruption"
      input_schema: {
        type: "object"
        properties: {
          resources: {
            type: "array"
            items: {
              type: "object"
              properties: {
                resource_type: {type: "string"}
                name: {type: "string"}
                replicas: {type: "integer"}
                namespace: {type: "string"}
              }
              required: ["resource_type", "name", "namespace", "replicas"]
            }
            description: "List of resources to scale"
          }
          timeout: {
            type: "string"
            description: "Timeout for scaling operations"
            default: "5m"
          }
        }
        required: ["resources"]
      }
    }
    {
      name: "get_scale_status"
      description: "Get current scaling status and replica information"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type to check"
          }
          name: {
            type: "string"
            description: "Resource name"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
        }
        required: ["resource_type", "name", "namespace"]
      }
    }
    {
      name: "autoscale_deployment"
      description: "[MODIFIES CLUSTER] Set up horizontal pod autoscaling for a deployment - modifies scaling behavior"
      input_schema: {
        type: "object"
        properties: {
          deployment_name: {
            type: "string"
            description: "Deployment name to autoscale"
          }
          min_replicas: {
            type: "integer"
            description: "Minimum number of replicas"
            minimum: 1
          }
          max_replicas: {
            type: "integer"
            description: "Maximum number of replicas"
            minimum: 1
          }
          cpu_percent: {
            type: "integer"
            description: "Target CPU utilization percentage"
            default: 80
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
        }
        required: ["deployment_name", "namespace", "min_replicas", "max_replicas"]
      }
    }
    {
      name: "scale_with_monitoring"
      description: "[MODIFIES CLUSTER] [DISRUPTIVE] Scale resource and monitor the scaling progress - can cause service disruption"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type to scale"
          }
          name: {
            type: "string"
            description: "Resource name"
          }
          replicas: {
            type: "integer"
            description: "Target replicas"
          }
          namespace: {
            type: "string"
            description: "Namespace (mandatory for safety)"
          }
          monitor_duration: {
            type: "string"
            description: "How long to monitor after scaling (e.g., '2m')"
            default: "2m"
          }
        }
        required: ["resource_type", "name", "namespace", "replicas"]
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
    "scale_resource" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let replicas = $parsed_args.replicas
      let namespace = $parsed_args.namespace?
      let current_replicas = $parsed_args.current_replicas?
      let timeout = $parsed_args.timeout? | default "5m"

      scale_resource $resource_type $name $replicas $namespace $timeout
    }
    "scale_multiple" => {
      let resources = $parsed_args.resources
      let timeout = $parsed_args.timeout? | default "5m"

      scale_multiple $resources $timeout
    }
    "get_scale_status" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace?

      get_scale_status $resource_type $name $namespace
    }
    "autoscale_deployment" => {
      let deployment_name = $parsed_args.deployment_name
      let min_replicas = $parsed_args.min_replicas
      let max_replicas = $parsed_args.max_replicas
      let cpu_percent = $parsed_args.cpu_percent? | default 80
      let namespace = $parsed_args.namespace?

      autoscale_deployment $deployment_name $min_replicas $max_replicas $cpu_percent $namespace
    }
    "scale_with_monitoring" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let replicas = $parsed_args.replicas
      let namespace = $parsed_args.namespace?
      let monitor_duration = $parsed_args.monitor_duration? | default "2m"

      scale_with_monitoring $resource_type $name $replicas $namespace $monitor_duration
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Scale a Kubernetes resource
def scale_resource [
  resource_type: string
  name: string
  replicas: int
  namespace?: string
  timeout: string = "5m"
] {
  try {
    mut cmd_args = ["scale" $resource_type $name $"--replicas=($replicas)"]

    # Add namespace if specified
    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    # Add timeout
    $cmd_args = ($cmd_args | append $"--timeout=($timeout)")

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    # Get current status after scaling
    let status = get_scale_status $resource_type $name $namespace | from json

    {
      type: "scale_result"
      operation: "scale"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      target_replicas: $replicas
      precondition: null
      timeout: $timeout
      command: ($full_cmd | str join " ")
      scale_output: $result
      current_status: $status
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error scaling ($resource_type)/($name): ($error.msg)"
      suggestions: [
        "Verify resource exists and is scalable"
        "Check current replica count matches precondition"
        "Ensure you have permission to scale the resource"
        "Confirm timeout is sufficient for the scaling operation"
      ]
    } | to json
  }
}

# Scale multiple resources at once
def scale_multiple [
  resources: list<record>
  timeout: string = "5m"
] {
  let scale_results = $resources | each {|resource|
    try {
      let resource_type = $resource.resource_type
      let name = $resource.name
      let replicas = $resource.replicas
      let namespace = $resource.namespace?

      let scale_result = try {
        scale_resource $resource_type $name $replicas $namespace $timeout | from json
      } catch {
        {type: "error" message: "Failed to scale resource"}
      }

      {
        resource: {
          type: $resource_type
          name: $name
          namespace: $namespace
        }
        status: "success"
        result: $scale_result
      }
    } catch {|error|
      {
        resource: {
          type: $resource.resource_type
          name: $resource.name
          namespace: $resource.namespace?
        }
        status: "error"
        error_message: $error.msg
      }
    }
  }

  let successful_scales = $scale_results | where status == "success" | length
  let failed_scales = $scale_results | where status == "error" | length

  {
    type: "multiple_scale_result"
    total_resources: ($resources | length)
    successful: $successful_scales
    failed: $failed_scales
    timeout: $timeout
    results: $scale_results
    summary: $"Scaled ($successful_scales) resources successfully, ($failed_scales) failed"
  } | to json
}

# Get current scaling status and replica information
def get_scale_status [
  resource_type: string
  name: string
  namespace?: string
] {
  try {
    mut get_cmd_args = ["get" $resource_type $name "--output" "json"]

    if $namespace != null {
      $get_cmd_args = ($get_cmd_args | append "--namespace" | append $namespace)
    }

    # Build and execute get command
    let full_get_cmd = (["kubectl"] | append $get_cmd_args)
    print $"Executing: ($full_get_cmd | str join ' ')"
    let resource_info = run-external ...$full_get_cmd | from json

    let spec = ($resource_info | get spec -o)
    let status = ($resource_info | get status -o)

    # Get replica information based on resource type
    let replica_status = match $resource_type {
      "deployment" => {
        let desired = ($spec | get replicas -o) | default 1
        let current = ($status | get replicas -o) | default 0
        let ready = ($status | get readyReplicas -o) | default 0
        let available = ($status | get availableReplicas -o) | default 0
        let updated = ($status | get updatedReplicas -o) | default 0

        {
          desired: $desired
          current: $current
          ready: $ready
          available: $available
          updated: $updated
          scaling_complete: ($current == $desired and $ready == $desired)
          health_status: (if $current == $desired and $ready == $desired { "healthy" } else { "scaling" })
        }
      }
      "replicaset" => {
        let desired = ($spec | get replicas -o) | default 1
        let current = ($status | get replicas -o) | default 0
        let ready = ($status | get readyReplicas -o) | default 0

        {
          desired: $desired
          current: $current
          ready: $ready
          scaling_complete: ($current == $desired and $ready == $desired)
          health_status: (if $current == $desired and $ready == $desired { "healthy" } else { "scaling" })
        }
      }
      "statefulset" => {
        let desired = ($spec | get replicas -o) | default 1
        let current = ($status | get replicas -o) | default 0
        let ready = ($status | get readyReplicas -o) | default 0
        let updated = ($status | get updatedReplicas -o) | default 0

        {
          desired: $desired
          current: $current
          ready: $ready
          updated: $updated
          scaling_complete: ($current == $desired and $ready == $desired)
          health_status: (if $current == $desired and $ready == $desired { "healthy" } else { "scaling" })
        }
      }
      _ => {
        {
          error: $"Unsupported resource type: ($resource_type)"
          health_status: "unknown"
        }
      }
    }

    # Get conditions if available
    let conditions = ($status | get conditions -o) | default [] | each {|condition|
      {
        type: $condition.type
        status: $condition.status
        reason: ($condition | get reason -o)
        message: ($condition | get message -o)
      }
    }

    {
      type: "scale_status"
      resource: {
        type: $resource_type
        name: $name
        namespace: ($namespace | default ($resource_info.metadata | get namespace -o))
        created: ($resource_info.metadata | get creationTimestamp -o)
      }
      replica_status: $replica_status
      conditions: $conditions
      timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting scale status for ($resource_type)/($name): ($error.msg)"
    } | to json
  }
}

# Set up horizontal pod autoscaling
def autoscale_deployment [
  deployment_name: string
  min_replicas: int
  max_replicas: int
  cpu_percent: int = 80
  namespace?: string
] {
  try {
    mut cmd_args = ["autoscale" "deployment" $deployment_name]
    $cmd_args = ($cmd_args | append $"--min=($min_replicas)" | append $"--max=($max_replicas)")
    $cmd_args = ($cmd_args | append $"--cpu-percent=($cpu_percent)")

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    # Build and execute autoscale command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    # Get HPA status
    let hpa_status = try {
      mut hpa_cmd_args = ["get" "hpa" $deployment_name "--output" "json"]
      if $namespace != null {
        $hpa_cmd_args = ($hpa_cmd_args | append "--namespace" | append $namespace)
      }

      # Build and execute HPA get command
      let full_hpa_cmd = (["kubectl"] | append $hpa_cmd_args)
      print $"Executing: ($full_hpa_cmd | str join ' ')"
      run-external ...$full_hpa_cmd | from json
    } catch {
      {error: "Could not retrieve HPA status immediately"}
    }

    {
      type: "autoscaler_result"
      deployment: $deployment_name
      namespace: $namespace
      configuration: {
        min_replicas: $min_replicas
        max_replicas: $max_replicas
        cpu_target_percent: $cpu_percent
      }
      command: ($full_cmd | str join " ")
      create_output: $result
      hpa_status: $hpa_status
      notes: [
        "HPA requires metrics-server to be installed"
        "Deployment containers must have resource requests set"
        "Use 'kubectl get hpa' to monitor autoscaler status"
      ]
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating autoscaler for deployment ($deployment_name): ($error.msg)"
      suggestions: [
        "Verify deployment exists and is running"
        "Check if metrics-server is installed in the cluster"
        "Ensure deployment containers have resource requests"
        "Confirm you have permission to create HPA resources"
      ]
    } | to json
  }
}

# Scale resource and monitor the progress
def scale_with_monitoring [
  resource_type: string
  name: string
  replicas: int
  namespace?: string
  monitor_duration: string = "2m"
] {
  try {
    # Get initial status
    let initial_status = get_scale_status $resource_type $name $namespace | from json

    # Perform scaling
    let scale_result = scale_resource $resource_type $name $replicas $namespace "10m" | from json

    if $scale_result.type == "error" {
      return ($scale_result | to json)
    }

    # Monitor progress
    let start_time = date now
    let monitor_end = $start_time + ($monitor_duration | into duration)

    mut monitoring_data = []
    mut check_count = 0

    while (date now) < $monitor_end {
      sleep 15sec
      $check_count = $check_count + 1

      let current_status = get_scale_status $resource_type $name $namespace | from json
      let elapsed = (date now) - $start_time

      let status_check = {
        check_number: $check_count
        elapsed_time: $elapsed
        status: $current_status
        scaling_complete: (($current_status | get replica_status -o | get scaling_complete -o) | default false)
      }

      $monitoring_data = ($monitoring_data | append $status_check)

      # Check if scaling is complete
      if $status_check.scaling_complete {
        break
      }
    }

    let final_status = get_scale_status $resource_type $name $namespace | from json
    let total_duration = (date now) - $start_time

    {
      type: "scale_with_monitoring_result"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      target_replicas: $replicas
      initial_status: $initial_status
      scale_result: $scale_result
      monitoring: {
        duration: $monitor_duration
        actual_duration: $total_duration
        checks_performed: $check_count
        monitoring_data: $monitoring_data
      }
      final_status: $final_status
      scaling_completed: (($final_status | get replica_status -o | get scaling_complete -o) | default false)
      summary: $"Scaling monitoring completed after ($check_count) checks over ($total_duration)"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error during scaling with monitoring: ($error.msg)"
    } | to json
  }
}
