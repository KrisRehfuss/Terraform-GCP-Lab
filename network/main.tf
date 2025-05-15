# --- network/main.tf ---
resource "google_compute_network" "vpc" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-1"
  region        = "us-east4"
  ip_cidr_range = "10.20.0.0/24"
  network       = google_compute_network.vpc.id
}

resource "google_compute_network" "lab_vpc" {
  name                    = "lab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "lab_subnet" {
  name          = "lab-subnet"
  region        = "us-east4"
  ip_cidr_range = "10.30.0.0/24"
  network       = google_compute_network.lab_vpc.id
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "fw-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "80", "8291"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["73.160.220.29/32"]
  target_tags   = ["ssh-allowed"]
}

resource "google_compute_firewall" "allow_snmp_to_snmp_server" {
  name    = "allow-snmp-to-snmp-server"
  network = google_compute_network.vpc.id

  allow {
    protocol = "udp"
    ports    = ["161"]
  }

  target_tags   = ["snmp-server"]
  source_ranges = ["10.20.0.0/24"]
}

resource "google_compute_firewall" "allow_icmp_to_snmp_external" {
  name    = "allow-icmp-to-snmp-external"
  network = google_compute_network.vpc.id

  allow {
    protocol = "icmp"
  }

  target_tags   = ["snmp-server"]
  source_ranges = ["0.0.0.0/0"]
}