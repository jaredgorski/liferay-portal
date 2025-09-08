terraform {
    required_providers {
        local = {
            source = "hashicorp/local"
            version = "~> 2.1"
        }
        null = {
            source = "hashicorp/null"
            version = "~> 3.1"
        }
        packer = {
            source = "toowoxx/packer"
            version = "0.17.2"
        }
    }
}