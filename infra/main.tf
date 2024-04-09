#Terraform backend configuration
terraform {
  backend "gcs" {
    bucket = "state-file-website"
    prefix = "terraform/state"
  }
}

#Create the bucket 
resource "google_storage_bucket" "website" {
    name = "website-by-dom-j"
    location = "europe-west2"
}

#Upload the html file to the bucket
resource "google_storage_bucket_object" "static_website_src" {
    name = "index.html"
    source = "../website/index.html"
    bucket = google_storage_bucket.website.name
}

#reate the images folder in the Bucket
resource "google_storage_bucket_object" "images" {
  name = "images/"
  bucket = google_storage_bucket.website.name
  content = " "
}

#Upload all the files from the images folder
resource "google_storage_bucket_object" "images-files" {
  for_each = fileset("../website/images/","*.jpg")
  bucket       = google_storage_bucket.website.name 
  name         = "images/${basename(each.key)}"
  source       = "../website/images/${basename(each.key)}"
}

#Create the assets folder in the bucket
resource "google_storage_bucket_object" "assets" {
  name = "assets/"
  bucket = google_storage_bucket.website.name
  content = " "
}

#Upload all the fwebfonts from the assets folder
resource "google_storage_bucket_object" "assets-files" {
  for_each = fileset("../website/assets/webfonts","**")
  bucket = google_storage_bucket.website.name
  name = "assets/webfonts/${basename(each.key)}"
  source = "../website/assets/webfonts/${basename(each.key)}"
}

#Upload the js files from the assets folder
resource "google_storage_bucket_object" "js-files" {
  for_each = fileset("../website/assets/js","**")
  bucket = google_storage_bucket.website.name
  name = "assets/js/${basename(each.key)}"
  source = "../website/assets/js/${basename(each.key)}"
}

#Upload the css folder's files mian and fontawesome-all
resource "google_storage_bucket_object" "css-files" {
  for_each = fileset("../website/assets/css","*")
  bucket = google_storage_bucket.website.name
  name = "assets/css/${basename(each.key)}"
  source = "../website/assets/css/${basename(each.key)}"
}

#Upload the css-images folder's content
resource "google_storage_bucket_object" "css-images-files" {
  for_each = fileset("../website/assets/css/images","*")
  bucket = google_storage_bucket.website.name
  name = "assets/css/images/${basename(each.key)}"
  source = "../website/assets/css/images/${basename(each.key)}"
}

#Upload the sass folder's content mian file
resource "google_storage_bucket_object" "sass-files" {
  for_each = fileset("../website/assets/sass","*")
  bucket = google_storage_bucket.website.name
  name = "assets/sass/${basename(each.key)}"
  source = "../website/assets/sass/${basename(each.key)}"
}

#Upload the sass-libs folder's content
resource "google_storage_bucket_object" "sass-libs-files" {
  for_each = fileset("../website/assets/sass/libs","*")
  bucket = google_storage_bucket.website.name
  name = "assets/sass/libs/${basename(each.key)}"
  source = "../website/assets/sass/libs/${basename(each.key)}"
}

# Make new object public
resource "google_storage_bucket_iam_member" "public_rule" {
    provider = google
    bucket = google_storage_bucket.website.name
    role = "roles/storage.objectViewer"
    member = "allUsers"
}

#Reserve a static external IP address if it does not exist
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