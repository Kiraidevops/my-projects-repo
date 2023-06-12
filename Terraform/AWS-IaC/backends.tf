terraform {
  cloud {
    organization = "kiraidevops"

    workspaces {
      name = "kiraidevops-dev"
    }
  }
}