## v2.0.0-beta / 2020-12-04
Promotion to beta release after a period of no bugs.

## v2.0.0-alpha.3 / 2020-11-19

* [BUGFIX] Fix container resource limits metrics, which got dropped #1293
* [BUGFIX] Adjust and refactor allowing labels to work for Kubernetes labels metrics #1301
Note this is a breaking change, if you were using --labels-allow-list, look at the PR details for more information.

## v2.0.0-alpha.2 / 2020-10-27

* [CHANGE] Migrate ingress and certificates to new stable APIs #1260
* [CHANGE] Revert "Rework resource metrics" #1278
To better align with future Kubernetes resource metrics, the changes to resource metrics were reverted, new metrics are:
kube_pod_container_resource_requests and kube_pod_container_resource_limits
* [FEATURE] Added the job failure reason in kube_job_status_failed metric #1214
* [FEATURE] feat(persistentvolume): claimRef info to labels (kube_persistentvolume_claim_ref) #1244
* [FEATURE] pod: add gauge for runtimeclass handler (kube_pod_runtimeclass_name_info) #1276

## v2.0.0-alpha.1 / 2020-10-06

* [CHANGE] Update go module path to k8s.io/kube-state-metrics/v2 #1238
* [CHANGE] Bump klog to v2 and client-go to 1.19 #1250
* [FEATURE] Add iscsi initiator name to persistentvolume_info #1235 
* [BUGFIX] Added Namespace to Rolebinding Jsonnet #1233 
* [BUGFIX] Reference closure scoped family generator #1240 

## v2.0.0-alpha / 2020-09-16

NOTE: This is a major new alpha 2.0 release with breaking changes and removed metrics. See details below!

* [CHANGE] Apply boundaries to metrics and allow via flag (--labels-allow-list) what labels to include #1125 
* [CHANGE] Update DaemonSet updated_number_scheduled metric name to be consistent #1181
Metric was changed from kube_daemonset_updated_number_scheduled to kube_daemonset_status_updated_number_scheduled 
* [CHANGE] Rework resource metrics #1168
Metrics kube_pod_container_resource_requests, kube_pod_container_resource_limits, kube_pod_overhead, kube_pod_init_container_resource_limits, kube_pod_init_container_resource_requests changed
* [CHANGE] Convert k8s labels to snake case #1165 
* [CHANGE] Mutatingwebhookconfiguration.go: Switch to v1 #1144 
* [CHANGE] v2: Rename storage class labels reclaimPolicy to reclaim_policy and volumeBindingMode to volume_binding_mode #1107
* [CHANGE] v2: Renamed --namespace flag to --namespaces #1098
* [CHANGE] Rename kube_pod_deleted to kube_pod_deletion_timestamp #1079
* [CHANGE] v2: Rename collector flag to resource flag #1006
--resources is the new flag
* [CHANGE] Remove non-identifying labels from pod metrics #1009 
* [CHANGE] v2: Remove deprecated stable metrics #1004
Note that some of these were replaced with EXPERIMENTAL resource metrics. See #1168 for more details.
  `kube_pod_container_resource_requests` and `kube_pod_container_resource_limits` are the replacements with `resource` labels
  representing the resource name and `unit` labels representing the resource unit.
  - kube_pod_container_resource_requests_cpu_cores
  - kube_pod_container_resource_limits_cpu_cores
  - kube_pod_container_resource_requests_memory_bytes
  - kube_pod_container_resource_limits_memory_bytes
  - `kube_node_status_capacity` and `kube_node_status_allocatable` are the replacements with `resource` labels
  representing the resource name and `unit` labels representing the resource unit.
  - kube_node_status_capacity_pods
  - kube_node_status_capacity_cpu_cores
  - kube_node_status_capacity_memory_bytes
  - kube_node_status_allocatable_pods
  - kube_node_status_allocatable_cpu_cores
  - kube_node_status_allocatable_memory_bytes
* [CHANGE] Rename black-/whitelist to allow/deny-list #1045
New flags are --metric-allowlist and --metric-denylist
* [CHANGE] Update telemetry port to 8081 #1049 
* [CHANGE] v2: Rename hpa metrics to use full horizontalpodautoscaler #1003 
All metrics with prefix of kube_hpa_ were renamed to kube_horizontalpodautoscaler_
* [CHANGE] v2: change metrics port to 8080, telemetry port to 8081 #1005 
* [FEATURE] Add http request metric for kube-state-metrics main /metrics #1218  
* [FEATURE] Add fc/iscsi/nfs identifier tags to persistentvolume_info metric #1208 
* [FEATURE] Adds new pod metric kube_pod_container_state_started #1183 
* [FEATURE] Add observedGeneration metric (kube_daemonset_status_observed_generation) for DaemonSets #1178
* [FEATURE] Add internal_ip to node_info #1172 
* [FEATURE] Avoid conflicts when mapping Kubernetes labels to Prometheus labels #1156 
* [FEATURE] Add aws/gce volume id to kube_persistentvolume_info #1146
* [FEATURE] Add UnexpectedAdmissionError to kube_pod_status_reason metric #1145
* [FEATURE] Add init container requests (kube_pod_init_container_resource_requests) #1123
* [FEATURE] Add host_network to kube_pod_info #1100 
* [FEATURE] Add kube_replicationcontroller_owner #1058 
* [FEATURE] Pod: add gauges for pod overhead (kube_pod_overhead) #1053 
* [FEATURE] Add "Terminating" status in kube_pod_status_phase metrics #1013 
* [FEATURE] Add lease collector metrics #1038 
* [ENHANCEMENT] Add DeprecatedVersion to struct FamilyGenerator and func NewFamilyGenerator #1160
* [ENHANCEMENT] Add security context to deployment and statefulset #1034 
* [BUGFIX] Fix VolumeAttachment API version mismatch: expected v1 but watching v1beta1 #1136
* [BUGFIX] Fix various CI issues (kube_volumeattachment_info nodeName -> node label rename) #1117 
* [BUGFIX] Fix maxUnavailable to round down instead up #1076 


## v1.9.7 / 2020-05-24

* [BUGFIX] internal/store/mutatingwebhookconfiguration.go: Switch to v1 #1144

## v1.9.6 / 2020-05-06

* [BUGFIX] Fix VolumeAttachment API version mismatch: expected v1 but watching v1beta1 #1136

## v1.9.5 / 2020-02-20

* [BUGFIX] Switch to using only v1 client of validatingwebhookconfiguration #1052

## v1.9.4 / 2020-02-03

* [BUGFIX] Fix VolumeAttachment api version to be used (was v1beta1, should have been v1). #1043
* [BUGFIX] Fix MutatingWebhookConfiguration api version to be used (was v1beta1, should have been v1). #1043
* [BUGFIX] Fix ValidatingWebhookConfiguration api version to be used (was v1beta1, should have been v1). #1043
* [BUGFIX] Use the correct for NetworkPolicy reflector. #1042

## v1.9.3 / 2020-01-22

* [CHANGE] Remove experimental hpa metrics kube_hpa_status_current_metrics_average_utilization and kube_hpa_status_current_metrics_average_value #1030

## v1.9.2 / 2020-01-13

* [BUGFIX] Fix segfault with External metrics #1023

## v1.9.1 / 2020-01-10

* [BUGFIX] Fix segfault in hpa metrics #1019
* [BUGFIX] Fix nil panics when parsing hpa memory current metrics #1014

## v1.9.0 / 2019-12-20

After a testing period of 7 days, there were no additional bugs found or features introduced.

## v1.9.0-rc.1 / 2019-12-12

* [BUGFIX] Move resource version from metric label to metric number value #997

## v1.9.0-rc.0 / 2019-12-04

* [CHANGE] Add tools as go modules #927
* [FEATURE] Add `kube_hpa_spec_target_metric` metric. #966
* [FEATURE] Add hpa stats for current utilization and average value. #961
* [FEATURE] Add `kube_namespace_status_condition` metric. #949
* [FEATURE] Add `kube_persistentvolumeclaim_status_condition` and `kube_persistentvolumeclaim_status_phase` metrics #952
* [FEATURE] Add `kube_networkpolicy_*` metrics #893
* [FEATURE] Add `kube_volumeattachment_*` metrics #946
* [FEATURE] add `kube_mutatingwebhookconfiguration_*`, `kube_validatingwebhookconfiguration_*` metrics #914
* [ENHANCEMENT] Add `pod_cidr` label to the `kube_node_info` metric. #963
* [ENHANCEMENT] Generate all manifests from jsonnet #908
* [ENHANCEMENT] Add kube-state-metrics alerting rules. #962
* [ENHANCEMENT] Add "Evicted" to the set of container terminated reasons. #968
* [BUGFIX] Add check for ReclaimPolicy, VolumeBindingMode storageclass metrics. #929
* [BUGFIX] Use single MultiListerWatcher for single store to fix missing metrics when watching multiple namespaces. #969
* [BUGFIX] Fix nil panics parsing HPA CPU current metrics. #993

## v1.8.0 / 2019-10-01

After a testing period of 7 days, there were no additional bugs found or features introduced.

## v1.8.0-rc.1 / 2019-09-24

* [CHANGE] Pin go version to go mod artifact file #882
* [BUGFIX] Correct mapping of hpa condition status labels  #890

## v1.8.0-rc.0 / 2019-09-10

* [FEATURE] Introduce sharding (and experimental auto-sharding) #613
* [FEATURE] Add `kube_pod_status_unschedulable metric` #835
* [CHANGE] Makefile: Remove tmpdir after container build #867
* [ENHANCEMENT] Add metrics about kube-state-metric's interaction with the Kubernetes API. #866
* [FEATURE] Add `kube_node_role metric` #877
* [ENHANCEMENT] Add support for Darwin OS in e2e test #879

## v1.7.2 / 2019-08-05

* [CHANGE] Revert "add `kube_*_annotations metrics` for all objects" #859
* [CHANGE] Remove `kube_namespace_annotations` metric #859

## v1.7.1 / 2019-07-18

* [BUGFIX] Fix crash due to missing ingress http block. #831
* [BUGFIX] Add nil guard checks when querying VPA objects. #832

## v1.7.0 / 2019-07-17

After a testing period of 7 days, there were no additional bugs found or features introduced.

## v1.7.0-rc.1 / 2019-07-10

* [BUGFIX] Use the appsv1 apigroup when building the reflector for replicasets. #816

## v1.7.0-rc.0 / 2019-07-10

* [CHANGE] Use appsv1 apigroup for ReplicaSet. #804
* [CHANGE] Use distroless/static as base image to further reduce image size. #748
* [CHANGE] Return standardized text for health endpoint. #767
* [ENHANCEMENT] Add DeadlineExceeded pod termination reason. #740
* [ENHANCEMENT] Add CreateContainerError and InvalidImageName waiting reasons. #763
* [FEATURE] Add Pod init container metrics. #762
* [FEATURE] Add Metrics About StorageClass. #777
* [FEATURE] Allow black/white- listing of metrics by regex. #773
* [FEATURE] Add metrics for VerticalPodAutoscaler objects (experimental and disabled by default). #791
* [FEATURE] Add (experimental) `kube_*_annotations` metrics. #770

## v1.6.0 / 2019-05-06

After a testing period of 10 days (release candidate 2), there were no
additional bugs found, thus releasing the stable version v1.6.0.

* [FEATURE] Add `kube_replicaset_labels` to replicaset collector (#638).
* [FEATURE] Add ingresses collector (#640).
* [FEATURE] Add certificate signing request collector (#650).
* [FEATURE] Add `kube_persistentvolumeclaim_access_mode` metric (#673).
* [FEATURE] Add `kube_persistentvolume_capacity` metric (#674).
* [FEATURE] Add `kube_job_owner` metric (#681).
* [ENHANCEMENT] Add `priority_class` label to `kube_pod_info` metric (#713).
* [BUGFIX] Bump addon-resizer patch version reducing resource consumption (#724).
* [BUGFIX] Use k8s.io/api/apps/v1 for DaemonSet, Deployment and StatefulSet reflector (#720).

## v1.5.0 / 2019-01-10

After a testing period of 30 days, there were no additional bugs found or features introduced. Due to no bugs being reported over an in total 41 days period, we feel no more pre-releases are necessary for a stable release.

This release's focus was a large architectural change in order to improve performance and resource usage of kube-state-metrics drastically. Special thanks to @mxinden for his hard work on this! See the changelog of the pre-releases for more detailed information and related pull requests.

An additional change has been requested to be listed in the release notes:

* [CHANGE] Due to removal of the surrounding mechanism the `ksm_resources_per_scrape` and `ksm_scrape_error_total` metrics no longer exists.

## v1.5.0-beta.0 / 2018-12-11

After a testing period of 11 days, there were no additional bugs found or features introduced.

## v1.5.0-alpha.0 / 2018-11-30

* [CHANGE] Disable gzip compression of kube-state-metrics responses by default. Can be re-enabled via `--enable-gzip-encoding`. See #563 for more details.
* [FEATURE] Add `kube_replicaset_owner` metric (#520).
* [FEATURE] Add `kube_pod_container_status_last_terminated_reason` metric (#535).
* [FEATURE] Add `stateful_set_status.{current,update}_revision` metric (#545).
* [FEATURE] Add pod disruption budget collector (#551).
* [FEATURE] Make kube-state-metrics usable as a library (#575).
* [FEATURE] Add `kube_service_spec_external_ip` metric and add `external_name` and `load_balancer_ip` label to `kube_service_info` metric (#571).
* [ENHANCEMENT] Add uid info in `kube_pod_info` metric (#508).
* [ENHANCEMENT] Update addon-resizer to 1.8.3 and increase resource limits (#552).
* [ENHANCEMENT] Improve metric caching and rendering performance (#498).
* [ENHANCEMENT] Adding CreateContainerConfigError as possible reason for container not starting (#578).

## v1.4.0 / 2018-08-22

After a testing period of 16 days, there were no additional bugs found or features introduced.

## v1.4.0-rc.0 / 2018-08-06

* [CHANGE] `kube_job_status_start_time` and `kube_job_status_completion_time` metric types changed from counter to gauge.
* [CHANGE] `job` label to `job_name` as this collides with the Prometheus `job` label.
* [FEATURE] Allow white- and black-listing metrics to be exposed.
* [FEATURE] Add `kube_node_status_capacity` and `kube_node_status_allocatable` metrics.
* [FEATURE] Add `kube_pod_status_scheduled_time` metric.
* [FEATURE] Add `kube_pod_container_status_waiting_reason` and `kube_pod_container_status_terminated_reason` metrics.
* [ENHANCEMENT] Add generic resource metrics for Pods, `kube_pod_container_resource_requests` and `kube_pod_container_resource_limits`. This deprecates the old resource metrics for Pods.
* [ENHANCEMENT] Prefer protobuf over json when communicating with the Kubernetes API.
* [ENHANCEMENT] Add dynamic volume support.
* [ENHANCEMENT] Properly set kube-state-metrics user agent when performing requests against the Kubernetes API.
* [BUGFIX] Fix incrorrect HPA metric labels.

## v1.3.1 / 2018-04-12

* [BUGFIX] Use Go 1.10.1 fixing TLS and memory issues.
* [BUGFIX] Fix Pod unknown state.

## v1.3.0 / 2018-04-04

After a testing period of 12 days, there were no additional bugs found or features introduced.

## v1.3.0-rc.0 / 2018-03-23

* [CHANGE] Removed `--in-cluster` flag in [#371](https://github.com/kubernetes/kube-state-metrics/pull/371).
  Users can no longer specify `--apiserver` with `--in-cluster=true`. To
  emulate this behaviour in future releases, set the `KUBERNETES_SERVICE_HOST`
  environment variable to the value of the `--apiserver` argument.
* [FEATURE] Allow to specify multiple namespace.
* [FEATURE] Add `kube_pod_completion_time`, `kube_pod_spec_volumes_persistentvolumeclaims_info`, and `kube_pod_spec_volumes_persistentvolumeclaims_readonly` metrics to the Pod collector.
* [FEATURE] Add `kube_node_spec_taint` metric.
* [FEATURE] Add `kube_namespace_annotations` metric.
* [FEATURE] Add `kube_deployment_spec_strategy_rollingupdate_max_surge` metric.
* [FEATURE] Add `kube_persistentvolume_labels` metric.
* [FEATURE] Add `kube_persistentvolumeclaim_lables` metric.
* [FEATURE] Add `kube_daemonset_labels` metric.
* [FEATURE] Add Secret metrics.
* [FEATURE] Add ConfigMap metrics.
* [ENHANCEMENT] Add additional reasons to `kube_pod_container_status_waiting_reason` metric.
* [BUGFIX] Fix namespacing of HPA.
* [BUGFIX] Fix namespacing of PersistentVolumes.
* [BUGFIX] Fix CronJob tab parsing.

## v1.2.0 / 2018-01-15

After a testing period of 10 days, there were no additional bugs found or features introduced.

## v1.2.0-rc.0 / 2018-01-05

* [CHANGE] The CronJob collector now expects the version to be v1beta1.
* [FEATURE] Add `Endpoints` metrics collector.
* [FEATURE] Add `PersistentVolume` metrics collector.
* [FEATURE] Add `HorizontalPodAutoscaler` metrics collector.
* [FEATURE] Add `kube_pod_container_status_terminated_reason` metric.
* [FEATURE] Add `kube_job_labels` metric.
* [FEATURE] Add `kube_cronjob_labels` metric.
* [FEATURE] Add `kube_service_spec_type` metric.
* [FEATURE] Add `kube_statefulset_status_replicas_current` metric.
* [FEATURE] Add `kube_statefulset_status_replicas_ready` metric.
* [FEATURE] Add `kube_statefulset_status_replicas_updated` metric.
* [ENHANCEMENT] Allow specifying the host/IP kube-state-metrics binds to.
* [ENHANCEMENT] Add `volumename` label to `kube_persistentvolumeclaim_info` metric.
* [ENHANCEMENT] Add `cluster_ip` label to `kube_service_info` metric.
* [ENHANCEMENT] Print version on startup and useful debug information at runtime.
* [ENHANCEMENT] Add metrics for kube-state-metrics itself. For separation purposes this listens on a separate host/IP and port, both configurable respectively.

## v1.1.0 / 2017-10-19

After a testing period of one week, there were no additional bugs found or features introduced.

## v1.1.0-rc.0 / 2017-10-12

* [FEATURE] Add `kube_pod_container_status_waiting_reason` metric.
* [FEATURE] Add `kube_node_status_capacity_nvidia_gpu_cards` and `kube_node_status_allocatable_nvidia_gpu_cards` metrics.
* [FEATURE] Add `kube_persistentvolumeclaim_info`, `kube_persistentvolumeclaim_status_phase` and `kube_persistentvolumeclaim_resource_requests_storage_bytes` metrics.
* [FEATURE] Add `kube_cronjob_created` metric.
* [FEATURE] Add `kube_namespace_status_phase`, `kube_namespace_labels` and `kube_namespace_created` metrics.
* [FEATURE] Add `*_created` metrics for all available collectors and resources.
* [FEATURE] Add ability to specify glog flags.
* [FEATURE] Add ability to limit kube-state-metrics objects to single namespace.
* [ENHANCEMENT] Bump client-go to 5.0 release branch.
* [ENHANCEMENT] Add pprof endpoints for profiling.
* [ENHANCEMENT] Log resources and API versions used when collecting metrics from objects.
* [ENHANCEMENT] Log number of resources used to generate metrics off of.
* [ENHANCEMENT] Improve a usage message for collectors flag.
* [BUGFIX] Fix Job start time nil panic.

## v1.0.1 / 2017-08-24

* [BUGFIX] Fix nil pointer panic when pods have an owner without controllers.

## v1.0.0 / 2017-08-09

After a testing period of one week, there were no additional bugs found or features introduced.

## v1.0.0-rc.1 / 2017-08-02

* [CHANGE] Remove `kube_node_status_ready`, `kube_node_status_out_of_disk`, `kube_node_status_memory_pressure`, `kube_node_status_disk_pressure`, and `kube_node_status_network_unavailable` metrics in favor of one generic `kube_node_status_condition` metric.
* [CHANGE] Flatten created by label on `kube_pod_info` metric.
* [FEATURE] Add `kube_pod_start_time` metric.
* [FEATURE] Add PersistentVolumeClaim metrics.
* [FEATURE] Add StatefulSet metrics.
* [FEATURE] Add Job and CronJob metrics.
* [FEATURE] Add label metrics for deployments.
* [FEATURE] Add `kube_pod_owner` metrics.
* [ENHANCEMENT] Add `provider_id` label to `kube_node_info` metric.
* [BUGFIX] Fix various nil pointer panics.

## v0.5.0 / 2017-05-03

* [FEATURE] Add label metrics for Pods, Nodes and Services.
* [FEATURE] Expose number of ready Pods for DaemonSets.
* [FEATURE] Add LimitRange metrics.
* [FEATURE] Add ReplicationController metrics.
* [ENHANCEMENT] Add NodeMemoryPressure, NodeDiskPressure, NodeNetworkUnavailable condition metrics.
* [ENHANCEMENT] Add `created_by` label to `kube_pod_info` metric.

## v0.4.1 / 2017-02-10

* [BUGFIX] fix panic if max unavailable if rolling update is unset

## v0.4.0 / 2017-02-07

* [FEATURE] Add replicaset metrics
* [FEATURE] Add resourcequota metrics
* [FEATURE] Add daemonset metrics
* [FEATURE] Add resource limit and request metrics for pod containers
* [FEATURE] Add node name label to `kube_pod_info` metric
* [FEATURE] Add rolling update metrics for deployments
* [ENHANCEMENT] Allow disabling collectors
* [ENHANCEMENT] Improve in cluster vs non in cluster configuration

## v0.3.0 / 2016-10-18

* [FEATURE] Add pod metrics: `kube_pod_status_scheduled`, `kube_pod_container_requested_cpu_cores` and `kube_pod_container_requested_memory_bytes`
* [FEATURE] Add deployment metric `kube_deployment_metadata_generation`
* [FEATURE] Add node metric `kube_node_spec_unschedulable`
* [CHANGE] Rename `kube_node_status_allocateable_*` to `kube_node_status_allocatable_*`

## v0.2.0 / 2016-09-14

* [CHANGE] Prefix all metrics with `kube_`
* [CHANGE] Make metric collection synchronous
* [FEATURE] Add a number of node/pod/deployment metrics
