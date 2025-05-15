# Create VPC
data "google_compute_network" "vpc" {
  name = "my-vpc"
}

# Create Subnet
data "google_compute_subnetwork" "subnet" {
  name   = "subnet-1"
  region = "us-east4"
}

# Create VPC II
data "google_compute_network" "lab_vpc" {
  name = "lab-vpc"
}

# Create Subnet II
data "google_compute_subnetwork" "lab_subnet" {
  name   = "lab-subnet"
  region = "us-east4"
}

# Create Fortigate VM
resource "google_compute_instance" "fortigate" {
  name              = "fortigate-payg"
  zone              = "us-east4-b"
  machine_type      = "e2-standard-2"
  tags              = ["ssh-allowed"]
  can_ip_forward    = true
  deletion_protection = false

  boot_disk {
    initialize_params {
      image = "projects/mpi-fortigcp-project-001/global/images/fortinet-fgtondemand-6415-20240208-001-w-license"
      size  = 10
    }
  }

metadata = {
  "startup-script" = <<-EOT
    config system interface
      edit port1
        set mode dhcp
        set allowaccess ping https ssh http fgfm
      next
    end

    config router static
      edit 1
        set dst 0.0.0.0/0
        set gateway 10.20.0.1
        set device port1
      next
    end
  EOT
  "serial-port-enable"      = "true"
  "enable-guest-attributes" = "true"
}


  network_interface {
    network    = data.google_compute_network.vpc.self_link
    subnetwork = data.google_compute_subnetwork.subnet.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }

  network_interface {
    network    = data.google_compute_network.lab_vpc.self_link
    subnetwork = data.google_compute_subnetwork.lab_subnet.self_link
  }
}

# Create SNMP Server
resource "google_compute_instance" "snmp_server" {
  name           = "snmp-server"
  zone           = "us-east4-b"
  machine_type   = "e2-micro"
  tags           = ["snmp-server"]
  can_ip_forward = false

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network    = data.google_compute_network.vpc.self_link
    subnetwork = data.google_compute_subnetwork.subnet.self_link
    network_ip = "10.20.0.99"

    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y snmpd
    sed -i 's/^agentAddress .*/agentAddress udp:161/' /etc/snmp/snmpd.conf
    sed -i 's/^# rocommunity.*/rocommunity public default -V systemonly/' /etc/snmp/snmpd.conf
    systemctl restart snmpd
  EOT
}