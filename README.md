# AWS Utility

Utility scripts for setting up common tooling on AWS-hosted Linux instances.

The repository currently includes a universal Docker and Docker Compose installer
for Ubuntu and Amazon Linux servers.

## Contents

```text
scripts/
  universal/
    install-docker.sh  # Installs Docker and Docker Compose on Ubuntu or Amazon Linux
```

## Supported Platforms

The Docker installer supports:

- Ubuntu
- Amazon Linux

Other operating systems are rejected with an unsupported OS message.

## Prerequisites

- An AWS Linux instance running Ubuntu or Amazon Linux
- A user with `sudo` access
- Internet access from the instance to package repositories and GitHub releases

## Install Docker

SSH into your AWS instance first:

```bash
ssh -i /path/to/key.pem ubuntu@your-instance-public-ip
```

Use `ubuntu` for Ubuntu instances and `ec2-user` for Amazon Linux instances.

Use this one-line command to download and run the installer directly on the AWS
instance:

```bash
curl -fsSL https://raw.githubusercontent.com/saiprasaddevare/aws-utility/main/scripts/universal/install-docker.sh | bash
```

The command downloads `scripts/universal/install-docker.sh` from this repository
and runs it on the instance.

If you want to inspect the script before running it, use this safer two-step
option:

```bash
curl -fsSL https://raw.githubusercontent.com/saiprasaddevare/aws-utility/main/scripts/universal/install-docker.sh -o install-docker.sh
chmod +x install-docker.sh
./install-docker.sh
```

The script will:

- Detect whether the host is Ubuntu or Amazon Linux
- Install Docker Engine
- Install Docker Compose V2
- Enable and start the Docker service
- Add the current user to the `docker` group

After installation, close your SSH session and reconnect so the Docker group
membership takes effect.

## Verify Installation

After reconnecting, verify Docker and Docker Compose:

```bash
docker --version
docker compose version
docker run hello-world
```

## Notes

- On Ubuntu, Docker is installed from Docker's official APT repository.
- On Amazon Linux, Docker is installed through `dnf` or `yum`, and Docker Compose
  V2 is installed as a Docker CLI plugin from the latest GitHub release.
- The installer uses `set -e`, so it exits immediately if any command fails.

## License

This project is licensed under the Apache License 2.0. See `LICENSE` for details.
