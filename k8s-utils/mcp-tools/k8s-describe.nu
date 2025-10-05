# Kubernetes resource description tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "describe_resource"
      description: "Get detailed description of Kubernetes resources including events and relationships"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type (e.g., pod, deployment, service, node)"
          }
          name: {
            type: "string"
            description: "Resource name to describe"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional - uses current context if not specified)"
          }
          show_events: {
            type: "boolean"
            description: "Include related events in the description"
            default: true
          }
        }
        required: ["resource_type" "name"]
      }
    }
    {
      name: "describe_multiple"
      description: "Describe multiple resources by label selector"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type to describe"
          }
          label_selector: {
            type: "string"
            description: "Label selector to match resources (e.g., 'app=nginx')"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional)"
          }
          all_namespaces: {
            type: "boolean"
            description: "Search across all namespaces"
            default: false
          }
        }
        required: ["resource_type" "label_selector"]
      }
    }
    {
      name: "get_resource_events"
      description: "Get events related to a specific resource"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type"
          }
          name: {
            type: "string"
            description: "Resource name"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional)"
          }
        }
        required: ["resource_type" "name"]
      }
    }
    {
      name: "resource_health_check"
      description: "Perform a health check on a resource and its dependencies"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type (pod, deployment, service)"
          }
          name: {
            type: "string"
            description: "Resource name"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional)"
          }
        }
        required: ["resource_type" "name"]
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
    "describe_resource" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace?
      let show_events = $parsed_args.show_events? | default true

      describe_resource $resource_type $name $namespace $show_events
    }
    "describe_multiple" => {
      let resource_type = $parsed_args.resource_type
      let label_selector = $parsed_args.label_selector
      let namespace = $parsed_args.namespace?
      let all_namespaces = $parsed_args.all_namespaces? | default false

      describe_multiple $resource_type $label_selector $namespace $all_namespaces
    }
    "get_resource_events" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace?

      get_resource_events $resource_type $name $namespace
    }
    "resource_health_check" => {
      let resource_type = $parsed_args.resource_type
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace?

      resource_health_check $resource_type $name $namespace
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Describe a specific Kubernetes resource
def describe_resource [
  resource_type: string
  name: string
  namespace?: string
  show_events: bool = true
] {
  try {
    mut cmd_args = ["describe" $resource_type $name]

    # Add namespace if specified
    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    # Add show-events flag
    $cmd_args = ($cmd_args | append $"--show-events=($show_events)")

    # Build and execute the command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "resource_description"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      command: ($full_cmd | str join " ")
      description: $result
      events_included: $show_events
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error describing ($resource_type)/($name): ($error.msg)"
      suggestions: [
        "Verify resource exists in the specified namespace"
        "Check resource type spelling"
        "Ensure you have permission to access the resource"
      ]
    } | to json
  }
}

# Describe multiple resources using label selector
def describe_multiple [
  resource_type: string
  label_selector: string
  namespace?: string
  all_namespaces: bool = false
] {
  try {
    mut cmd_args = ["describe" $resource_type "--selector" $label_selector]

    # Add namespace options
    if $all_namespaces {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    } else if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    # Build and execute the command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "multiple_resource_description"
      filter: {
        resource_type: $resource_type
        label_selector: $label_selector
        namespace: $namespace
        all_namespaces: $all_namespaces
      }
      command: ($full_cmd | str join " ")
      description: $result
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error describing resources with selector ($label_selector): ($error.msg)"
      suggestions: [
        "Check label selector syntax"
        "Verify resources matching the selector exist"
        "Ensure namespace is correct"
      ]
    } | to json
  }
}

# Get events related to a specific resource
def get_resource_events [
  resource_type: string
  name: string
  namespace?: string
] {
  try {
    mut events_cmd_args = ["get" "events"]

    # Add namespace if specified
    if $namespace != null {
      $events_cmd_args = ($events_cmd_args | append "--namespace" | append $namespace)
    }

    # Filter events by involved object
    $events_cmd_args = ($events_cmd_args | append "--field-selector" | append $"involvedObject.name=($name)")

    # Build and execute the events command
    let full_events_cmd = (["kubectl"] | append $events_cmd_args)
    print $"Executing: ($full_events_cmd | str join ' ')"
    let events_result = run-external ...$full_events_cmd

    # Also get basic resource info for context
    let resource_info = try {
      mut info_cmd_args = ["get" $resource_type $name "--output" "json"]
      if $namespace != null {
        $info_cmd_args = ($info_cmd_args | append "--namespace" | append $namespace)
      }

      # Build and execute the info command
      let full_info_cmd = (["kubectl"] | append $info_cmd_args)
      print $"Executing: ($full_info_cmd | str join ' ')"
      let raw_info = run-external ...$full_info_cmd | from json
      {
        created: $raw_info.metadata?.creationTimestamp?
        labels: ($raw_info.metadata?.labels? | default {})
        status: $raw_info.status?
      }
    } catch {
      {error: "Could not retrieve resource details"}
    }

    {
      type: "resource_events"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
      }
      events: $events_result
      resource_info: $resource_info
      commands_executed: [
        ($full_events_cmd | str join " ")
      ]
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error retrieving events for ($resource_type)/($name): ($error.msg)"
    } | to json
  }
}

# Perform a comprehensive health check on a resource
def resource_health_check [
  resource_type: string
  name: string
  namespace?: string
] {
  try {
    # Get basic resource info
    mut get_cmd_args = ["get" $resource_type $name "--output" "json"]
    if $namespace != null {
      $get_cmd_args = ($get_cmd_args | append "--namespace" | append $namespace)
    }

    # Build and execute the get command
    let full_get_cmd = (["kubectl"] | append $get_cmd_args)
    print $"Executing: ($full_get_cmd | str join ' ')"
    let resource_info = run-external ...$full_get_cmd | from json

    # Build health status based on resource type
    let health_status = match $resource_type {
      "pod" => {
        let phase = $resource_info.status?.phase? | default "Unknown"
        let conditions = $resource_info.status?.conditions? | default []
        let container_statuses = $resource_info.status?.containerStatuses? | default []

        {
          phase: $phase
          conditions: (
            $conditions | each {|cond|
              {
                type: $cond.type
                status: $cond.status
                ready: ($cond.status == "True")
              }
            }
          )
          containers: (
            $container_statuses | each {|cont|
              {
                name: $cont.name
                ready: $cont.ready
                restart_count: $cont.restartCount
                state: $cont.state
              }
            }
          )
          overall_health: (if $phase == "Running" { "healthy" } else if $phase == "Pending" { "pending" } else { "unhealthy" })
        }
      }
      "deployment" => {
        let replicas = $resource_info.status?.replicas? | default 0
        let ready_replicas = $resource_info.status?.readyReplicas? | default 0
        let available_replicas = $resource_info.status?.availableReplicas? | default 0
        let conditions = $resource_info.status?.conditions? | default []

        {
          replicas: {
            desired: $replicas
            ready: $ready_replicas
            available: $available_replicas
          }
          conditions: (
            $conditions | each {|cond|
              {
                type: $cond.type
                status: $cond.status
                reason: $cond.reason?
              }
            }
          )
          overall_health: (if $ready_replicas == $replicas and $available_replicas == $replicas { "healthy" } else { "degraded" })
        }
      }
      "service" => {
        let service_type = $resource_info.spec?.type? | default "ClusterIP"
        let cluster_ip = $resource_info.spec?.clusterIP?
        let ports = $resource_info.spec?.ports? | default []

        {
          type: $service_type
          cluster_ip: $cluster_ip
          ports: (
            $ports | each {|port|
              {
                port: $port.port
                target_port: $port.targetPort
                protocol: $port.protocol
              }
            }
          )
          overall_health: "active"
        }
      }
      _ => {
        {
          status: "unknown_resource_type"
          overall_health: "unknown"
        }
      }
    }

    # Get recent events
    let recent_events = try {
      mut events_cmd_args = ["get" "events" "--field-selector" $"involvedObject.name=($name)" "--sort-by" ".lastTimestamp"]
      if $namespace != null {
        $events_cmd_args = ($events_cmd_args | append "--namespace" | append $namespace)
      }

      # Build and execute the events command
      let full_events_cmd = (["kubectl"] | append $events_cmd_args)
      print $"Executing: ($full_events_cmd | str join ' ')"
      run-external ...$full_events_cmd | lines | last 5
    } catch {
      []
    }

    {
      type: "health_check"
      resource: {
        type: $resource_type
        name: $name
        namespace: ($namespace | default $resource_info.metadata?.namespace?)
        created: $resource_info.metadata?.creationTimestamp?
        labels: ($resource_info.metadata?.labels? | default {})
      }
      health_status: $health_status
      recent_events: $recent_events
      timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error performing health check on ($resource_type)/($name): ($error.msg)"
    } | to json
  }
}

