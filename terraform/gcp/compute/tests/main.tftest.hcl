# Runs with `terraform test` against a mocked Google provider: no credentials or cloud costs.
mock_provider "google" {}

run "free_tier_vm" {
  command = plan

  assert {
    condition     = google_compute_instance.app.machine_type == "e2-micro"
    error_message = "The VM must be an e2-micro to stay in the Free Tier."
  }

  assert {
    condition     = google_compute_instance.app.boot_disk[0].initialize_params[0].image == "cos-cloud/cos-stable"
    error_message = "The VM must boot from the cos-stable image family."
  }

  assert {
    condition     = strcontains(google_compute_instance.app.metadata_startup_script, "docker run")
    error_message = "The startup script must start the app container."
  }
}

run "firewall_targets_only_the_vm" {
  command = plan

  assert {
    condition     = google_compute_firewall.allow_app.target_tags == toset(google_compute_instance.app.tags)
    error_message = "The firewall rule must only target the app VM."
  }

  assert {
    condition     = tolist(one(google_compute_firewall.allow_app.allow).ports) == tolist(["8080"])
    error_message = "The firewall rule must open port 8080 only."
  }
}

run "outputs" {
  command = apply

  assert {
    condition     = startswith(output.app_url, "http://") && endswith(output.app_url, ":8080")
    error_message = "app_url must be an http URL on port 8080."
  }
}
