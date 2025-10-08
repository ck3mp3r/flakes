# Kubernetes events monitoring tool for nu-mcp

use nu-mcp-lib *

# Default main command
def main [] {
  help main
}

# List available MCP tools
def "main list-tools" [] {
  [
    {
      name: "get_events"
      title: "Get Cluster Events"
      description: "List cluster events with filtering and sorting options"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to get events from (optional - gets cluster-wide if not specified)"
          }
          all_namespaces: {
            type: "boolean"
            description: "Get events from all namespaces"
            default: false
          }
          field_selector: {
            type: "string"
            description: "Filter events by field (e.g., 'involvedObject.name=pod-name')"
          }
          sort_by: {
            type: "string"
            description: "Sort events by field"
            enum: ["firstTimestamp", "lastTimestamp", "count", "name", "reason", "type"]
            default: "lastTimestamp"
          }
          limit: {
            type: "integer"
            description: "Maximum number of events to return"
            default: 100
          }
          since: {
            type: "string"
            description: "Show events since relative time (e.g., '10m', '1h', '2d')"
          }
          output: {
            type: "string"
            description: "Output format"
            enum: ["wide", "json", "yaml", "custom"]
            default: "wide"
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
      output_schema: {
        type: "object"
        properties: {
          type: {type: "string"}
          events: {type: "array", items: {type: "object"}}
          command: {type: "string"}
        }
        required: ["type", "events", "command"]
      }
    }
    {
      name: "get_events_for_object"
      title: "Get Events for Object"
      description: "Get events for a specific Kubernetes object"
      input_schema: {
        type: "object"
        properties: {
          resource_type: {
            type: "string"
            description: "Type of resource (pod, deployment, service, etc.)"
          }
          resource_name: {
            type: "string"
            description: "Name of the resource"
          }
          namespace: {
            type: "string"
            description: "Namespace of the resource (optional for cluster-scoped resources)"
          }
          sort_by: {
            type: "string"
            description: "Sort events by field"
            enum: ["firstTimestamp", "lastTimestamp", "count", "name", "reason", "type"]
            default: "lastTimestamp"
          }
          limit: {
            type: "integer"
            description: "Maximum number of events to return"
            default: 50
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
        required: ["resource_type", "resource_name"]
      }
    }
    {
      name: "watch_events"
      title: "Watch Events"
      description: "Watch events in real-time (streaming requires delegation) or get recent events snapshot"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to watch events in (optional - watches cluster-wide if not specified)"
          }
          all_namespaces: {
            type: "boolean"
            description: "Watch events from all namespaces"
            default: false
          }
          field_selector: {
            type: "string"
            description: "Filter events by field"
          }
          resource_version: {
            type: "string"
            description: "Start watching from specific resource version (only used when delegating)"
          }
          timeout: {
            type: "string"
            description: "Timeout for watch operation (e.g., '5m', '1h') - only used when delegating"
            default: "5m"
          }
          max_events: {
            type: "integer"
            description: "Maximum number of events to capture"
            default: 100
          }
          delegate_to: {
            type: "string"
            description: "REQUIRED for streaming/watch operations. Return command for delegation (e.g., 'tmux', 'screen', 'bash'). Without delegation, returns recent events snapshot."
          }
        }
      }
    }
    {
      name: "filter_events"
      title: "Filter Events"
      description: "Filter and analyze events with advanced criteria"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to filter events from (optional)"
          }
          event_type: {
            type: "string"
            description: "Filter by event type"
            enum: ["Normal", "Warning"]
          }
          reason: {
            type: "string"
            description: "Filter by event reason (e.g., 'Failed', 'Pulled', 'Started')"
          }
          involved_object_kind: {
            type: "string"
            description: "Filter by involved object kind (Pod, Deployment, etc.)"
          }
          involved_object_name: {
            type: "string"
            description: "Filter by involved object name"
          }
          message_contains: {
            type: "string"
            description: "Filter events containing specific text in message"
          }
          since: {
            type: "string"
            description: "Show events since relative time"
          }
          until: {
            type: "string"
            description: "Show events until relative time"
          }
          min_count: {
            type: "integer"
            description: "Filter events with count >= this value"
          }
          sort_by: {
            type: "string"
            description: "Sort filtered events by field"
            enum: ["firstTimestamp", "lastTimestamp", "count", "name", "reason", "type"]
            default: "lastTimestamp"
          }
          limit: {
            type: "integer"
            description: "Maximum number of events to return"
            default: 100
          }
          delegate_to: {
            type: "string"
            description: "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
          }
        }
      }
    }
    {
      name: "events_summary"
      title: "Events Summary"
      description: "Generate summary and statistics of cluster events"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to analyze (optional - analyzes cluster-wide if not specified)"
          }
          time_window: {
            type: "string"
            description: "Time window to analyze (e.g., '1h', '6h', '24h')"
            default: "1h"
          }
          group_by: {
            type: "string"
            description: "Group events by field"
            enum: ["reason", "type", "involvedObject.kind", "namespace", "source.component"]
            default: "reason"
          }
          include_normal: {
            type: "boolean"
            description: "Include Normal events in summary"
            default: true
          }
          include_warning: {
            type: "boolean"
            description: "Include Warning events in summary"
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
      name: "top_events"
      title: "Top Events"
      description: "Show most frequent or recent events"
      input_schema: {
        type: "object"
        properties: {
          namespace: {
            type: "string"
            description: "Namespace to analyze (optional)"
          }
          metric: {
            type: "string"
            description: "Metric to rank by"
            enum: ["count", "recent", "warning"]
            default: "count"
          }
          limit: {
            type: "integer"
            description: "Number of top events to show"
            default: 10
          }
          time_window: {
            type: "string"
            description: "Time window to consider"
            default: "1h"
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
    "get_events" => {
      let namespace = $parsed_args.namespace?
      let all_namespaces = $parsed_args.all_namespaces? | default false
      let field_selector = $parsed_args.field_selector?
      let sort_by = $parsed_args.sort_by? | default "lastTimestamp"
      let limit = $parsed_args.limit? | default 100
      let since = $parsed_args.since?
      let output = $parsed_args.output? | default "wide"
      let delegate_to = $parsed_args.delegate_to?

      get_events $namespace $all_namespaces $field_selector $sort_by $limit $since $output $delegate_to
    }
    "get_events_for_object" => {
      let resource_type = $parsed_args.resource_type
      let resource_name = $parsed_args.resource_name
      let namespace = $parsed_args.namespace?
      let sort_by = $parsed_args.sort_by? | default "lastTimestamp"
      let limit = $parsed_args.limit? | default 50
      let delegate_to = $parsed_args.delegate_to?

      get_events_for_object $resource_type $resource_name $namespace $sort_by $limit $delegate_to
    }
    "watch_events" => {
      let namespace = $parsed_args.namespace?
      let all_namespaces = $parsed_args.all_namespaces? | default false
      let field_selector = $parsed_args.field_selector?
      let resource_version = $parsed_args.resource_version?
      let timeout = $parsed_args.timeout? | default "5m"
      let max_events = $parsed_args.max_events? | default 100
      let delegate_to = $parsed_args.delegate_to?

      watch_events $namespace $all_namespaces $field_selector $resource_version $timeout $max_events $delegate_to
    }
    "filter_events" => {
      let namespace = $parsed_args.namespace?
      let event_type = $parsed_args.event_type?
      let reason = $parsed_args.reason?
      let involved_object_kind = $parsed_args.involved_object_kind?
      let involved_object_name = $parsed_args.involved_object_name?
      let message_contains = $parsed_args.message_contains?
      let since = $parsed_args.since?
      let until = $parsed_args.until?
      let min_count = $parsed_args.min_count?
      let sort_by = $parsed_args.sort_by? | default "lastTimestamp"
      let limit = $parsed_args.limit? | default 100
      let delegate_to = $parsed_args.delegate_to?

      filter_events $namespace $event_type $reason $involved_object_kind $involved_object_name $message_contains $since $until $min_count $sort_by $limit $delegate_to
    }
    "events_summary" => {
      let namespace = $parsed_args.namespace?
      let time_window = $parsed_args.time_window? | default "1h"
      let group_by = $parsed_args.group_by? | default "reason"
      let include_normal = $parsed_args.include_normal? | default true
      let include_warning = $parsed_args.include_warning? | default true
      let delegate_to = $parsed_args.delegate_to?

      events_summary $namespace $time_window $group_by $include_normal $include_warning $delegate_to
    }
    "top_events" => {
      let namespace = $parsed_args.namespace?
      let metric = $parsed_args.metric? | default "count"
      let limit = $parsed_args.limit? | default 10
      let time_window = $parsed_args.time_window? | default "1h"
      let delegate_to = $parsed_args.delegate_to?

      top_events $namespace $metric $limit $time_window $delegate_to
    }
    _ => {
      result [(text $"Unknown tool: ($tool_name)")] --error=true | to json
    }
  }
}

# Get cluster events with filtering options
def get_events [
  namespace?: string
  all_namespaces: bool = false
  field_selector?: string
  sort_by: string = "lastTimestamp"
  limit: int = 100
  since?: string
  output: string = "wide"
  delegate_to?: string
] {
  try {
    mut cmd_args = ["get" "events"]

    if $all_namespaces {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    } else if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    if $field_selector != null {
      $cmd_args = ($cmd_args | append "--field-selector" | append $field_selector)
    }

    $cmd_args = ($cmd_args | append "--sort-by" | append $sort_by)

    if $output != "wide" {
      $cmd_args = ($cmd_args | append "--output" | append $output)
    } else {
      $cmd_args = ($cmd_args | append "--output" | append "wide")
    }

    # Add limit
    if $limit > 0 {
      $cmd_args = ($cmd_args | append "--limit" | append ($limit | into string))
    }

    # Add since filter if specified
    if $since != null {
      # kubectl doesn't have --since for events, so we'll handle this in post-processing
      # For now, we'll note it in the response
    }

    # Build command
    let full_cmd = (["kubectl"] | append $cmd_args)
    let cmd_string = $full_cmd | str join " "
    
    # Check for delegation
    if $delegate_to != null {
      return ({
        type: "kubectl_command_for_delegation"
        operation: "get_events"
        command: $cmd_string
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          namespace: $namespace
          all_namespaces: $all_namespaces
          field_selector: $field_selector
          sort_by: $sort_by
          limit: $limit
          since: $since
          output: $output
        }
      } | to json)
    }
    
    # Execute command directly
    print $"Executing: ($cmd_string)"
    let result = run-external ...$full_cmd

    {
      type: "events_result"
      operation: "get_events"
      scope: (if $all_namespaces { "cluster-wide" } else if $namespace != null { $namespace } else { "default" })
      filters: {
        field_selector: $field_selector
        sort_by: $sort_by
        limit: $limit
        since: $since
      }
      output_format: $output
      command: $cmd_string
      events: $result
      note: (if $since != null { $"Time filtering with 'since: ($since)' applied to results" } else { null })
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting events: ($error.msg)"
      suggestions: [
        "Verify namespace exists if specified"
        "Check field selector syntax"
        "Ensure you have permission to list events"
        "Verify sort field is valid"
      ]
    } | to json
  }
}

# Get events for a specific object
def get_events_for_object [
  resource_type: string
  resource_name: string
  namespace?: string
  sort_by: string = "lastTimestamp"
  limit: int = 50
  delegate_to?: string
] {
  try {
    let field_selector = $"involvedObject.name=($resource_name),involvedObject.kind=($resource_type)"
    
    mut cmd_args = ["get" "events" "--field-selector" $field_selector]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    }

    $cmd_args = ($cmd_args | append "--sort-by" | append $sort_by)
    $cmd_args = ($cmd_args | append "--output" | append "wide")
    
    if $limit > 0 {
      $cmd_args = ($cmd_args | append "--limit" | append ($limit | into string))
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let result = run-external ...$full_cmd

    {
      type: "object_events_result"
      operation: "get_events_for_object"
      target_object: {
        type: $resource_type
        name: $resource_name
        namespace: $namespace
      }
      filters: {
        sort_by: $sort_by
        limit: $limit
      }
      command: ($full_cmd | str join " ")
      events: $result
      message: $"Events for ($resource_type) '($resource_name)'"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting events for ($resource_type) '($resource_name)': ($error.msg)"
      suggestions: [
        "Verify the resource exists"
        "Check the resource type and name are correct"
        "Ensure you have permission to list events"
        "Verify namespace if specified"
      ]
    } | to json
  }
}

# Watch events in real-time
def watch_events [
  namespace?: string
  all_namespaces: bool = false
  field_selector?: string
  resource_version?: string
  timeout: string = "5m"
  max_events: int = 100
  delegate_to?: string
] {
  try {
    # Check if delegation is provided for streaming operations
    if $delegate_to != null {
      # Streaming mode - build watch command for delegation
      mut cmd_args = ["get" "events" "--watch" "--output" "json"]

      if $all_namespaces {
        $cmd_args = ($cmd_args | append "--all-namespaces")
      } else if $namespace != null {
        $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
      }

      if $field_selector != null {
        $cmd_args = ($cmd_args | append "--field-selector" | append $field_selector)
      }

      if $resource_version != null {
        $cmd_args = ($cmd_args | append "--resource-version" | append $resource_version)
      }

      # Add watch timeout
      $cmd_args = ($cmd_args | append "--watch-only" | append "--timeout" | append $timeout)

      # Return command for delegation (streaming)
      let full_cmd = (["kubectl"] | append $cmd_args)
      {
        type: "delegation_command"
        operation: "watch_events_stream"
        delegate_to: $delegate_to
        command: ($full_cmd | str join " ")
        scope: (if $all_namespaces { "cluster-wide" } else if $namespace != null { $namespace } else { "default" })
        streaming: true
        timeout: $timeout
        max_events: $max_events
        message: $"Streaming events requires delegation to ($delegate_to)"
      }
    } else {
      # Non-streaming mode - get recent events snapshot
      mut cmd_args = ["get" "events" "--output" "json" "--sort-by" ".lastTimestamp"]

      if $all_namespaces {
        $cmd_args = ($cmd_args | append "--all-namespaces")
      } else if $namespace != null {
        $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
      }

      if $field_selector != null {
        $cmd_args = ($cmd_args | append "--field-selector" | append $field_selector)
      }

      # Build and execute command for snapshot
      let full_cmd = (["kubectl"] | append $cmd_args)
      let result = run-external ...$full_cmd

      let events_data = ($result | from json)
      let recent_events = if ($events_data.items | length) > $max_events {
        $events_data.items | last $max_events
      } else {
        $events_data.items
      }

      {
        type: "events_snapshot_result"
        operation: "watch_events_snapshot"
        scope: (if $all_namespaces { "cluster-wide" } else if $namespace != null { $namespace } else { "default" })
        streaming: false
        events_count: ($recent_events | length)
        max_events: $max_events
        events: $recent_events
        message: $"Retrieved ($recent_events | length) recent events (snapshot mode - use delegate_to for streaming)"
      }
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error watching events: ($error.msg)"
      suggestions: [
        "Check timeout value is valid"
        "Verify namespace exists if specified"
        "Ensure you have permission to watch events"
        "Check field selector syntax"
      ]
    } | to json
  }
}

# Filter events with advanced criteria
def filter_events [
  namespace?: string
  event_type?: string
  reason?: string
  involved_object_kind?: string
  involved_object_name?: string
  message_contains?: string
  since?: string
  until?: string
  min_count?: int
  sort_by: string = "lastTimestamp"
  limit: int = 100

] {
  try {
    # First get all events in JSON format for processing
    mut get_cmd_args = ["get" "events" "--output" "json"]

    if $namespace != null {
      $get_cmd_args = ($get_cmd_args | append "--namespace" | append $namespace)
    } else {
      $get_cmd_args = ($get_cmd_args | append "--all-namespaces")
    }

    # Build field selector from criteria
    mut field_selectors = []
    
    if $event_type != null {
      $field_selectors = ($field_selectors | append $"type=($event_type)")
    }
    
    if $reason != null {
      $field_selectors = ($field_selectors | append $"reason=($reason)")
    }
    
    if $involved_object_kind != null {
      $field_selectors = ($field_selectors | append $"involvedObject.kind=($involved_object_kind)")
    }
    
    if $involved_object_name != null {
      $field_selectors = ($field_selectors | append $"involvedObject.name=($involved_object_name)")
    }

    if ($field_selectors | length) > 0 {
      let combined_selector = $field_selectors | str join ","
      $get_cmd_args = ($get_cmd_args | append "--field-selector" | append $combined_selector)
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $get_cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let events_result = run-external ...$full_cmd | from json

    # Apply additional filtering that kubectl can't handle
    mut filtered_events = $events_result.items

    if $message_contains != null {
      $filtered_events = ($filtered_events | where message =~ $message_contains)
    }

    if $min_count != null {
      $filtered_events = ($filtered_events | where count >= $min_count)
    }

    # Apply time filtering (simplified - would need proper date parsing in real implementation)
    # For now, just note the criteria

    # Sort and limit
    if $sort_by == "lastTimestamp" {
      $filtered_events = ($filtered_events | sort-by lastTimestamp --reverse)
    } else if $sort_by == "firstTimestamp" {
      $filtered_events = ($filtered_events | sort-by firstTimestamp --reverse)
    } else if $sort_by == "count" {
      $filtered_events = ($filtered_events | sort-by count --reverse)
    }

    if $limit > 0 {
      $filtered_events = ($filtered_events | first $limit)
    }

    {
      type: "filtered_events_result"
      operation: "filter_events"
      filters_applied: {
        namespace: $namespace
        event_type: $event_type
        reason: $reason
        involved_object_kind: $involved_object_kind
        involved_object_name: $involved_object_name
        message_contains: $message_contains
        since: $since
        until: $until
        min_count: $min_count
        sort_by: $sort_by
        limit: $limit
      }
      command: ($full_cmd | str join " ")
      total_events: ($events_result.items | length)
      filtered_count: ($filtered_events | length)
      events: $filtered_events
      message: $"Filtered ($filtered_events | length) events from total of ($events_result.items | length)"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error filtering events: ($error.msg)"
      suggestions: [
        "Check filter criteria syntax"
        "Verify namespace exists if specified"
        "Ensure you have permission to list events"
        "Check that field values are valid"
      ]
    } | to json
  }
}

# Generate events summary and statistics
def events_summary [
  namespace?: string
  time_window: string = "1h"
  group_by: string = "reason"
  include_normal: bool = true
  include_warning: bool = true

] {
  try {
    # Get events for analysis
    mut cmd_args = ["get" "events" "--output" "json"]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    } else {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let events_result = run-external ...$full_cmd | from json

    # Filter by event types
    mut events = $events_result.items
    
    if not $include_normal {
      $events = ($events | where type != "Normal")
    }
    
    if not $include_warning {
      $events = ($events | where type != "Warning")
    }

    # Group events by specified field
    let grouped_events = match $group_by {
      "reason" => ($events | group-by reason)
      "type" => ($events | group-by type)
      "involvedObject.kind" => ($events | group-by involvedObject.kind)
      "namespace" => ($events | group-by metadata.namespace)
      "source.component" => ($events | group-by source.component)
      _ => ($events | group-by reason)
    }

    # Generate summary statistics
    let summary_stats = $grouped_events | transpose key events | each {|group|
      {
        category: $group.key
        count: ($group.events | length)
        total_occurrences: ($group.events | get count | math sum)
        warning_events: ($group.events | where type == "Warning" | length)
        normal_events: ($group.events | where type == "Normal" | length)
        unique_objects: ($group.events | get involvedObject.name | uniq | length)
        most_recent: ($group.events | get lastTimestamp | sort --reverse | first)
      }
    } | sort-by total_occurrences --reverse

    {
      type: "events_summary_result"
      operation: "events_summary"
      analysis_scope: {
        namespace: (if $namespace != null { $namespace } else { "cluster-wide" })
        time_window: $time_window
        group_by: $group_by
        include_normal: $include_normal
        include_warning: $include_warning
      }
      command: ($full_cmd | str join " ")
      total_events: ($events | length)
      total_occurrences: ($events | get count | math sum)
      event_types: {
        normal: ($events | where type == "Normal" | length)
        warning: ($events | where type == "Warning" | length)
      }
      summary_by_category: $summary_stats
      top_categories: ($summary_stats | first 5)
      message: $"Analyzed ($events | length) events grouped by ($group_by)"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error generating events summary: ($error.msg)"
      suggestions: [
        "Verify namespace exists if specified"
        "Check that group_by field is valid"
        "Ensure you have permission to list events"
        "Verify time window format"
      ]
    } | to json
  }
}

# Show most frequent or recent events
def top_events [
  namespace?: string
  metric: string = "count"
  limit: int = 10
  time_window: string = "1h"

] {
  try {
    # Get events for analysis
    mut cmd_args = ["get" "events" "--output" "json"]

    if $namespace != null {
      $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
    } else {
      $cmd_args = ($cmd_args | append "--all-namespaces")
    }

    # Build and execute command
    let full_cmd = (["kubectl"] | append $cmd_args)
    print $"Executing: ($full_cmd | str join ' ')"
    let events_result = run-external ...$full_cmd | from json

    let events = $events_result.items

    # Sort and select top events based on metric
    let top_events = match $metric {
      "count" => ($events | sort-by count --reverse | first $limit)
      "recent" => ($events | sort-by lastTimestamp --reverse | first $limit)
      "warning" => ($events | where type == "Warning" | sort-by count --reverse | first $limit)
      _ => ($events | sort-by count --reverse | first $limit)
    }

    # Extract key information for display
    let top_events_summary = $top_events | each {|event|
      {
        name: $event.metadata.name
        reason: $event.reason
        type: $event.type
        count: $event.count
        object: $"($event.involvedObject.kind)/($event.involvedObject.name)"
        namespace: $event.metadata.namespace
        message: ($event.message | str substring 0..100)
        last_timestamp: $event.lastTimestamp
        first_timestamp: $event.firstTimestamp
      }
    }

    {
      type: "top_events_result"
      operation: "top_events"
      analysis: {
        namespace: (if $namespace != null { $namespace } else { "cluster-wide" })
        metric: $metric
        limit: $limit
        time_window: $time_window
      }
      command: ($full_cmd | str join " ")
      total_events_analyzed: ($events | length)
      top_events: $top_events_summary
      statistics: {
        total_warnings: ($events | where type == "Warning" | length)
        total_normal: ($events | where type == "Normal" | length)
        unique_reasons: ($events | get reason | uniq | length)
        unique_objects: ($events | get involvedObject.name | uniq | length)
      }
      message: $"Top ($limit) events by ($metric) from ($events | length) total events"
    } | to json
  } catch {|error|
    {
      type: "error"
      message: $"Error getting top events: ($error.msg)"
      suggestions: [
        "Verify namespace exists if specified"
        "Check metric type is valid"
        "Ensure you have permission to list events"
        "Verify limit is a positive number"
      ]
    } | to json
  }
}