resource "google_compute_instance" "ensign" {

  name            = var.instance_name
  zone            = var.zone
  project         = var.project_name
  hostname        = var.hostname
  machine_type    = var.ensign_type
  can_ip_forward  = true
  tags                    = ["ensign", "ministackdev", "ssh-service-public"]
  boot_disk {
    initialize_params {
      image = var.instance_os
      size    = 32
    }
  }
  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.primary_public_ipv4.address
    }
  }
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  lifecycle {
    ignore_changes = [attached_disk]
  }
  metadata = {
    serial-port-logging-enable = "TRUE"
    ssh-keys                   = var.sshkeys
    startup-script             = "${module.startup-script-lib.content}"
    startup-script-custom      = file("${path.module}/bin/startup-centos.sh")
  }
}

resource "google_compute_address" "primary_public_ipv4" {
  name = "primary-public-ipv4"
}

resource "google_dns_record_set" "ensign" {
  name = "ensign.ministack.dev."
  type = "A"
  ttl  = 300
  managed_zone = "ministackdev"
  rrdatas = ["${google_compute_address.primary_public_ipv4.address}"]
  //rrdatas = ["${google_compute_address.primary-public-ipv4.network_interface.0.access_config.0.nat_ip}"]
}

output "public_ipv4" {
  value = google_compute_instance.ensign.network_interface.0.access_config.0.nat_ip
}

