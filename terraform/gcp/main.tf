provider "google" {
  project = var.gcp_project_id
  credentials = file("./google-credentials.json")
}

resource "google_compute_instance" "vm_instance" {
  name         = "sing-box"
  machine_type = "e2-micro"
  zone         = "asia-east1-a" # Taiwan

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "vpn:${file("./ssh_key.pub")}"
  }  

  tags = ["vpn"]

  provisioner "file" {
    source      = "../scripts/initialize-server.sh"
    destination = "/tmp/initialize-server.sh"

    connection {
      type        = "ssh"
      user        = "vpn"
      private_key = file("./ssh_key")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "file" {
    source      = "../../output/server.json"
    destination = "/tmp/config.json"

    connection {
      type        = "ssh"
      user        = "vpn"
      private_key = file("./ssh_key")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/initialize-server.sh",
      "sudo mkdir -p /etc/sing-box",
      "sudo mv /tmp/config.json /etc/sing-box/config.json",
      "sudo systemctl restart sing-box"
    ]

    connection {
      type        = "ssh"
      user        = "vpn"
      private_key = file("./ssh_key")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}

resource "google_compute_firewall" "allow_443" {
  name    = "allow-443"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags   = ["vpn"]
  source_ranges = ["0.0.0.0/0"]
}

# Output variable: Public IP address
output "public_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
