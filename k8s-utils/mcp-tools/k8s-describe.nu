#!/usr/bin/env nu

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
        required: ["resource_type", "name"]
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
        required: ["resource_type", "label_selector"]
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
        required: ["resource_type", "name"]
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
        required: ["resource_type", "name"]
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
      let resource_type = $parsed_args | get resource_type
      let name = $parsed_args | get name
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let show_events = if "show_events" in $parsed_args { $parsed_args | get show_events } else { true }
      
      describe_resource $resource_type $name $namespace $show_events
    }
    "describe_multiple" => {
      let resource_type = $parsed_args | get resource_type
      let label_selector = $parsed_args | get label_selector
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      let all_namespaces = if "all_namespaces" in $parsed_args { $parsed_args | get all_namespaces } else { false }
      
      describe_multiple $resource_type $label_selector $namespace $all_namespaces
    }
    "get_resource_events" => {
      let resource_type = $parsed_args | get resource_type
      let name = $parsed_args | get name
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      
      get_resource_events $resource_type $name $namespace
    }
    "resource_health_check" => {
      let resource_type = $parsed_args | get resource_type
      let name = $parsed_args | get name
      let namespace = if "namespace" in $parsed_args { $parsed_args | get namespace } else { null }
      
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
    mut cmd = ["kubectl", "describe", $resource_type, $name]
    
    # Add namespace if specified
    if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    # Add show-events flag
    $cmd = ($cmd | append $"--show-events=($show_events)")
    
    let result = run-external $cmd.0 ...$cmd.1..
    
    $"Detailed Description - ($resource_type)/($name):
($result)

Command executed: ($cmd | str join ' ')"
  } catch { |e|
    $"Error describing ($resource_type)/($name): ($e.msg)
Please check:
- Resource exists in the specified namespace
- Resource type is correct
- You have permission to access the resource"
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
    mut cmd = ["kubectl", "describe", $resource_type, "--selector", $label_selector]
    
    # Add namespace options
    if $all_namespaces {
      $cmd = ($cmd | append "--all-namespaces")
    } else if $namespace != null {
      $cmd = ($cmd | append "--namespace" | append $namespace)
    }
    
    let result = run-external $cmd.0 ...$cmd.1..
    
    $"Multiple Resource Description - ($resource_type) with selector '($label_selector)':
($result)

Command executed: ($cmd | str join ' ')"
  } catch { |e|
    $"Error describing resources with selector ($label_selector): ($e.msg)
Please check:
- Label selector syntax is correct
- Resources matching the selector exist
- Namespace is correct (if specified)"
  }
}

# Get events related to a specific resource
def get_resource_events [
  resource_type: string
  name: string
  namespace?: string
] {
  try {
    mut get_cmd = ["kubectl", "get", "events"]
    
    # Add namespace if specified
    if $namespace != null {
      $get_cmd = ($get_cmd | append "--namespace" | append $namespace)
    }
    
    # Filter events by involved object
    $get_cmd = ($get_cmd | append "--field-selector" | append $"involvedObject.name=($name)")
    
    let events_result = run-external $get_cmd.0 ...$get_cmd.1..
    
    # Also get the resource description for context
    mut describe_cmd = ["kubectl", "get", $resource_type, $name, "--output", "yaml"]
    if $namespace != null {
      $describe_cmd = ($describe_cmd | append "--namespace" | append $namespace)
    }
    
    $"Events for ($resource_type)/($name):
($events_result)

Resource Overview:
"
    try {
      let resource_info = run-external $describe_cmd.0 ...$describe_cmd.1.. | from yaml
      let status = if "status" in $resource_info { $resource_info.status } else { "No status available" }
      let phase = if ($status | describe) != "string" and "phase" in $status { $status.phase } else { "Unknown" }
      
      $"Status: ($phase)
Created: ($resource_info.metadata.creationTimestamp)
Labels: ($resource_info.metadata.labels | default {} | transpose key value | each { |row| $"($row.key)=($row.value)" } | str join ', ')"
    } catch {
      "Unable to retrieve resource details"
    }
  } catch { |e|
    $"Error retrieving events for ($resource_type)/($name): ($e.msg)"
  }
}

# Perform a comprehensive health check on a resource
def resource_health_check [
  resource_type: string
  name: string
  namespace?: string
] {
  try {
    mut health_report = [$"Health Check Report for ($resource_type)/($name):"]
    
    # Get basic resource info
    mut get_cmd = ["kubectl", "get", $resource_type, $name, "--output", "json"]
    if $namespace != null {
      $get_cmd = ($get_cmd | append "--namespace" | append $namespace)
    }
    
    let resource_info = run-external $get_cmd.0 ...$get_cmd.1.. | from json
    
    # Check resource status
    $health_report = ($health_report | append "")
    $health_report = ($health_report | append "📊 Resource Status:")
    
    let status = if "status" in $resource_info { $resource_info.status } else { {} }
    
    match $resource_type {
      "pod" => {
        let phase = if "phase" in $status { $status.phase } else { "Unknown" }
        $health_report = ($health_report | append $"  Phase: ($phase)")
        
        if "conditions" in $status {
          $health_report = ($health_report | append "  Conditions:")
          for condition in $status.conditions {
            let status_icon = if $condition.status == "True" { "✅" } else { "❌" }
            $health_report = ($health_report | append $"    ($status_icon) ($condition.type): ($condition.status)")
          }
        }
        
        if "containerStatuses" in $status {
          $health_report = ($health_report | append "  Containers:")
          for container in $status.containerStatuses {
            let ready_icon = if $container.ready { "✅" } else { "❌" }
            $health_report = ($health_report | append $"    ($ready_icon) ($container.name): Ready=($container.ready), Restarts=($container.restartCount)")
          }
        }
      }
      "deployment" => {
        let replicas = if "replicas" in $status { $status.replicas } else { 0 }
        let ready_replicas = if "readyReplicas" in $status { $status.readyReplicas } else { 0 }
        let available_replicas = if "availableReplicas" in $status { $status.availableReplicas } else { 0 }
        
        $health_report = ($health_report | append $"  Replicas: ($ready_replicas)/($replicas) ready, ($available_replicas) available")
        
        if "conditions" in $status {
          for condition in $status.conditions {
            let status_icon = if $condition.status == "True" { "✅" } else { "❌" }
            $health_report = ($health_report | append $"  ($status_icon) ($condition.type): ($condition.reason)")
          }
        }
      }
      "service" => {
        let service_type = if "type" in $resource_info.spec { $resource_info.spec.type } else { "ClusterIP" }
        $health_report = ($health_report | append $"  Type: ($service_type)")
        
        if "clusterIP" in $resource_info.spec {
          $health_report = ($health_report | append $"  Cluster IP: ($resource_info.spec.clusterIP)")
        }
        
        if "ports" in $resource_info.spec {
          $health_report = ($health_report | append "  Ports:")
          for port in $resource_info.spec.ports {
            $health_report = ($health_report | append $"    ($port.port):($port.targetPort)/($port.protocol)")
          }
        }
      }
    }
    
    # Get recent events
    $health_report = ($health_report | append "")
    $health_report = ($health_report | append "📋 Recent Events:")
    
    try {
      mut events_cmd = ["kubectl", "get", "events", "--field-selector", $"involvedObject.name=($name)", "--sort-by", ".lastTimestamp"]
      if $namespace != null {
        $events_cmd = ($events_cmd | append "--namespace" | append $namespace)
      }
      
      let events = run-external $events_cmd.0 ...$events_cmd.1.. | lines | last 5
      for event in $events {
        if ($event | str length) > 0 and not ($event | str starts-with "LAST SEEN") {
          $health_report = ($health_report | append $"  ($event)")
        }
      }
    } catch {
      $health_report = ($health_report | append "  No recent events found")
    }
    
    # Resource age and labels
    $health_report = ($health_report | append "")
    $health_report = ($health_report | append "ℹ️  Resource Info:")
    $health_report = ($health_report | append $"  Created: ($resource_info.metadata.creationTimestamp)")
    $health_report = ($health_report | append $"  Namespace: (if $namespace != null { $namespace } else { $resource_info.metadata.namespace })")
    
    let labels = if "labels" in $resource_info.metadata { $resource_info.metadata.labels } else { {} }
    if ($labels | length) > 0 {
      let label_str = $labels | transpose key value | each { |row| $"($row.key)=($row.value)" } | str join ', '
      $health_report = ($health_report | append $"  Labels: ($label_str)")
    }
    
    $health_report | str join (char newline)
  } catch { |e|
    $"Error performing health check on ($resource_type)/($name): ($e.msg)"
  }
}