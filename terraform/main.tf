variable "region" {
  default = "lon1"
}

provider "digitalocean" {
}

provider "aws" {
  alias  = "wasabi"
  region = "us-east-1"

  endpoints {
    sts = "https://sts.wasabisys.com"
    iam = "https://iam.wasabisys.com"
    s3  = "https://s3.wasabisys.com"
  }

  s3_use_path_style      = true
  skip_get_ec2_platforms = true
}
