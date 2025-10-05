# Kubernetes logs tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "get_logs"
      description: "Get logs from pods, deployments, or other resources"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type (pod, deployment, job, etc.)"
            default: "pod"
          }
          name: {
            type: "string"
            description: "Resource name to get logs from"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional - uses current context if not specified)"
          }
          container: {
            type: "string"
            description: "Container name (optional for single-container pods)"
          }
          previous: {
            type: "boolean"
            description: "Get logs from previous container instance"
            default: false
          }
          since: {
            type: "string"
            description: "Show logs since duration (e.g., '5s', '2m', '3h')"
          }
          since_time: {
            type: "string"
            description: "Show logs since RFC3339 timestamp"
          }
          tail: {
            type: "integer"
            description: "Number of lines to show from end of logs"
          }
          timestamps: {
            type: "boolean"
            description: "Include timestamps in logs"
            default: false
          }
          prefix: {
            type: "boolean"
            description: "Prefix each log line with pod name"
            default: false
          }
          limit_bytes: {
            type: "integer"
            description: "Maximum bytes to return"
          }
        }
        required: ["name"]
      }
    }
    {
      name: "get_logs_selector"
      description: "Get logs from pods matching label selector"
      input_schema: {
        type: "object"
        properties: {
          selector: {
            type: "string"
            description: "Label selector (e.g., 'app=nginx,env=prod')"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional - uses current context if not specified)"
          }
          all_containers: {
            type: "boolean"
            description: "Get logs from all containers in matching pods"
            default: false
          }
          all_pods: {
            type: "boolean"
            description: "Get logs from all matching pods"
            default: true
          }
          max_log_requests: {
            type: "integer"
            description: "Maximum number of concurrent log requests"
            default: 5
          }
          since: {
            type: "string"
            description: "Show logs since duration"
          }
          tail: {
            type: "integer"
            description: "Number of lines from end of logs"
          }
          timestamps: {
            type: "boolean"
            description: "Include timestamps"
            default: false
          }
          prefix: {
            type: "boolean"
            description: "Prefix lines with pod name"
            default: true
          }
        }
        required: ["selector"]
      }
    }
    {
      name: "get_logs_deployment"
      description: "Get logs from all pods in a deployment"
      input_schema: {
        type: "object"
        properties: {
          deployment_name: {
            type: "string"
            description: "Name of the deployment"
          }
          namespace: {
            type: "string"
            description: "Namespace (optional - uses current context if not specified)"
          }
          all_containers: {
            type: "boolean"
            description: "Get logs from all containers"
            default: false
          }
          since: {
            type: "string"
            description: "Show logs since duration"
          }
          tail: {
            type: "integer"
            description: "Number of lines from end"
          }
          timestamps: {
            type: "boolean"
            description: "Include timestamps"
            default: false
          }
          max_log_requests: {
            type: "integer"
            description: "Maximum concurrent requests"
            default: 5
          }
        }
        required: ["deployment_name"]
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
    "get_logs" => {
      let resource_type = $parsed_args.resource_type? | default "pod"
      let name = $parsed_args.name
      let namespace = $parsed_args.namespace?
      let container = $parsed_args.container?
      let previous = $parsed_args.previous? | default false
      let since = $parsed_args.since?
      let since_time = $parsed_args.since_time?
      let tail = $parsed_args.tail?
      let timestamps = $parsed_args.timestamps? | default false
      let prefix = $parsed_args.prefix? | default false
      let limit_bytes = $parsed_args.limit_bytes?

      get_logs $name $namespace $container $resource_type $previous $since $since_time $tail $timestamps $prefix $limit_bytes
    }
    "get_logs_selector" => {
      let selector = $parsed_args.selector
      let namespace = $parsed_args.namespace?
      let all_containers = $parsed_args.all_containers? | default false
      let all_pods = $parsed_args.all_pods? | default true
      let max_log_requests = $parsed_args.max_log_requests? | default 5
      let since = $parsed_args.since?
      let tail = $parsed_args.tail?
      let timestamps = $parsed_args.timestamps? | default false
      let prefix = $parsed_args.prefix? | default true

      get_logs_selector $selector $namespace $all_containers $all_pods $max_log_requests $since $tail $timestamps $prefix
    }
    "get_logs_deployment" => {
      let deployment_name = $parsed_args.deployment_name
      let namespace = $parsed_args.namespace?
      let all_containers = $parsed_args.all_containers? | default false
      let since = $parsed_args.since?
      let tail = $parsed_args.tail?
      let timestamps = $parsed_args.timestamps? | default false
      let max_log_requests = $parsed_args.max_log_requests? | default 5

      get_logs_deployment $deployment_name $namespace $all_containers $since $tail $timestamps $max_log_requests
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Get logs from a specific resource
def get_logs [
  name: string
  namespace?: string
  container?: string
  resource_type: string = "pod"
  previous: bool = false
  since?: string
  since_time?: string
  tail?: int
  timestamps: bool = false
  prefix: bool = false
  limit_bytes?: int
] {
  try {
    mut cmd_args = ["logs"]

    # Add resource type and name
    if $resource_type != "pod" {
      $cmd_args = ($cmd_args | append $"($resource_type)/($name)")
    } else {
      $cmd_args = ($cmd_args | append $name)
    }

    # Add namespace if specified
    if $namespace != null {
      if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }
    }

    # Add container if specified
    if $container != null {
      $cmd_args = ($cmd_args | append "--container" | append $container)
    }

    # Add previous flag if requested
    if $previous {
      $cmd_args = ($cmd_args | append "--previous")
    }

    # Add time-based filtering
    if $since != null {
      $cmd_args = ($cmd_args | append "--since" | append $since)
    }

    if $since_time != null {
      $cmd_args = ($cmd_args | append "--since-time" | append $since_time)
    }

    # Add tail if specified
    if $tail != null {
      $cmd_args = ($cmd_args | append "--tail" | append ($tail | into string))
    }

    # Add timestamps if requested
    if $timestamps {
      $cmd_args = ($cmd_args | append "--timestamps")
    }

    # Add prefix if requested
    if $prefix {
      $cmd_args = ($cmd_args | append "--prefix")
    }

    # Add limit bytes if specified
    if $limit_bytes != null {
      $cmd_args = ($cmd_args | append "--limit-bytes" | append ($limit_bytes | into string))
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "logs_result"
      resource: {
        type: $resource_type
        name: $name
        namespace: $namespace
        container: $container
      }
      options: {
        previous: $previous
        since: $since
        since_time: $since_time
        tail: $tail
        timestamps: $timestamps
        prefix: $prefix
        limit_bytes: $limit_bytes
      }
      command: ($full_cmd | str join " ")
      logs: $result
      log_lines: ($result | lines | length)
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting logs from ($resource_type) '($name)': ($error.msg)"
      suggestions: [
        "Verify the resource exists and is running"
        "Check container name for multi-container pods"
        "Ensure you have permission to view logs"
        "Try without --previous flag if container hasn't restarted"
        "Verify namespace is correct"
      ]
    } | to json
  }
}

# Get logs from pods matching a selector
def get_logs_selector [
  selector: string
  namespace?: string
  all_containers: bool = false
  all_pods: bool = true
  max_log_requests: int = 5
  since?: string
  tail?: int
  timestamps: bool = false
  prefix: bool = true
] {
  try {
    mut cmd_args = ["logs" "--selector" $selector]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $all_containers {
      $cmd_args = ($cmd_args | append "--all-containers")
    }

    if $all_pods {
      $cmd_args = ($cmd_args | append "--all-pods")
    }

    if $max_log_requests != 5 {
      $cmd_args = ($cmd_args | append "--max-log-requests" | append ($max_log_requests | into string))
    }

    if $since != null {
      $cmd_args = ($cmd_args | append "--since" | append $since)
    }

    if $tail != null {
      $cmd_args = ($cmd_args | append "--tail" | append ($tail | into string))
    }

    if $timestamps {
      $cmd_args = ($cmd_args | append "--timestamps")
    }

    if $prefix {
      $cmd_args = ($cmd_args | append "--prefix")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "logs_selector_result"
      selector: $selector
      scope: (if $namespace != null { $namespace } else { "current_namespace" })
      options: {
        all_containers: $all_containers
        all_pods: $all_pods
        max_log_requests: $max_log_requests
        since: $since
        tail: $tail
        timestamps: $timestamps
        prefix: $prefix
      }
      command: ($full_cmd | str join " ")
      logs: $result
      log_lines: ($result | lines | length)
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting logs with selector '($selector)': ($error.msg)"
      suggestions: [
        "Verify the selector syntax is correct"
        "Check that pods with this selector exist"
        "Ensure you have permission to view logs"
        "Try reducing max-log-requests if hitting limits"
      ]
    } | to json
  }
}

# Get logs from all pods in a deployment
def get_logs_deployment [
  deployment_name: string
  namespace?: string
  all_containers: bool = false
  since?: string
  tail?: int
  timestamps: bool = false
  max_log_requests: int = 5
] {
  try {
    # Use selector to get logs from deployment pods
    let selector = $"app=($deployment_name)"
    
    mut cmd_args = ["logs" "--selector" $selector]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $all_containers {
      $cmd_args = ($cmd_args | append "--all-containers")
    }

    $cmd_args = ($cmd_args | append "--max-log-requests" | append ($max_log_requests | into string))

    if $since != null {
      $cmd_args = ($cmd_args | append "--since" | append $since)
    }

    if $tail != null {
      $cmd_args = ($cmd_args | append "--tail" | append ($tail | into string))
    }

    if $timestamps {
      $cmd_args = ($cmd_args | append "--timestamps")
    }

    # Always prefix for deployment logs
    $cmd_args = ($cmd_args | append "--prefix")

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "deployment_logs_result"
      deployment: $deployment_name
      namespace: (if $namespace != null { $namespace } else { "current_namespace" })
      selector_used: $selector
      options: {
        all_containers: $all_containers
        since: $since
        tail: $tail
        timestamps: $timestamps
        max_log_requests: $max_log_requests
      }
      command: ($full_cmd | str join " ")
      logs: $result
      log_lines: ($result | lines | length)
      note: "Logs retrieved from all pods matching deployment label selector"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting deployment logs for '($deployment_name)': ($error.msg)"
      suggestions: [
        "Verify the deployment exists"
        "Check that the deployment has running pods"
        "Ensure deployment uses standard 'app' label"
        "Try with a custom selector if deployment uses different labels"
      ]
    } | to json
  }
}