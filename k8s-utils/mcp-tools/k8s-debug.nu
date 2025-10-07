# Kubernetes debug tool for nu-mcp

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "debug_pod"
      title: "Debug Pod"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Create debug session for troubleshooting pods - creates ephemeral containers"
      input_schema: {
        type: "object"
        properties: {
          pod_name: {
            type: "string"
            description: "Name of the pod to debug (mandatory for safety)"
          }
          namespace: {
            type: "string"
            description: "Namespace of the pod (mandatory for safety)"
          }
          image: {
            type: "string"
            description: "Debug container image to use"
            default: "busybox:1.35"
          }
          container: {
            type: "string"
            description: "Target container to debug (optional for single-container pods)"
          }
          share_processes: {
            type: "boolean"
            description: "Share process namespace with target container"
            default: true
          }
          copy_to: {
            type: "string"
            description: "Copy target container and run debug commands in the copy"
          }
          replace: {
            type: "boolean"
            description: "Replace the original container with debug container"
            default: false
          }
          command: {
            type: "array"
            items: {type: "string"}
            description: "Command to run in debug container"
            default: ["/bin/sh"]
          }
          attach: {
            type: "boolean"
            description: "Attach to the debug container after creation"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["pod_name", "namespace"]
      }
    }
    {
      name: "debug_node"
      title: "Debug Node"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Create debug session on a node - creates privileged debug pod"
      input_schema: {
        type: "object"
        properties: {
          node_name: {
            type: "string"
            description: "Name of the node to debug (mandatory for safety)"
          }
          image: {
            type: "string"
            description: "Debug container image to use"
            default: "busybox:1.35"
          }
          command: {
            type: "array"
            items: {type: "string"}
            description: "Command to run in debug container"
            default: ["/bin/sh"]
          }
          attach: {
            type: "boolean"
            description: "Attach to the debug container after creation"
            default: false
          }
          profile: {
            type: "string"
            description: "Debug profile to use (general, baseline, restricted, netadmin, sysadmin)"
            default: "general"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["node_name"]
      }
    }
    {
      name: "debug_workload"
      title: "Debug Workload"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Debug workload by creating a copy with debug container"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of workload to debug"
            enum: ["deployment", "replicaset", "job", "cronjob"]
          }
          resource_name: {
            type: "string"
            description: "Name of the workload to debug (mandatory for safety)"
          }
          namespace: {
            type: "string"
            description: "Namespace of the workload (mandatory for safety)"
          }
          image: {
            type: "string"
            description: "Debug container image to use"
            default: "busybox:1.35"
          }
          container: {
            type: "string"
            description: "Target container to debug"
          }
          copy_to: {
            type: "string"
            description: "Name for the debug copy"
          }
          same_node: {
            type: "boolean"
            description: "Schedule debug pod on same node as original"
            default: false
          }
          replace: {
            type: "boolean"
            description: "Replace the original container with debug container"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "resource_name", "namespace"]
      }
    }
    {
      name: "debug_cleanup"
      title: "Debug Cleanup"
      description: "[MODIFIES CLUSTER] Clean up debug resources created by debug sessions"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to clean up debug resources in (optional - cleans all if not specified)"
          }
          label_selector: {
            type: "string"
            description: "Label selector to filter debug resources"
            default: "kubectl.kubernetes.io/debug=true"
          }
          dry_run: {
            type: "boolean"
            description: "Show what would be cleaned up without actually doing it"
            default: false
          }
          force: {
            type: "boolean"
            description: "Force cleanup even if resources are still running"
            default: false
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "list_debug_sessions"
      title: "List Debug Sessions"
      description: "List active debug sessions and resources"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to list debug sessions in (optional - lists all if not specified)"
          }
          show_ephemeral: {
            type: "boolean"
            description: "Include ephemeral containers in output"
            default: true
          }
          show_debug_pods: {
            type: "boolean"
            description: "Include debug pods in output"
            default: true
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "debug_network"
      title: "Debug Network"
      description: "[MODIFIES CLUSTER] [POTENTIALLY DESTRUCTIVE] Create network debugging session with network tools"
      input_schema: {
        type: "object"
        properties: {
          target_pod: {
            type: "string"
            description: "Pod to debug network connectivity for"
          }
          namespace: {
            type: "string"
            description: "Namespace of the target pod (mandatory if target_pod specified)"
          }
          node_name: {
            type: "string"
            description: "Node to debug network on (alternative to target_pod)"
          }
          image: {
            type: "string"
            description: "Network debug image with tools"
            default: "nicolaka/netshoot:latest"
          }
          attach: {
            type: "boolean"
            description: "Attach to the debug container after creation"
            default: false
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
  let parsed_args = $args | from json

  match $tool_name {
    "debug_pod" => {
      let pod_name = $parsed_args.pod_name
      let namespace = $parsed_args.namespace
      let image = $parsed_args.image? | default "busybox:1.35"
      let container = $parsed_args.container?
      let share_processes = $parsed_args.share_processes? | default true
      let copy_to = $parsed_args.copy_to?
      let replace = $parsed_args.replace? | default false
      let command = $parsed_args.command? | default ["/bin/sh"]
      let attach = $parsed_args.attach? | default false
      let delegate_to = $parsed_args.delegate_to?

      debug_pod $pod_name $namespace $image $container $share_processes $copy_to $replace $command $attach $delegate_to
    }
    "debug_node" => {
      let node_name = $parsed_args.node_name
      let image = $parsed_args.image? | default "busybox:1.35"
      let command = $parsed_args.command? | default ["/bin/sh"]
      let attach = $parsed_args.attach? | default false
      let profile = $parsed_args.profile? | default "general"
      let delegate_to = $parsed_args.delegate_to?

      debug_node $node_name $image $command $attach $profile $delegate_to
    }
    "debug_workload" => {
      let resource_type = $parsed_args.resource_type
      let resource_name = $parsed_args.resource_name
      let namespace = $parsed_args.namespace
      let image = $parsed_args.image? | default "busybox:1.35"
      let container = $parsed_args.container?
      let copy_to = $parsed_args.copy_to?
      let same_node = $parsed_args.same_node? | default false
      let replace = $parsed_args.replace? | default false
      let delegate_to = $parsed_args.delegate_to?

      debug_workload $resource_type $resource_name $namespace $image $container $copy_to $same_node $replace $delegate_to
    }
    "debug_cleanup" => {
      let namespace = $parsed_args.namespace?
      let label_selector = $parsed_args.label_selector? | default "kubectl.kubernetes.io/debug=true"
      let dry_run = $parsed_args.dry_run? | default false
      let force = $parsed_args.force? | default false
      let delegate_to = $parsed_args.delegate_to?

      debug_cleanup $namespace $label_selector $dry_run $force $delegate_to
    }
    "list_debug_sessions" => {
      let namespace = $parsed_args.namespace?
      let show_ephemeral = $parsed_args.show_ephemeral? | default true
      let show_debug_pods = $parsed_args.show_debug_pods? | default true
      let delegate_to = $parsed_args.delegate_to?

      list_debug_sessions $namespace $show_ephemeral $show_debug_pods $delegate_to
    }
    "debug_network" => {
      let target_pod = $parsed_args.target_pod?
      let namespace = $parsed_args.namespace?
      let node_name = $parsed_args.node_name?
      let image = $parsed_args.image? | default "nicolaka/netshoot:latest"
      let attach = $parsed_args.attach? | default false
      let delegate_to = $parsed_args.delegate_to?

      debug_network $target_pod $namespace $node_name $image $attach $delegate_to
    }
    _ => {
      error make {msg: $"Unknown tool: ($tool_name)"}
    }
  }
}

# Debug a pod by creating an ephemeral container
def debug_pod [
  pod_name: string
  namespace: string
  image: string = "busybox:1.35"
  container?: string
  share_processes: bool = true
  copy_to?: string
  replace: bool = false
  command: list<string> = ["/bin/sh"]
  attach: bool = false
  delegate_to?: string
] {
  try {
    mut cmd_args = ["debug" $pod_name "--namespace" $namespace "--image" $image]

    if $container != null {
      $cmd_args = ($cmd_args | append "--container" | append $container)
    }

    if $share_processes {
      $cmd_args = ($cmd_args | append "--share-processes")
    }

    if $copy_to != null {
      $cmd_args = ($cmd_args | append "--copy-to" | append $copy_to)
    }

    if $replace {
      $cmd_args = ($cmd_args | append "--replace")
    }

    if not $attach {
      $cmd_args = ($cmd_args | append "--attach=false")
    }

    # Add command
    $cmd_args = ($cmd_args | append "--")
    $cmd_args = ($cmd_args | append $command)

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "debug_pod"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          pod_name: $pod_name
          namespace: $namespace
          image: $image
          container: $container
          share_processes: $share_processes
          copy_to: $copy_to
          replace: $replace
          command: $command
          attach: $attach
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "debug_pod_result"
      operation: "debug_pod"
      target: {
        pod_name: $pod_name
        namespace: $namespace
        container: $container
      }
      debug_config: {
        image: $image
        share_processes: $share_processes
        copy_to: $copy_to
        replace: $replace
        command: $command
        attach: $attach
      }
      command: $cmd_string
      result: $result
      message: $"Debug session created for pod '($pod_name)' in namespace '($namespace)'"
      warning: "Debug containers share the pod's network and can access its filesystems"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating debug session for pod '($pod_name)': ($error.msg)"
      suggestions: [
        "Verify the pod exists and is running"
        "Check that the debug image is available"
        "Ensure you have permission to create ephemeral containers"
        "Verify the container name if specified"
        "Check if the pod supports ephemeral containers"
      ]
    } | to json
  }
}

# Debug a node by creating a privileged debug pod
def debug_node [
  node_name: string
  image: string = "busybox:1.35"
  command: list<string> = ["/bin/sh"]
  attach: bool = false
  profile: string = "general"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["debug" "node" $node_name "--image" $image]

    if not $attach {
      $cmd_args = ($cmd_args | append "--attach=false")
    }

    $cmd_args = ($cmd_args | append "--profile" | append $profile)

    # Add command
    $cmd_args = ($cmd_args | append "--")
    $cmd_args = ($cmd_args | append $command)

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "debug_node_result"
      operation: "debug_node"
      node_name: $node_name
      debug_config: {
        image: $image
        command: $command
        attach: $attach
        profile: $profile
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Debug session created for node '($node_name)'"
      warning: "Node debug pods run with privileged access to the host system"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating debug session for node '($node_name)': ($error.msg)"
      suggestions: [
        "Verify the node name is correct"
        "Check that the debug image is available"
        "Ensure you have permission to create privileged pods"
        "Verify the node is ready and schedulable"
        "Check cluster policy allows privileged containers"
      ]
    } | to json
  }
}

# Debug a workload by creating a copy with debug container
def debug_workload [
  resource_type: string
  resource_name: string
  namespace: string
  image: string = "busybox:1.35"
  container?: string
  copy_to?: string
  same_node: bool = false
  replace: bool = false
  delegate_to?: string
] {
  try {
    mut cmd_args = ["debug" $"($resource_type)/($resource_name)" "--namespace" $namespace "--image" $image]

    if $container != null {
      $cmd_args = ($cmd_args | append "--container" | append $container)
    }

    if $copy_to != null {
      $cmd_args = ($cmd_args | append "--copy-to" | append $copy_to)
    }

    if $same_node {
      $cmd_args = ($cmd_args | append "--same-node")
    }

    if $replace {
      $cmd_args = ($cmd_args | append "--replace")
    }

    # Don't attach by default for workloads
    $cmd_args = ($cmd_args | append "--attach=false")

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "debug_workload_result"
      operation: "debug_workload"
      target: {
        resource_type: $resource_type
        resource_name: $resource_name
        namespace: $namespace
        container: $container
      }
      debug_config: {
        image: $image
        copy_to: $copy_to
        same_node: $same_node
        replace: $replace
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: $"Debug copy created for ($resource_type) '($resource_name)' in namespace '($namespace)'"
      note: "Use 'kubectl get pods' to find the debug pod and 'kubectl exec' to access it"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating debug session for ($resource_type) '($resource_name)': ($error.msg)"
      suggestions: [
        "Verify the resource exists and has running pods"
        "Check that the debug image is available"
        "Ensure you have permission to create pods"
        "Verify the container name if specified"
        "Check resource type is supported for debugging"
      ]
    } | to json
  }
}

# Clean up debug resources
def debug_cleanup [
  namespace?: string
  label_selector: string = "kubectl.kubernetes.io/debug=true"
  dry_run: bool = false
  force: bool = false
  delegate_to?: string
] {
  try {
    mut cmd_args = ["delete" "pods" "--selector" $label_selector]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    } else {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    }

    if $dry_run {
      $cmd_args = ($cmd_args | append "--dry-run=client")
    }

    if $force {
      $cmd_args = ($cmd_args | append "--force" | append "--grace-period=0")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "debug_cleanup_result"
      operation: (if $dry_run { "dry_run_debug_cleanup" } else { "debug_cleanup" })
      scope: (if $namespace != null { $namespace } else { "cluster-wide" })
      label_selector: $label_selector
      options: {
        dry_run: $dry_run
        force: $force
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: (if $dry_run { 
        "Dry run: Would clean up debug resources" 
      } else { 
        "Debug resources cleaned up" 
      })
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error cleaning up debug resources: ($error.msg)"
      suggestions: [
        "Check that debug resources exist to clean up"
        "Verify label selector is correct"
        "Ensure you have permission to delete pods"
        "Use --force if pods are stuck terminating"
      ]
    } | to json
  }
}

# List active debug sessions
def list_debug_sessions [
  namespace?: string
  show_ephemeral: bool = true
  show_debug_pods: bool = true
  delegate_to?: string
] {
  try {
    mut results = {}

    # Get debug pods
    if $show_debug_pods {
      mut debug_pods_cmd = ["get" "pods" "--selector" "kubectl.kubernetes.io/debug=true" "--output" "json"]
      
      if $namespace != null {
        $debug_pods_cmd = ($debug_pods_cmd | append "--namespace" | append $namespace)
      } else {
        $debug_pods_cmd = ($debug_pods_cmd | append "--all-namespaces")
      }

      let debug_pods_full_cmd = (["kubectl"] | append $debug_pods_cmd)
      print $"Executing: ($debug_pods_full_cmd | str join ' ')"
      let debug_pods_result = run-external ...$debug_pods_full_cmd | from json
      $results = ($results | insert debug_pods $debug_pods_result)
    }

    # Get pods with ephemeral containers
    if $show_ephemeral {
      mut ephemeral_cmd = ["get" "pods" "--output" "json"]
      
      if $namespace != null {
        $ephemeral_cmd = ($ephemeral_cmd | append "--namespace" | append $namespace)
      } else {
        $ephemeral_cmd = ($ephemeral_cmd | append "--all-namespaces")
      }

      let ephemeral_full_cmd = (["kubectl"] | append $ephemeral_cmd)
      print $"Executing: ($ephemeral_full_cmd | str join ' ')"
      let ephemeral_result = run-external ...$ephemeral_full_cmd | from json
      
      # Filter pods that have ephemeral containers
      let pods_with_ephemeral = $ephemeral_result.items | where {|pod| 
        ($pod.spec.ephemeralContainers? | length) > 0
      }
      
      $results = ($results | insert ephemeral_containers $pods_with_ephemeral)
    }

    {
      type: "debug_sessions_list"
      operation: "list_debug_sessions"
      scope: (if $namespace != null { $namespace } else { "cluster-wide" })
      options: {
        show_ephemeral: $show_ephemeral
        show_debug_pods: $show_debug_pods
      }
      sessions: $results
      summary: {
        debug_pods: (if $show_debug_pods { $results.debug_pods.items | length } else { 0 })
        ephemeral_containers: (if $show_ephemeral { $results.ephemeral_containers | length } else { 0 })
      }
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error listing debug sessions: ($error.msg)"
      suggestions: [
        "Verify you have permission to list pods"
        "Check that the cluster is accessible"
        "Ensure namespace exists if specified"
      ]
    } | to json
  }
}

# Create a network debugging session
def debug_network [
  target_pod?: string
  namespace?: string
  node_name?: string
  image: string = "nicolaka/netshoot:latest"
  attach: bool = false
  delegate_to?: string
] {
  if $target_pod == null and $node_name == null {
    return ({
      type: "error"
      message: "Must specify either target_pod (with namespace) or node_name"
    } | to json)
  }

  if $target_pod != null and $namespace == null {
    return ({
      type: "error"
      message: "Namespace is required when debugging a specific pod"
    } | to json)
  }

  try {
    mut cmd_args = []

    if $target_pod != null {
      # Debug specific pod
      $cmd_args = ["debug" $target_pod "--namespace" $namespace "--image" $image "--share-processes"]
    } else {
      # Debug node network
      $cmd_args = ["debug" "node" $node_name "--image" $image]
    }

    if not $attach {
      $cmd_args = ($cmd_args | append "--attach=false")
    }

    # Add network debugging command
    $cmd_args = ($cmd_args | append "--" | append "/bin/bash")

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "debug_network_result"
      operation: "debug_network"
      target: (if $target_pod != null { 
        {type: "pod", name: $target_pod, namespace: $namespace} 
      } else { 
        {type: "node", name: $node_name} 
      })
      debug_config: {
        image: $image
        attach: $attach
      }
      command: ($full_cmd | str join " ")
      result: $result
      message: "Network debugging session created with netshoot tools"
      available_tools: [
        "tcpdump", "netstat", "ss", "iptables", "dig", "nslookup", 
        "curl", "wget", "ping", "traceroute", "nmap", "nc"
      ]
      note: "Use 'kubectl exec' to access the debug container and run network diagnostic commands"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error creating network debug session: ($error.msg)"
      suggestions: [
        "Verify the target pod/node exists"
        "Check that the netshoot image is available"
        "Ensure you have permission to create debug containers"
        "Verify network policies allow the debug session"
      ]
    } | to json
  }
}