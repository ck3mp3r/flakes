#!/usr/bin/env nu

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
      description: "[MODIFIES CLUSTER] Scale deployments, replica sets, or stateful sets"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Resource type to scale (deployment, replicaset, statefulset)"
            enum: ["deployment", "replicaset", "statefulset", "replicationcontroller"]
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
        required: ["resource_type", "name", "replicas"]
      }
    }
    {
      name: "scale_multiple"
      description: "[MODIFIES CLUSTER] Scale multiple resources at once"
      input_schema: {
        type: "object"
        properties: {
          resources: {
            type: "array"
            items: {
              type: "object"
              properties: {
                resource_type: { type: "string" }
                name: { type: "string" }
                replicas: { type: "integer" }
                namespace: { type: "string" }
              }
              required: ["resource_type", "name", "replicas"]
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
            description: "Namespace (optional)"
          }
        }
        required: ["resource_type", "name"]
      }
    }
    {
      name: "autoscale_deployment"
      description: "[MODIFIES CLUSTER] Set up horizontal pod autoscaling for a deployment"
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
            description: "Namespace (optional)"
          }
        }
        required: ["deployment_name", "min_replicas", "max_replicas"]
      }
    }
    {
      name: "scale_with_monitoring"
      description: "[MODIFIES CLUSTER] Scale resource and monitor the scaling progress"
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
            description: "Namespace (optional)"
          }
          monitor_duration: {
            type: "string"
            description: "How long to monitor after scaling (e.g., '2m')"
            default: "2m"
          }
        }
        required: ["resource_type", "name", "replicas"]
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
      let resource_type = $parsed_args | get resource_type
      let name = $parsed_args | get name
      let replicas = $parsed_args | get replicas
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let current_replicas = if "current_replicas" in $parsed_args { $parsed_args | get current_replicas } else { null }
      let timeout = if "timeout" in $parsed_args { $parsed_args | get timeout } else { "5m" }
      
      scale_resource $resource_type $name $replicas $namespace $current_replicas $timeout
    }
    "scale_multiple" => {
      let resources = $parsed_args | get resources
      let timeout = if "timeout" in $parsed_args { $parsed_args | get timeout } else { "5m" }
      
      scale_multiple $resources $timeout
    }
    "get_scale_status" => {
      let resource_type = $parsed_args | get resource_type
      let name = $parsed_args | get name
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      
      get_scale_status $resource_type $name $namespace
    }
    "autoscale_deployment" => {
      let deployment_name = $parsed_args | get deployment_name
      let min_replicas = $parsed_args | get min_replicas
      let max_replicas = $parsed_args | get max_replicas
      let cpu_percent = if "cpu_percent" in $parsed_args { $parsed_args | get cpu_percent } else { 80 }
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      
      autoscale_deployment $deployment_name $min_replicas $max_replicas $cpu_percent $namespace
    }
    "scale_with_monitoring" => {
      let resource_type = $parsed_args | get resource_type
      let name = $parsed_args | get name
      let replicas = $parsed_args | get replicas
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let monitor_duration = if "monitor_duration" in $parsed_args { $parsed_args | get monitor_duration } else { "2m" }
      
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
  current_replicas?: int
  timeout: string = "5m"
] {
  try {
    mut cmd = ["kubectl", "scale", $resource_type, $name, $"--replicas=($replicas)"]
    
    # Add namespace if specified
    if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    # Add current replicas precondition if specified
    if $current_replicas != null {
      $cmd = ($cmd | append $"--current-replicas=($current_replicas)")
    }
    
    # Add timeout
    $cmd = ($cmd | append $"--timeout=($timeout)")
    
    let result = run-external $cmd.0 ...$cmd.1..
    
    # Get current status after scaling
    let status = get_scale_status $resource_type $name $namespace
    
    $"Scaling Operation Completed:
($result)

Current Status:
($status)

Command executed: ($cmd | str join ' ')"
  } catch { |e|
    $"Error scaling ($resource_type)/($name): ($e.msg)
Please check:
- Resource exists and is scalable
- Current replica count matches precondition (if specified)
- You have permission to scale the resource
- Timeout is sufficient for the scaling operation"
  }
}

# Scale multiple resources at once
def scale_multiple [
  resources: list<record>
  timeout: string = "5m"
] {
  mut results = ["Scaling Multiple Resources:"]
  
  for resource in $resources {
    try {
      let resource_type = $resource | get resource_type
      let name = $resource | get name
      let replicas = $resource | get replicas
      let namespace = if "namespace" in $resource { $resource | get namespace } else { null }
      
      $results = ($results | append $"")
      $results = ($results | append $"📊 Scaling ($resource_type)/($name) to ($replicas) replicas...")
      
      let scale_result = scale_resource $resource_type $name $replicas $namespace null $timeout
      $results = ($results | append $scale_result)
      $results = ($results | append $"✅ ($resource_type)/($name) scaling initiated")
    } catch { |e|
      $results = ($results | append $"❌ Failed to scale ($resource.resource_type)/($resource.name): ($e.msg)")
    }
  }
  
  $results | str join (char newline)
}

# Get current scaling status and replica information
def get_scale_status [
  resource_type: string
  name: string
  namespace?: string
] {
  try {
    mut get_cmd = ["kubectl", "get", $resource_type, $name, "--output", "json"]
    
    if $namespace != null {
      $get_cmd = ($get_cmd | append "--namespace" | append $namespace)
    }
    
    let resource_info = run-external $get_cmd.0 ...$get_cmd.1.. | from json
    
    let spec = $resource_info.spec
    let status = $resource_info.status
    
    mut status_lines = [$"Scale Status for ($resource_type)/($name):"]
    
    # Get replica information based on resource type
    match $resource_type {
      "deployment" => {
        let desired = if "replicas" in $spec { $spec.replicas } else { 1 }
        let current = if "replicas" in $status { $status.replicas } else { 0 }
        let ready = if "readyReplicas" in $status { $status.readyReplicas } else { 0 }
        let available = if "availableReplicas" in $status { $status.availableReplicas } else { 0 }
        let updated = if "updatedReplicas" in $status { $status.updatedReplicas } else { 0 }
        
        $status_lines = ($status_lines | append $"  Desired Replicas: ($desired)")
        $status_lines = ($status_lines | append $"  Current Replicas: ($current)")
        $status_lines = ($status_lines | append $"  Ready Replicas: ($ready)")
        $status_lines = ($status_lines | append $"  Available Replicas: ($available)")
        $status_lines = ($status_lines | append $"  Updated Replicas: ($updated)")
        
        # Check if scaling is complete
        if $current == $desired and $ready == $desired {
          $status_lines = ($status_lines | append $"  Status: ✅ Scaling Complete")
        } else {
          $status_lines = ($status_lines | append $"  Status: 🔄 Scaling in Progress")
        }
      }
      "replicaset" => {
        let desired = if "replicas" in $spec { $spec.replicas } else { 1 }
        let current = if "replicas" in $status { $status.replicas } else { 0 }
        let ready = if "readyReplicas" in $status { $status.readyReplicas } else { 0 }
        
        $status_lines = ($status_lines | append $"  Desired Replicas: ($desired)")
        $status_lines = ($status_lines | append $"  Current Replicas: ($current)")
        $status_lines = ($status_lines | append $"  Ready Replicas: ($ready)")
        
        if $current == $desired and $ready == $desired {
          $status_lines = ($status_lines | append $"  Status: ✅ Scaling Complete")
        } else {
          $status_lines = ($status_lines | append $"  Status: 🔄 Scaling in Progress")
        }
      }
      "statefulset" => {
        let desired = if "replicas" in $spec { $spec.replicas } else { 1 }
        let current = if "replicas" in $status { $status.replicas } else { 0 }
        let ready = if "readyReplicas" in $status { $status.readyReplicas } else { 0 }
        let updated = if "updatedReplicas" in $status { $status.updatedReplicas } else { 0 }
        
        $status_lines = ($status_lines | append $"  Desired Replicas: ($desired)")
        $status_lines = ($status_lines | append $"  Current Replicas: ($current)")
        $status_lines = ($status_lines | append $"  Ready Replicas: ($ready)")
        $status_lines = ($status_lines | append $"  Updated Replicas: ($updated)")
        
        if $current == $desired and $ready == $desired {
          $status_lines = ($status_lines | append $"  Status: ✅ Scaling Complete")
        } else {
          $status_lines = ($status_lines | append $"  Status: 🔄 Scaling in Progress")
        }
      }
    }
    
    # Add timing information
    $status_lines = ($status_lines | append $"  Created: ($resource_info.metadata.creationTimestamp)")
    
    if "conditions" in $status {
      $status_lines = ($status_lines | append $"  Conditions:")
      for condition in $status.conditions {
        let status_icon = if $condition.status == "True" { "✅" } else { "❌" }
        $status_lines = ($status_lines | append $"    ($status_icon) ($condition.type): ($condition.status)")
      }
    }
    
    $status_lines | str join (char newline)
  } catch { |e|
    $"Error getting scale status for ($resource_type)/($name): ($e.msg)"
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
    mut cmd = ["kubectl", "autoscale", "deployment", $deployment_name]
    $cmd = ($cmd | append $"--min=($min_replicas)" | append $"--max=($max_replicas)")
    $cmd = ($cmd | append $"--cpu-percent=($cpu_percent)")
    
    if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    let result = run-external $cmd.0 ...$cmd.1..
    
    # Get HPA status
    try {
      mut hpa_cmd = ["kubectl", "get", "hpa", $deployment_name, "--output", "wide"]
      if $namespace != null {
        $hpa_cmd = ($hpa_cmd | append "--namespace" | append $namespace)
      }
      
      let hpa_status = run-external $hpa_cmd.0 ...$hpa_cmd.1..
      
      $"Horizontal Pod Autoscaler Created:
($result)

Current HPA Status:
($hpa_status)

Configuration:
- Deployment: ($deployment_name)
- Min Replicas: ($min_replicas)
- Max Replicas: ($max_replicas)
- Target CPU: ($cpu_percent)%

Command executed: ($cmd | str join ' ')"
    } catch {
      $"Horizontal Pod Autoscaler Created:
($result)

Note: HPA status could not be retrieved immediately.
Use 'kubectl get hpa' to check status later."
    }
  } catch { |e|
    $"Error creating autoscaler for deployment ($deployment_name): ($e.msg)
Please check:
- Deployment exists and is running
- Metrics server is installed in the cluster
- Resource requests are set on the deployment containers
- You have permission to create HPA resources"
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
    let initial_status = get_scale_status $resource_type $name $namespace
    
    # Perform scaling
    let scale_result = scale_resource $resource_type $name $replicas $namespace null "10m"
    
    # Monitor progress
    let start_time = date now
    let monitor_end = $start_time + ($monitor_duration | into duration)
    
    mut monitoring_results = [$"Scaling and Monitoring ($resource_type)/($name):"]
    $monitoring_results = ($monitoring_results | append $"")
    $monitoring_results = ($monitoring_results | append $"Initial Status:")
    $monitoring_results = ($monitoring_results | append $initial_status)
    $monitoring_results = ($monitoring_results | append $"")
    $monitoring_results = ($monitoring_results | append $"Scaling Result:")
    $monitoring_results = ($monitoring_results | append $scale_result)
    $monitoring_results = ($monitoring_results | append $"")
    $monitoring_results = ($monitoring_results | append $"Monitoring Progress for ($monitor_duration):")
    
    # Monitor for the specified duration
    mut check_count = 0
    while (date now) < $monitor_end {
      sleep 15sec
      $check_count = $check_count + 1
      
      let current_status = get_scale_status $resource_type $name $namespace
      let elapsed = (date now) - $start_time
      
      $monitoring_results = ($monitoring_results | append $"")
      $monitoring_results = ($monitoring_results | append $"Check #($check_count) (($elapsed | format duration sec) elapsed):")
      $monitoring_results = ($monitoring_results | append $current_status)
      
      # Check if scaling is complete
      if ($current_status | str contains "✅ Scaling Complete") {
        $monitoring_results = ($monitoring_results | append $"")
        $monitoring_results = ($monitoring_results | append $"🎉 Scaling completed successfully!")
        break
      }
    }
    
    $monitoring_results = ($monitoring_results | append $"")
    $monitoring_results = ($monitoring_results | append $"Monitoring completed at (date now)")
    
    $monitoring_results | str join (char newline)
  } catch { |e|
    $"Error during scaling with monitoring: ($e.msg)"
  }
}