variable "dns" {
  type        = "map"
  description = "The DNS server to maintain."

  default = {
    server    = ""
    domain    = ""
    ttl       = ""
    algorithm = ""
    secret    = ""
  }
}

# Configure the DNS Provider
provider "dns" {
  version = ">= 1.0.0"

  update {
    server        = "${var.dns["server"]}"
    key_name      = "${var.dns["domain"]}."
    key_algorithm = "${var.dns["algorithm"]}"
    key_secret    = "${var.dns["secret"]}"
  }
}

# Create a DNS A record set
resource "dns_a_record_set" "dns" {
  count     = "${var.instances}"
  name      = "${var.name}-0${count.index}"
  zone      = "${var.dns["domain"]}."
  ttl       = "${var.dns["ttl"]}"
  addresses = [
    "${var.ip_prefix}${10 + count.index}"
  ]
}
