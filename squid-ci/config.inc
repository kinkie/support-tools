set -e -o pipefail
squid_https_repo="https://github.com/squid-cache/squid.git"

# outside the docker containers
shared_docker_homedir=/home/jenkins/docker-images/homedir
shared_docker_squid_reference_repo=${shared_docker_homedir}/lib/squid-reference-repo
