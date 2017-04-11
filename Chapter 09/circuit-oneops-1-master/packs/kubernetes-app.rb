name          "kubernetes-app"
description   "Kubernetes Application/Deployment"
type          "Platform"
category      "Worker Application"

environment "single", {}
environment "redundant", {}
entrypoint "app"

resource "app",
	:cookbook => "oneops.1.container-app",
	:design	=> true,
	:requires => {"constraint" => "1..*", "services" => "kubernetes" }

