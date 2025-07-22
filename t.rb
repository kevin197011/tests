# frozen_string_literal: true

def create_gcp_instance(hostname:, cpu_count:, memory_gb:, disk_gb:)
  # 组装 machine_type
  machine_type = "e2-custom-#{cpu_count}-#{memory_gb * 1024}"
  # 组装磁盘参数
  create_disk = "auto-delete=yes,boot=yes,device-name=#{hostname},disk-resource-policy=projects/csc5002-infra/regions/asia-east2/resourcePolicies/default-schedule-1,image=projects/centos-cloud/global/images/centos-stream-9-v20250709,mode=rw,size=#{disk_gb},type=pd-balanced"

  params = {
    name: hostname,
    project: 'csc5002-infra',
    zone: 'asia-east2-a',
    machine_type: machine_type,
    network_interface: 'stack-type=IPV4_ONLY,subnet=infra-sub-01,no-address',
    metadata: 'ssh-keys=devops:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCGn19RbmKF4Uj3JTnoHvHYMwWETVqa0YaguiTp6h9MbusYARhryka7YtFE4ifCrNhC/itXZoUiua+ZxPmpQhaELiB9Ev7Oi0QnrRhk3lv60jRv4bRpVj5LTpCtjvDLAuFpqHPaV6BudVZI0w6WolqpNAedtLT3iucbQRzYvNVQSPO4vBaTKajjyqwYs0TKtFAYsD7pWNilR3WwciK7po8I1FjyYlQBQ8s+AqMOqgQadpefWeRcE5yIaoqjUNwpEHBxESoGhueBxifhxEppCEhadeDewI94w+DzdyKqGvdi4vjnXvqmat5XPicyrACjDR+nbmpqNeRd4aJtwW2M/JNlIIpnPuqHF+akz3ODu2sSfTCs5/E800wsmGdp189lPcU9WFKznkqDwX3dCuxATwMprELF7Xutz46Em9MVVXK7wxeTkDzYaZUqqVUTel+I1o1ncZdx9FSeBa+hyRH52nVjdBI6HUxl675P7bCh0PQnzayCek2hX1IV4wRFxDIA9u/Ep/3FJA8JNDyumIgSieACau6lHth/MOX311SBSNj7cKhLG+qQxidz9cJ9bt4Q7hj+zEJjMsiPsQ2YWW0V1u/vWU1YKHY13rbiBPEKvQrJyPt6WiA4p9zuqUw2aiY6ANu2I3HJ/c7mFH/k1dGGMB3Ls/fsHm5F8CBQA3s2M9wQw== devops',
    maintenance_policy: 'MIGRATE',
    provisioning_model: 'STANDARD',
    service_account: '1086790254547-compute@developer.gserviceaccount.com',
    scopes: [
      'https://www.googleapis.com/auth/devstorage.read_only',
      'https://www.googleapis.com/auth/logging.write',
      'https://www.googleapis.com/auth/monitoring.write',
      'https://www.googleapis.com/auth/service.management.readonly',
      'https://www.googleapis.com/auth/servicecontrol',
      'https://www.googleapis.com/auth/trace.append'
    ],
    tags: 'devops',
    create_disk: create_disk,
    no_shielded_secure_boot: true,
    shielded_vtpm: true,
    shielded_integrity_monitoring: true,
    labels: 'goog-ec-src=vm_add-gcloud',
    reservation_affinity: 'any'
  }

  cmd = [
    'gcloud compute instances create', params[:name],
    "--project=#{params[:project]}",
    "--zone=#{params[:zone]}",
    "--machine-type=#{params[:machine_type]}",
    "--network-interface=#{params[:network_interface]}",
    "--metadata=\"#{params[:metadata]}\"",
    "--maintenance-policy=#{params[:maintenance_policy]}",
    "--provisioning-model=#{params[:provisioning_model]}",
    "--service-account=#{params[:service_account]}",
    "--scopes=#{params[:scopes].join(',')}",
    "--tags=#{params[:tags]}",
    "--create-disk=#{params[:create_disk]}",
    ('--no-shielded-secure-boot' if params[:no_shielded_secure_boot]),
    ('--shielded-vtpm' if params[:shielded_vtpm]),
    ('--shielded-integrity-monitoring' if params[:shielded_integrity_monitoring]),
    "--labels=#{params[:labels]}",
    "--reservation-affinity=#{params[:reservation_affinity]}"
  ].compact.join(' ')

  puts "执行命令：\n#{cmd}\n\n"
  system(cmd)
end

# 示例调用
# create_gcp_instance(hostname: 'devops-elk-es-01', cpu_count: 4, memory_gb: 16, disk_gb: 2000)
create_gcp_instance(hostname: 'devops-elk-es-02', cpu_count: 4, memory_gb: 16, disk_gb: 2000)
create_gcp_instance(hostname: 'devops-elk-es-03', cpu_count: 4, memory_gb: 16, disk_gb: 2000)
create_gcp_instance(hostname: 'devops-elk-ls-01', cpu_count: 4, memory_gb: 8, disk_gb: 500)
create_gcp_instance(hostname: 'devops-elk-kb-01', cpu_count: 4, memory_gb: 8, disk_gb: 200)
