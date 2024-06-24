using './prometheus-alerts.bicep'

param alertsEmailAddress = '#{{ prometheusAlertsSlackEmailAddress }}'
param environment = '#{{ environment }}'
param environmentId = '#{{ environmentId }}'
param azureMonitorWorkspace = '#{{ infraResourceNamePrefix }}#{{ nc_resource_azuremonitorworkspace }}#{{ nc_instance_regionid }}01'
param location = '#{{ location }}'

param alerts = [
  {
    name: 'KubeContainerOOMKilledCount'
    expression: 'sum by (cluster,container,controller,namespace)(kube_pod_container_status_last_terminated_reason{reason="OOMKilled", namespace=~"#{{ clusterNamespacesToMonitor }}"} * on(cluster,namespace,pod) group_left(controller) label_replace(kube_pod_owner, "controller", "$1", "owner_name", "(.*)")) > 0'
    description: 'Number of OOM killed containers is greater than 0.'
    firedTimePeriod: 'PT5M'
    timeToResolve: 'PT10M'
  }
  {
    name: 'KubeDeploymentReplicasMismatch'
    expression: '( kube_deployment_spec_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"} > kube_deployment_status_replicas_available{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}) and ( changes(kube_deployment_status_replicas_updated{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}[10m]) == 0)'
    description: 'Deployment {{ $labels.namespace }}/{{ $labels.deployment }} in {{ $labels.cluster}} replica mismatch.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT15M'
  }
  {
    name: 'KubeStatefulSetReplicasMismatch'
    expression: '(  kube_statefulset_status_replicas_ready{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"} > kube_deployment_status_replicas_available{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}) and ( changes(kube_deployment_status_replicas_updated{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}[10m])    ==  0)'
    description: 'StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} in {{ $labels.cluster}} replica mismatch.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT10M'
  }
  {
    name: 'KubeHpaReplicasMismatch'
    expression: '(kube_horizontalpodautoscaler_status_desired_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}  !=kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"})  and(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}  >kube_horizontalpodautoscaler_spec_min_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"})  and(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}  <kube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"})  and changes(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}[15m]) == 0'
    description: 'Horizontal Pod Autoscaler in {{ $labels.cluster}} has not matched the desired number of replicas for longer than 15 minutes.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT15M'
  }
  {
    name: 'KubeHpaMaxedOut'
    expression: 'kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}  == kube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}'
    description: 'Horizontal Pod Autoscaler in {{ $labels.cluster}} has been running at max replicas for longer than 15 minutes.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT15M'
  }
  {
    name: 'KubePodCrashLooping'
    expression: 'max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff", job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}[5m]) >= 1'
    description: '{{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) in {{ $labels.cluster}} is restarting.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT10M'
  }
  {
    name: 'KubePodContainerRestart'
    expression: 'sum by (namespace, controller, container, cluster)(increase(kube_pod_container_status_restarts_total{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}[1h])* on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, "controller", "$1", "owner_name", "(.*)")) > 0'
    description: 'Pod container restarted in the last 1 hour.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT10M'
  }
  {
    name: 'KubePodReadyStateLow'
    expression: 'sum by (cluster,namespace,deployment)(kube_deployment_status_replicas_ready{namespace=~"#{{ clusterNamespacesToMonitor }}"}) / sum by (cluster,namespace,deployment)(kube_deployment_spec_replicas{namespace=~"#{{ clusterNamespacesToMonitor }}"}) <.8 or sum by (cluster,namespace,deployment)(kube_daemonset_status_number_ready{namespace=~"#{{ clusterNamespacesToMonitor }}"}) / sum by (cluster,namespace,deployment)(kube_daemonset_status_desired_number_scheduled{namespace=~"#{{ clusterNamespacesToMonitor }}"}) <.8 '
    description: 'Ready state of pods is less than 80%.'
    firedTimePeriod: 'PT5M'
    timeToResolve: 'PT15M'
  }
  {
    name: 'KubePodFailedState'
    expression: 'sum by (cluster, namespace, controller) (kube_pod_status_phase{phase="failed", namespace=~"#{{ clusterNamespacesToMonitor }}"} * on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, "controller", "$1", "owner_name", "(.*)"))  > 0'
    description: 'Number of pods in failed state are greater than 0'
    firedTimePeriod: 'PT5M'
    timeToResolve: 'PT15M'
  }
  {
    name: 'KubePodNotReadyByController'
    expression: 'sum by (namespace, controller, cluster) (max by(namespace, pod, cluster) (kube_pod_status_phase{job="kube-state-metrics", phase=~"Pending|Unknown", namespace=~"#{{ clusterNamespacesToMonitor }}" }  ) * on(namespace, pod, cluster) group_left(controller)label_replace(kube_pod_owner,"controller","$1","owner_name","(.*)")) > 0'
    description: '{{ $labels.namespace }}/{{ $labels.pod }} in {{ $labels.cluster}} by controller is not ready.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT10M'
  }
  {
    name: 'KubeStatefulSetGenerationMismatch'
    expression: 'kube_statefulset_status_observed_generation{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"} != kube_statefulset_metadata_generation{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}'
    description: 'StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset }} does not match, this indicates that the StatefulSet has failed but has not been rolled back.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT10M'
  }
  {
    name: 'KubeJobFailed'
    expression: 'kube_job_failed{job="kube-state-metrics", namespace=~"#{{ clusterNamespacesToMonitor }}"}  > 0'
    description: 'Job {{ $labels.namespace }}/{{ $labels.job_name }} in {{ $labels.cluster}} failed to complete.'
    firedTimePeriod: 'PT15M'
    timeToResolve: 'PT10M'
  }
  {
    name: 'KubeContainerAverageCPUHigh'
    expression: 'sum (rate(container_cpu_usage_seconds_total{image!="", container!="POD", namespace=~"#{{ clusterNamespacesToMonitor }}"}[5m])) by (pod,cluster,container,namespace) / sum(container_spec_cpu_quota{image!="", container!="POD", namespace=~"#{{ clusterNamespacesToMonitor }}"}/container_spec_cpu_period{image!="", container!="POD", namespace=~"#{{ clusterNamespacesToMonitor }}"}) by (pod,cluster,container,namespace) > .95'
    description: 'Average CPU usage per container is greater than 95%.'
    firedTimePeriod: 'PT5M'
    timeToResolve: 'PT15M'
  }
  {
    name: 'KubeContainerAverageMemoryHigh'
    expression: 'avg by (namespace, controller, container, cluster)(((container_memory_working_set_bytes{container!="", image!="", container!="POD", namespace=~"#{{ clusterNamespacesToMonitor }}"} / on(namespace,cluster,pod,container) group_left kube_pod_container_resource_limits{resource="memory", node!="", namespace=~"#{{ clusterNamespacesToMonitor }}"})*on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, "controller", "$1", "owner_name", "(.*)")) > .95)'
    description: 'Average Memory usage per container is greater than 95%.'
    firedTimePeriod: 'PT10M'
    timeToResolve: 'PT10M'
  }
  // Add more alerts here
]
