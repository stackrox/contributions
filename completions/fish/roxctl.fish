# Command Sets
set -l base_commands central cluster collector deployment helm help image scanner sensor version
set -l central_commands backup cert db debug generate init-bundles license userpki whoami
set -l image_commands check scan
set -l deployment_commands check
set -l scanner_commands generate upload-db
set -l sensor_commands generate generate-certs get-bundle

# Disable file completions
complete -c roxctl -f

# Base flags
complete -c roxctl -s h -l help -d "more information about a command"
complete -c roxctl -s e -l endpoint -d "endpoint for service to contact"
complete -c roxctl -l insecure -d "skip tls certification validation"
complete -c roxctl -s p -l password -d "password for basic auth"
complete -c roxctl -s e -l endpoint -d "stackrox central endpoint"
complete -c roxctl -l token-file -d "use API token in the provided file"


# Base commands
complete -c roxctl -n "not __fish_seen_subcommand_from $base_commands" -a "$base_commands"

# Central subcommands
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "backup" -d "backup the StackRox database and certificates"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "cert" -d "download certificate chain for the Central service"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "db" -d "commands related to the StackRox database"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "debug" -d "debug the Central Service"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "generate" -d "generate k8s manifests to deploy StackRox Central"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "init-bundles" -d "manage cluster init bundle"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "license" -d "add and display license information"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "userpki" -d "manage user certificate authorization providers"
complete -c roxctl -n "__fish_seen_subcommand_from central; and not __fish_seen_subcommand_from $central_commands" -a "whoami" -d "info about the current user"

# Image flags
complete -c roxctl -n "__fish_seen_subcommand_from $image_commands" -s t -l timeout -d "timeout for api requests (default 10m0s)"
complete -c roxctl -n "__fish_seen_subcommand_from $image_commands" -s i -l image -d "image name and tag" -a "(docker image list --format '{{.Repository}}:{{.Tag}}')"
complete -c roxctl -n "__fish_seen_subcommand_from $image_commands" -s a -l include-snoozed -d "return both snoozed and unsnoozed CVEs if set to false"

# Image subcommands
complete -c roxctl -n "__fish_seen_subcommand_from image; and not __fish_seen_subcommand_from $image_commands" -a "check" -d "check images for build time policy violations"
complete -c roxctl -n "__fish_seen_subcommand_from image; and not __fish_seen_subcommand_from $image_commands" -a "scan" -d "scan the specified images"

# Deployment flags
complete -c roxctl -n "__fish_seen_subcommand_from $deployment_commands" -s t -l timeout -d "timeout for api requests (default 10m0s)"
complete -c roxctl -n "__fish_seen_subcommand_from $deployment_commands" -s f -l file -d "evaluate policies against yaml file" -a "(find . | grep -i -e '\.y\(aml\|ml\)' | head -n 10 | sort -d -u)"


# Deployment subcommands
complete -c roxctl -n "__fish_seen_subcommand_from deployment; and not __fish_seen_subcommand_from $deployment_commands" -a "check" -d "check deployments for deploy time policy violations"

# Scanner flags
complete -c roxctl -n "__fish_seen_subcommand_from $scanner_commands" -s t -l timeout -d "timeout for api requests (default 10m0s)"

# Scanner subcommands
complete -c roxctl -n "__fish_seen_subcommand_from scanner; and not __fish_seen_subcommand_from $scanner_commands" -a "generate" -d "generate k8s manifests to deploy StackRox Scanner"
complete -c roxctl -n "__fish_seen_subcommand_from scanner; and not __fish_seen_subcommand_from $scanner_commands" -a "upload-db" -d "upload a vulnerability database for the StackRox Scanner"

# Sensor flags
complete -c roxctl -n "__fish_seen_subcommand_from $sensor_commands" -s t -l timeout -d "timeout for api requests (default 10m0s)"

# Sensor subcommands
complete -c roxctl -n "__fish_seen_subcommand_from sensor; and not __fish_seen_subcommand_from $sensor_commands" -a "generate" -d "generate k8s manifests to deploy StackRox services into secured clusters"
complete -c roxctl -n "__fish_seen_subcommand_from sensor; and not __fish_seen_subcommand_from $sensor_commands" -a "generate-certs" -d "download a YAML file with renewed certificates"
complete -c roxctl -n "__fish_seen_subcommand_from sensor; and not __fish_seen_subcommand_from $sensor_commands" -a "get-bundle" -d "download a bundle with the files to deploy StackRox services into a cluster"


