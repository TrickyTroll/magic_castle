provider "cloudflare" {
  version = "~> 2.0"
}

data "cloudflare_zones" "domain" {
  filter {
    name   = var.domain
    status = "active"
    paused = false
  }
}

data "external" "key2fp" {
  program = ["python", "${path.module}/../key2fp.py"]
  query = {
    ssh_key = var.rsa_public_key
  }
}

resource "cloudflare_record" "loginX_A" {
  count   = length(var.public_ip)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = join(".", [format("login%d", count.index + 1), var.name])
  value   = var.public_ip[count.index]
  type    = "A"
}

resource "cloudflare_record" "loginX_sshfp_rsa_sha256" {
  count   = length(var.public_ip)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = join(".", [format("login%d", count.index + 1), var.name])
  type    = "SSHFP"
  data    = {
    algorithm   = data.external.key2fp.result["algorithm"]
    type        = 2
    fingerprint = data.external.key2fp.result["sha256"]
  }
}

resource "cloudflare_record" "login_A" {
  count   = length(var.public_ip)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = var.name
  value   = var.public_ip[count.index]
  type    = "A"
}

resource "cloudflare_record" "jupyter_A" {
  count   = length(var.public_ip)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "jupyter.${var.name}"
  value   = var.public_ip[count.index]
  type    = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = var.name
  type    = "SSHFP"
  data    = {
    algorithm   = data.external.key2fp.result["algorithm"]
    type        = 2
    fingerprint = data.external.key2fp.result["sha256"]
  }
}

output "hostnames" {
  value = concat(
    distinct(cloudflare_record.login_A[*].hostname),
    cloudflare_record.loginX_A[*].hostname,
  )
}
