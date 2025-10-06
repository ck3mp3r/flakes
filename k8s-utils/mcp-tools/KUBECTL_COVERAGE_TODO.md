# Kubernetes MCP Tools - kubectl Coverage TODO

## Implementation Guidelines

### Parameter Design Decisions (LLM Safety vs kubectl CLI)

**CRITICAL RULE: Side-Effect vs Read-Only Operations**

**READ-ONLY Operations** (get, describe, logs, status):
- Can use kubectl's default optional parameters
- `namespace`: Optional (kubectl defaults to current context)
- `container`: Optional for single-container pods (kubectl picks the only one)
- `all_namespaces`: Optional flag (explicit cluster-wide scope)

**SIDE-EFFECT Operations** (apply, delete, exec, scale, rollout):
- MUST be explicit about scope to prevent foot-guns
- `namespace`: MANDATORY (no implicit defaults in LLM context)
- `container`: MANDATORY for pod operations (explicit targeting required)
- All targeting parameters must be explicit

**Rationale:**
- LLMs lack user context awareness that kubectl CLI users have
- kubectl's "helpful" defaults become dangerous in automated contexts
- Explicit parameters make operations self-documenting and auditable
- Prevents accidental operations in wrong namespace/container
- Side-effect operations require explicit intent confirmation

### Current Parameter Consistency Status

**✅ READ-ONLY Tools (kubectl defaults preserved):**
- k8s-get.nu: namespace optional, resource_type mandatory 
- k8s-describe.nu: namespace optional (kubectl defaults work fine)
- k8s-logs.nu: namespace and container optional (kubectl handles single containers)

**✅ SIDE-EFFECT Tools (mandatory parameters for safety):**
- k8s-exec.nu: namespace and container mandatory ✓
- k8s-scale.nu: namespace mandatory ✓
- k8s-delete.nu: namespace mandatory ✓
- k8s-rollout.nu: namespace mandatory ✓
- k8s-apply.nu: namespace optional (reasonable for cluster-scoped resources) ✓

**✅ Parameter Design Implementation Complete:**
- All tools follow the side-effect vs read-only parameter rules
- LLM safety achieved through explicit targeting for destructive operations
- kubectl's helpful defaults preserved for safe read-only operations
- All tools tested and validated

### Delegation Pattern Implementation

**✅ DELEGATION PATTERN (implemented across all 17 tools):**

All tools now support flexible delegation for tmux-based workflows where users interact with an agent in one pane and see command executions in another pane.

**Schema Pattern:**
```json
{
  "delegate_to": {
    "type": "string",
    "description": "Optional: Return command for delegation instead of executing directly (e.g., 'nu_mcp', 'tmux')"
  }
}
```

**Function Signature Pattern:**
```nushell
def tool_function [
  # ... required parameters
  # ... optional parameters  
  delegate_to?: string  # Always last parameter
] {
  # ... function body
}
```

**Call-Tool Extraction Pattern:**
```nushell
def "main call-tool" [
  tool_name: string
  args: string = "{}"
] {
  let parsed_args = $args | from json
  let delegate_to = $parsed_args.delegate_to?
  
  match $tool_name {
    "tool_name" => {
      # ... extract other parameters
      tool_function $param1 $param2 $delegate_to
    }
  }
}
```

**Delegation Logic Pattern:**
```nushell
def tool_function [param1: string, delegate_to?: string] {
  try {
    # Build command arguments
    mut cmd_args = ["subcommand", $param1]
    let full_cmd = (["kubectl"] | append $cmd_args)
    
    # Delegation check - return command info instead of executing
    if $delegate_to != null {
      {
        type: "kubectl_command_for_delegation"
        operation: "operation_name"
        command: ($full_cmd | str join " ")
        delegate_to: $delegate_to
        instructions: $"Execute this command using ($delegate_to) delegation method"
        parameters: {
          param1: $param1
          # ... other relevant parameters
        }
      } | to json
    } else {
      # Execute directly
      print $"Executing: ($full_cmd | str join ' ')"
      let result = run-external ...$full_cmd
      
      {
        type: "operation_result"
        operation: "operation_name"
        command: ($full_cmd | str join " ")
        result: $result
      } | to json
    }
  } catch {|error|
    # ... error handling
  }
}
```

**Key Design Decisions:**
- `delegate_to` accepts any string value (not restricted to enum) for maximum flexibility
- When `delegate_to` is specified, tools return structured command information instead of executing
- Delegation logic appears before actual execution for early return
- All 17 tools implement identical delegation pattern for consistency
- Enables interactive agent workflows with external command execution monitoring

### Existing Implementation Patterns

**File Structure**: Each tool follows the MCP pattern:
- `main`: Default help command
- `main list-tools`: Returns JSON array of available tools with schemas
- `main call-tool`: Dispatches to specific tool functions
- Individual tool functions for each operation

**Command Execution Pattern**: 
```nushell
# Build command args first
mut cmd_args = ["get" "pods"]
$cmd_args = ($cmd_args | append "--namespace" | append $namespace)

# Build full command array and execute
let full_cmd = (["kubectl"] | append $cmd_args)
print $"Executing: ($full_cmd | str join ' ')"
let result = run-external ...$full_cmd

# Use same command for output record
{
  command: ($full_cmd | str join " ")
  result: $result
} | to json
```

**Side-Effect Marking**: Operations that modify cluster state must be marked with appropriate warning levels:
- `[MODIFIES CLUSTER]` - Basic cluster modification
- `[DISRUPTIVE]` - Can cause service disruption 
- `[HIGHLY DISRUPTIVE]` - Can cause widespread service disruption
- `[POTENTIALLY DESTRUCTIVE]` - Can delete/overwrite data or resources
- `[HIGHLY DESTRUCTIVE]` - Can delete/overwrite multiple resources simultaneously

**Warning Level Guidelines:**
- Read-only operations: No marking needed
- Resource creation/updates: `[MODIFIES CLUSTER]` + `[POTENTIALLY DESTRUCTIVE]`
- Resource deletion: `[MODIFIES CLUSTER]` + `[DESTRUCTIVE]`
- Scaling operations: `[MODIFIES CLUSTER]` + `[DISRUPTIVE]`
- Multi-resource operations: Add `[HIGHLY...]` prefix
- Container exec operations: `[MODIFIES CLUSTER]` + `[POTENTIALLY DESTRUCTIVE]`

**Error Handling**: Use try-catch with structured error responses:
```nushell
try {
  # operation
} catch {|error|
  {
    type: "error"
    message: $"Error description: ($error.msg)"
    suggestions: ["suggestion1", "suggestion2"]
  } | to json
}
```

**Optional Parameters**: Use safe field access with `?` operator:
```nushell
let namespace = $parsed_args.namespace?
if $namespace != null {
  $cmd_args = ($cmd_args | append "--namespace" | append $namespace)
}
```

## Current Implementation Status

### ✅ COMPLETED
**Phase 1 - Essential Operations:**
- **k8s-get.nu**: Resource retrieval, filtering, API resources, summaries
- **k8s-describe.nu**: Resource descriptions, health checks, events
- **k8s-apply.nu**: YAML/Kustomization application, validation, diff
- **k8s-scale.nu**: Scaling, autoscaling, monitoring
- **k8s-logs.nu**: Pod logs, streaming, selector-based retrieval
- **k8s-exec.nu**: Command execution in pods, interactive shells, file transfer
- **k8s-delete.nu**: Resource deletion, selector-based, cascade policies
- **k8s-rollout.nu**: Deployment rollout management, history, restart, undo

**Phase 2 - Advanced Operations:**
- **k8s-patch.nu**: Resource patching (strategic, merge, JSON patches)
- **k8s-create.nu**: Resource creation (files, namespaces, configmaps, secrets, deployments, services)
- **k8s-config.nu**: Configuration management (contexts, clusters, users, kubeconfig)
- **k8s-auth.nu**: Authorization and authentication (can-i, whoami, RBAC reconciliation)

## kubectl Command Coverage TODO

### 📋 BASIC COMMANDS (Beginner)

#### ❌ CREATE Operations [MODIFIES CLUSTER]
**File: k8s-create.nu**
- [ ] `create_from_file` - Create from YAML/JSON file
- [ ] `create_from_stdin` - Create from piped content  
- [ ] `create_clusterrole` - Create cluster role
- [ ] `create_clusterrolebinding` - Create cluster role binding
- [ ] `create_configmap` - Create config map (from file/literal/env)
- [ ] `create_cronjob` - Create cron job
- [ ] `create_deployment` - Create deployment
- [ ] `create_ingress` - Create ingress
- [ ] `create_job` - Create job
- [ ] `create_namespace` - Create namespace
- [ ] `create_poddisruptionbudget` - Create PDB
- [ ] `create_priorityclass` - Create priority class
- [ ] `create_quota` - Create resource quota
- [ ] `create_role` - Create role
- [ ] `create_rolebinding` - Create role binding
- [ ] `create_secret` - Create secret (generic/docker/tls)
- [ ] `create_service` - Create service
- [ ] `create_serviceaccount` - Create service account
- [ ] `create_token` - Request service account token

#### ❌ EXPOSE Operations [MODIFIES CLUSTER]
**File: k8s-expose.nu**
- [ ] `expose_deployment` - Expose deployment as service
- [ ] `expose_pod` - Expose pod as service
- [ ] `expose_replicaset` - Expose RS as service
- [ ] `expose_replicationcontroller` - Expose RC as service
- [ ] `expose_service` - Create service from existing service

#### ❌ RUN Operations [MODIFIES CLUSTER]
**File: k8s-run.nu**
- [ ] `run_pod` - Run pod with image
- [ ] `run_job` - Run as job
- [ ] `run_with_overrides` - Run with JSON overrides

#### ❌ SET Operations [MODIFIES CLUSTER]
**File: k8s-set.nu**
- [ ] `set_env` - Update environment variables
- [ ] `set_image` - Update container image
- [ ] `set_resources` - Update resource requests/limits
- [ ] `set_selector` - Set resource selector
- [ ] `set_serviceaccount` - Update service account
- [ ] `set_subject` - Update RBAC subjects

### 📋 BASIC COMMANDS (Intermediate)

#### ❌ EXPLAIN Operations (Read-only)
**File: k8s-explain.nu** 
- [ ] `explain_resource` - Get resource documentation
- [ ] `explain_field` - Get specific field docs
- [ ] `explain_recursive` - Get all nested fields
- [ ] `explain_api_version` - Explain for specific API version


#### ✅ DELETE Operations [MODIFIES CLUSTER]
**File: k8s-delete.nu**
- [x] `delete_resource` - Delete by name
- [x] `delete_by_selector` - Delete by label selector
- [x] `delete_by_file` - Delete from file
- [x] `delete_all_in_namespace` - Delete all in namespace
- [x] `delete_with_cascade` - Delete with cascade policy

### 📋 DEPLOY COMMANDS

#### ✅ ROLLOUT Operations
**File: k8s-rollout.nu**
- [x] `rollout_history` - View rollout history [READ-ONLY]
- [x] `rollout_pause` - Pause rollout [MODIFIES CLUSTER]
- [x] `rollout_restart` - Restart rollout [MODIFIES CLUSTER]
- [x] `rollout_resume` - Resume rollout [MODIFIES CLUSTER]
- [x] `rollout_status` - Check rollout status [READ-ONLY]
- [x] `rollout_undo` - Undo rollout [MODIFIES CLUSTER]

### 📋 CLUSTER MANAGEMENT COMMANDS

#### ❌ CLUSTER INFO Operations (Read-only)
**File: k8s-cluster.nu**
- [ ] `cluster_info` - Display cluster info
- [ ] `cluster_info_dump` - Dump cluster info

#### ❌ RESOURCE USAGE Operations (Read-only)
**File: k8s-top.nu**
- [ ] `top_nodes` - Node CPU/memory usage
- [ ] `top_pods` - Pod CPU/memory usage
- [ ] `top_containers` - Container resource usage

#### ✅ NODE MANAGEMENT Operations [MODIFIES CLUSTER]
**File: k8s-node.nu**
- [x] `cordon_node` - Mark node unschedulable
- [x] `uncordon_node` - Mark node schedulable
- [x] `drain_node` - Drain node for maintenance
- [x] `taint_node` - Add/remove node taints
- [x] `get_node_info` - Get detailed node information
- [x] `list_nodes` - List all nodes with status

#### ❌ CERTIFICATE Operations [MODIFIES CLUSTER]
**File: k8s-certificate.nu**
- [ ] `approve_csr` - Approve certificate signing request
- [ ] `deny_csr` - Deny certificate signing request

### 📋 TROUBLESHOOTING COMMANDS

#### ✅ LOGS Operations (Read-only)
**File: k8s-logs.nu**
- [x] `get_logs` - Get pod logs
- [x] `get_logs_selector` - Get logs by selector
- [x] `get_logs_deployment` - Get logs from deployment pods
- [x] `stream_logs` - Follow/stream logs

#### ✅ EXEC Operations [MODIFIES CLUSTER - can change pod state]
**File: k8s-exec.nu**
- [x] `exec_command` - Execute command in pod
- [x] `exec_script` - Execute script in pod
- [x] `exec_multiple` - Execute on multiple pods
- [x] `exec_file_transfer` - Transfer files to/from pods

#### ❌ PORT FORWARD Operations [MODIFIES CLUSTER - network changes]
**File: k8s-port-forward.nu**
- [ ] `port_forward` - Forward local port to pod
- [ ] `port_forward_service` - Forward to service
- [ ] `port_forward_deployment` - Forward to deployment


#### ❌ COPY Operations [MODIFIES CLUSTER]
**File: k8s-copy.nu**
- [ ] `copy_to_pod` - Copy files to pod
- [ ] `copy_from_pod` - Copy files from pod

#### ✅ DEBUG Operations [MODIFIES CLUSTER]
**File: k8s-debug.nu**
- [x] `debug_pod` - Create debug session for pods
- [x] `debug_node` - Debug node with privileged access
- [x] `debug_workload` - Debug workloads by creating copies
- [x] `debug_cleanup` - Clean up debug resources
- [x] `list_debug_sessions` - List active debug sessions
- [x] `debug_network` - Network debugging with netshoot

#### ✅ EVENTS Operations (Read-only)
**File: k8s-events.nu**
- [x] `get_events` - List cluster events with filtering
- [x] `get_events_for_object` - Events for specific object
- [x] `watch_events` - Watch events in real-time
- [x] `filter_events` - Advanced event filtering
- [x] `events_summary` - Generate event statistics
- [x] `top_events` - Show most frequent/recent events

### 📋 ADVANCED COMMANDS

#### ❌ DIFF Operations (Read-only)
**File: k8s-diff.nu**
- [ ] `diff_file` - Diff local file vs cluster
- [ ] `diff_kustomization` - Diff kustomization

#### ❌ PATCH Operations [MODIFIES CLUSTER]
**File: k8s-patch.nu**
- [ ] `patch_strategic` - Strategic merge patch
- [ ] `patch_merge` - JSON merge patch
- [ ] `patch_json` - JSON patch
- [ ] `patch_subresource` - Patch subresource

#### ❌ REPLACE Operations [MODIFIES CLUSTER]
**File: k8s-replace.nu**
- [ ] `replace_resource` - Replace resource
- [ ] `replace_force` - Force replace


#### ❌ KUSTOMIZE Operations (Read-only)
**File: k8s-kustomize.nu**
- [ ] `build_kustomization` - Build kustomization
- [ ] `kustomize_from_url` - Build from URL

### 📋 SETTINGS COMMANDS

#### ❌ LABEL Operations [MODIFIES CLUSTER]
**File: k8s-label.nu**
- [ ] `add_labels` - Add/update labels
- [ ] `remove_labels` - Remove labels
- [ ] `list_labels` - List current labels
- [ ] `overwrite_labels` - Overwrite existing labels

#### ❌ ANNOTATE Operations [MODIFIES CLUSTER]
**File: k8s-annotate.nu**
- [ ] `add_annotations` - Add/update annotations
- [ ] `remove_annotations` - Remove annotations
- [ ] `list_annotations` - List current annotations
- [ ] `overwrite_annotations` - Overwrite existing annotations

### 📋 CONFIGURATION COMMANDS

#### ❌ CONFIG Operations (Read-only for view, [MODIFIES CLUSTER] for changes)
**File: k8s-config.nu**
- [ ] `config_view` - View kubeconfig [READ-ONLY]
- [ ] `config_current_context` - Show current context [READ-ONLY]
- [ ] `config_get_contexts` - List contexts [READ-ONLY]
- [ ] `config_get_clusters` - List clusters [READ-ONLY]
- [ ] `config_get_users` - List users [READ-ONLY]
- [ ] `config_use_context` - Switch context [MODIFIES CONFIG]
- [ ] `config_set_context` - Set context [MODIFIES CONFIG]
- [ ] `config_set_cluster` - Set cluster [MODIFIES CONFIG]
- [ ] `config_set_credentials` - Set user credentials [MODIFIES CONFIG]
- [ ] `config_delete_context` - Delete context [MODIFIES CONFIG]
- [ ] `config_delete_cluster` - Delete cluster [MODIFIES CONFIG]
- [ ] `config_delete_user` - Delete user [MODIFIES CONFIG]
- [ ] `config_rename_context` - Rename context [MODIFIES CONFIG]

### 📋 AUTHORIZATION COMMANDS

#### ❌ AUTH Operations (Read-only)
**File: k8s-auth.nu**
- [ ] `auth_can_i` - Check permissions
- [ ] `auth_whoami` - Check user identity
- [ ] `auth_reconcile` - Reconcile RBAC [MODIFIES CLUSTER]

### 📋 UTILITY COMMANDS

#### ✅ API RESOURCES Operations (Read-only)
**File: k8s-api.nu**
- [x] `api_resources` - List API resources with filtering
- [x] `api_versions` - List API versions
- [x] `explain_resource` - Get resource documentation
- [x] `api_resource_info` - Get detailed resource information
- [x] `cluster_info` - Display cluster information
- [x] `server_version` - Get server version and build info

#### ✅ VERSION Operations (Read-only)
**File: k8s-version.nu**
- [x] `version_client` - Show client version
- [x] `version_server` - Show server version
- [x] `version_both` - Show both client and server
- [x] `version_short` - Short version info
- [x] `version_compatibility` - Check client-server compatibility
- [x] `cluster_version_info` - Comprehensive version information


## Implementation Priority

### ✅ Phase 1 - Essential Operations (COMPLETED)
1. ✅ k8s-logs.nu (troubleshooting)
2. ✅ k8s-exec.nu (debugging)  
3. ✅ k8s-delete.nu (resource management)
4. ✅ k8s-rollout.nu (deployment management)

### ✅ Phase 2 - Advanced Operations (COMPLETED)
1. ✅ k8s-patch.nu (resource updates)
2. ✅ k8s-create.nu (resource creation)
3. ✅ k8s-config.nu (configuration management)
4. ✅ k8s-auth.nu (permissions)

### ✅ Phase 3 - Specialized Operations (COMPLETED)
1. ✅ k8s-node.nu (node management)
2. ✅ k8s-debug.nu (advanced debugging)
3. ✅ k8s-events.nu (cluster monitoring)
4. ✅ k8s-api.nu (API resources and versions)
5. ✅ k8s-version.nu (version information)

## Notes

- Always implement command logging first following existing pattern
- Mark side-effect operations clearly in descriptions
- Use structured JSON output for consistency
- Include helpful error messages with suggestions
- Test each tool with `cat file.nu | nu --ide-check 10 --stdin` before committing
- Follow MCP tool schema specifications
- Maintain consistency with existing code style

## Implementation Summary

### ✅ COMPLETED IMPLEMENTATIONS

**Total Tools Implemented: 17 files, 89+ individual MCP tools**

**Phase 1 - Essential Operations (4 tools):**
- ✅ k8s-get.nu (6 tools) - Resource retrieval, filtering, API resources
- ✅ k8s-describe.nu (4 tools) - Resource descriptions, health checks
- ✅ k8s-apply.nu (5 tools) - YAML/Kustomization application, validation
- ✅ k8s-scale.nu (4 tools) - Scaling, autoscaling, monitoring
- ✅ k8s-logs.nu (4 tools) - Pod logs, streaming, selector-based
- ✅ k8s-exec.nu (4 tools) - Command execution, shells, file operations
- ✅ k8s-delete.nu (5 tools) - Resource deletion, cascade policies
- ✅ k8s-rollout.nu (6 tools) - Deployment rollout management

**Phase 2 - Advanced Operations (4 tools):**
- ✅ k8s-patch.nu (4 tools) - Resource patching (strategic, merge, JSON)
- ✅ k8s-create.nu (8 tools) - Resource creation from files/templates
- ✅ k8s-config.nu (8 tools) - Configuration management (contexts, clusters)
- ✅ k8s-auth.nu (4 tools) - Authorization and authentication

**Phase 3 - Specialized Operations (5 tools):**
- ✅ k8s-node.nu (6 tools) - Node management (cordon, drain, taint)
- ✅ k8s-debug.nu (6 tools) - Advanced debugging (pods, nodes, network)
- ✅ k8s-events.nu (6 tools) - Cluster monitoring and event analysis
- ✅ k8s-api.nu (6 tools) - API resources, versions, documentation
- ✅ k8s-version.nu (6 tools) - Version information and compatibility

### 🔧 IMPLEMENTATION HIGHLIGHTS

**Safety Features Implemented:**
- ✅ Side-effect vs read-only parameter design (mandatory namespace/container for destructive operations)
- ✅ Comprehensive warning markers ([MODIFIES CLUSTER], [DESTRUCTIVE], etc.)
- ✅ Structured error handling with helpful suggestions
- ✅ Command logging and execution tracking
- ✅ Non-interactive design for LLM compatibility

**Technical Features:**
- ✅ Consistent MCP tool patterns across all implementations
- ✅ JSON schema definitions for all tool inputs
- ✅ Structured JSON output for all operations
- ✅ Comprehensive error handling and suggestion systems
- ✅ Support for all major kubectl operations and patterns
- ✅ Advanced filtering, sorting, and output options
- ✅ Proper handling of optional vs mandatory parameters

**Quality Assurance:**
- ✅ All tools pass `nu --ide-check` validation
- ✅ Consistent code style and patterns
- ✅ Comprehensive tool documentation
- ✅ Safety-first design with explicit parameter requirements
- ✅ LLM-optimized interface design

This comprehensive implementation provides MCP-compatible, LLM-safe access to virtually all kubectl functionality while maintaining the safety and explicitness required for automated operations.