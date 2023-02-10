packer {
  required_plugins {
    boilerplate = {
      version = ">= 0.0.1"
      source  = "github.com/takumin/boilerplate"
    }
  }
}

source "boilerplate" "example" {
}

build {
  sources = ["source.boilerplate.example"]
}
