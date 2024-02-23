# Bucket to store website
resource "google_storage_bucket" "website" {
    name = "website-by-dom-j"
    location = "europe-west2"
}

# Make new object public
resource "google_storage_object_access_control" "public_rule" {
    object = google_storage_bucket_object.static_website_src.name
    bucket = google_storage_bucket.website.name
    role = "READER"
    entity = "allUsers"
}


#Upload the html file to the bucket
resource "google_storage_bucket_object" "static_website_src" {
    name = "index.html"
    source = "../website/index.html"
    bucket = google_storage_bucket.website.name
}

#Reserve a static external IP address
resource "google_compute_global_address" "website_ip" {
    name = "website-lb-ip"
}

#Get the managed DNS Zone
data "google_dns_managed_zone" "dns_zone"{
    name = "website-gcp"
}

#Add the IP to the DNS
resource "google_dns_record_set" "gcp" {
  name = "website.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type = "A"
  ttl=300
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas = [google_compute_global_address.website_ip.address]
}

#Add the bucket as a CDN backup
resource "google_compute_backend_bucket" "website-backend" {
    name = "website-bucket"
    bucket_name = google_storage_bucket.website.name
    description = "Contains files needed for the website"
    enable_cdn = true
  
}

#Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
    provider = google
    name = "website-domssocial-cert"
    managed {
        domains = [google_dns_record_set.gcp.name]
    }
}

#GCP URL MAP
resource "google_compute_url_map" "website" {
  name = "website-url-map"
  default_service = google_compute_backend_bucket.website-backend.self_link
  host_rule {
    hosts = ["*"]
    path_matcher = "allpaths"
    }
    path_matcher {
        name = "allpaths"
        default_service = google_compute_backend_bucket.website-backend.self_link
    }
}

#GCP HTTPS Proxy

resource "google_compute_target_https_proxy" "website" {
  provider = google  
  name = "website--target-proxy-uk"
  url_map = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

#GCP forwarding rule 
resource "google_compute_global_forwarding_rule" "default" {
    provider = google
    name = "website-forarding-rule"
    load_balancing_scheme = "EXTERNAL"
    ip_address = google_compute_global_address.website_ip.address
    ip_protocol = "TCP"
    port_range = "443"
    target = google_compute_target_https_proxy.website.self_link
}