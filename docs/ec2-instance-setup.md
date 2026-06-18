# EC2 Instance Setup

This document describes the **ragFLow** AWS EC2 instance used to run
[RAGFlow](https://github.com/infiniflow/ragflow) and related utility scripts
from this repository.

## Instance Specifications

| Setting        | Value                          |
| -------------- | ------------------------------ |
| Instance name  | `ragFLow`                      |
| Instance type  | `t3.xlarge`                    |
| vCPUs          | 4                              |
| Memory         | 16 GiB                         |
| Storage        | 30 GB SSD (EBS)                |
| Platform       | AWS EC2                        |
| Configuration  | All other settings use AWS defaults |
| RAGFlow version | `v0.25.6` (stable release)         |

The `t3.xlarge` instance type is a general-purpose burstable instance suitable
for development, Docker workloads, and light-to-moderate production use.

## Prerequisites

- An AWS account with permissions to create EC2 instances, security groups, and
  key pairs
- AWS CLI configured locally (optional, for CLI-based setup)
- An SSH key pair for instance access

## Step 1: Sign in to AWS

1. Open the [AWS Management Console](https://console.aws.amazon.com/).
2. Sign in with your AWS account credentials.
3. Select the AWS Region where you want to launch the instance (for example,
   `us-east-1`).

## Step 2: Launch the EC2 Instance

1. Go to **EC2** → **Instances** → **Launch instances**.
2. Enter the instance name: **`ragFLow`**.

### Choose an Amazon Machine Image (AMI)

3. Choose the **Ubuntu Server** AMI (e.g., Ubuntu Server 22.04 LTS) – this is the default Ubuntu image on AWS.

### Choose Instance Type

4. Under **Instance type**, select **t3.xlarge** (4 vCPUs, 16 GiB memory).

### Configure Storage

5. Under **Configure storage**, set the root volume size to **30 GiB**.
   - Keep the default volume type (General Purpose SSD).

### Network, Security, and Key Pair

6. Leave all remaining options at their **default settings**:

- Default VPC and subnet
- Default security group – add an inbound rule allowing all traffic from `0.0.0.0/0`. If SSL is enabled, also add an inbound rule for port 443.
- Default key pair selection
- Default network and advanced settings

### Review and Launch

7. Review the summary:
   - Name: `ragFLow`
   - Instance type: `t3.xlarge`
   - Memory: 16 GiB
   - Storage: 30 GB SSD
   - All other settings: AWS defaults
8. Click **Launch instance**.

## Step 3: Connect to the Instance

Wait until the **ragFLow** instance state is **Running**, then connect via SSH
using the key pair from the default launch settings.

```bash
chmod 400 /path/to/your-key.pem
ssh -i /path/to/your-key.pem <default-ami-user>@<instance-public-ip>
```

Replace `<instance-public-ip>` with the **Public IPv4 address** of `ragFLow` in
the EC2 console. Use the SSH username for the default AMI (`ubuntu` for Ubuntu,
`ec2-user` for Amazon Linux).

## Step 4: Verify Instance Resources

After connecting, confirm the instance matches the expected specs:

```bash
# CPU count
nproc

# Memory
free -h

# Disk space
df -h /
```

Expected results:

- `nproc` → `4`
- Memory → approximately 16 GiB available
- Root volume → approximately 30 GB

## Step 5: Install Docker

RAGFlow runs via Docker Compose, so Docker must be installed first. Use the
installer script from this repository:

```bash
curl -fsSL https://raw.githubusercontent.com/saiprasaddevare/aws-utility/main/scripts/universal/install-docker.sh | bash
```

After installation, the script creates the `docker` group and adds the current user to it (`sudo groupadd docker && sudo usermod -aG docker $USER`). For the changes to take effect, you need to refresh your group membership. You can either:

- Log out and log back in (most reliable).
- Run `newgrp docker` in your current terminal session to apply the changes immediately.

Then verify:

```bash
docker --version
docker compose version
docker run hello-world
```

See the main [README](../README.md) for full Docker installation details.

## Step 6: Configure Kernel Settings for RAGFlow

RAGFlow requires a higher `vm.max_map_count` value (used by Elasticsearch and
similar services). Apply it immediately and persist it across reboots:

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

Verify the setting:

```bash
sysctl vm.max_map_count
```

Expected output: `vm.max_map_count = 262144`

## Step 7: Clone and Checkout RAGFlow

Clone the official RAGFlow repository and switch to the stable release
`v0.25.6`:

```bash
git clone https://github.com/infiniflow/ragflow.git
cd ragflow
git checkout v0.25.6
```

Confirm the active version:

```bash
git describe --tags
```

Expected output includes `v0.25.6`.

## Step 8: Start RAGFlow with Docker Compose

Navigate to the Docker folder within the cloned repository, then start all services in detached mode:

```bash
cd docker
docker compose up -d
```

Check that containers are running:

```bash
docker compose ps
```

Follow logs if needed:

```bash
docker compose logs -f
```

After running `docker compose up -d`, the following containers will be started:

| CONTAINER ID | IMAGE                                      | STATUS                    | PORTS                                                                                                                                                       | NAMES                    |
|--------------|--------------------------------------------|---------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| 22ba59c05890 | infiniflow/ragflow:v0.25.6                 | Up 20 minutes             | 0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp, 0.0.0.0:9380-9384->9380-9384/tcp, [::]:9380-9384->9380-9384/tcp                 | docker-ragflow-cpu-1     |
| ffc77100ff65 | mysql:8.0.39                               | Up 20 minutes (healthy)   | 0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp, 33060/tcp                                                                                                      | docker-mysql-1           |
| 886524928ce5 | elasticsearch:8.11.3                       | Up 20 minutes (healthy)   | 9300/tcp, 0.0.0.0:1200->9200/tcp, [::]:1200->9200/tcp                                                                                                       | docker-es01-1            |
| f0a7282bc90a | pgsty/minio:RELEASE.2026-03-25T00-00-00Z  | Up 20 minutes (healthy)   | 0.0.0.0:9000-9001->9000-9001/tcp, [::]:9000-9001->9000-9001/tcp                                                                                             | docker-minio-1           |
| 760b4f49d903 | valkey/valkey:8                            | Up 20 minutes (healthy)   | 0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp                                                                                                                 | docker-redis-1           |

## Step 9: Access RAGFlow UI

Once startup completes, open the RAGFlow web UI in a browser using the EC2 instance's public IPv4 address or its public DNS name, e.g.:

- `http://<public-ip>` (or `http://<public-dns>`) for non‑SSL access
- `https://<public-ip>` (or `https://<public-dns>`) if you have enabled SSL

Use the port defined in the RAGFlow `docker-compose` configuration (default 80 for HTTP, 443 for HTTPS). See the [RAGFlow documentation](https://github.com/infiniflow/ragflow) for the default port and first‑login steps.

## Step 10: Install Cloudflared and Create a Tunnel

To securely expose the RAGFlow UI without opening additional ports, install
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
(`cloudflared`) and create a quick tunnel.

### Install cloudflared

```bash
# Download the latest Linux version
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64

# Give it permission to run
chmod +x cloudflared-linux-amd64

# Move it so the system can find the command globally
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
```

Verify the installation:

```bash
cloudflared --version
```

### Verify It Works

Test if the system recognizes it now by checking the version:

```bash
cloudflared --version
```

If it spits out a version number, you are good to go!

### Start Your Quick Tunnel

Now you can safely run your tunnel command again:

```bash
cloudflared tunnel --url http://localhost:80
```

### Run the Tunnel in the Background

To keep the tunnel running after you close your terminal, launch it in the
background:

```bash
nohup cloudflared tunnel --url http://localhost:80 > tunnel.log 2>&1 &
```

What this command does:

- `nohup` — tells the server not to hang up the process even if you log out.
- `> tunnel.log 2>&1` — sends all output (including the public URL) into a
  file called `tunnel.log`.
- `&` — pushes the task to the background and frees up your terminal prompt.

### Get Your URL

Give the tunnel about 3 to 5 seconds to connect, then read the log file to
find your link:

```bash
cat tunnel.log
```

Look for a line like:

```
Your quick tunnel has been created! Visit it at: https://some-random-words.trycloudflare.com
```

Copy that URL and place it into your HTML iframe or share it as needed. The
tunnel will keep running even after you close your terminal.

The command prints a public `https://<random>.trycloudflare.com` URL. Open
that URL in a browser to access the RAGFlow UI.

> **Note:** Quick tunnels are ephemeral and the URL changes each time you
> restart the command. For a permanent URL, create a named tunnel with a
> Cloudflare account (see the
> [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)).

## Step 11: Configure Models in RAGFlow

After accessing the RAGFlow UI, you need to configure the models used for
chunking, GraphRag, and generating responses from your knowledge base (datasets).

### Add a Model Provider

1. In the RAGFlow web UI, click the **user icon** in the top-right corner.
2. Select **Model Provider** from the left-side navigation.
3. On the right side of the side nav, click **Available Model** to add a new
   model.
4. Fill in the model details (see example below for OpenRouter):

| Field         | Example Value                                  |
| ------------- | ---------------------------------------------- |
| Model Type    | `Chat`                                         |
| Model Name    | `openai/gpt-oss-120b:free`                     |
| Base URL      | `https://openrouter.ai/api/v1`                 |
| API Key       | *(generate from [OpenRouter](https://openrouter.ai))* |
| Max Token     | `10000`                                        |
| Provider Name | `OpenRouter`                                   |

5. Click **Validate** to verify the API key is correct.
6. If validation passes, click **Save** to store the model configuration.

> **Note:** You can use any OpenAI-compatible API provider (e.g., OpenAI,
> Azure OpenAI, OpenRouter, Ollama, vLLM) by entering the appropriate Base
> URL and API Key for that provider.

### Add an Embedding Model

1. Follow the same steps above (user icon → **Model Provider** → **Available
   Model**) to add an **Embedding** model for document chunking and vector
   indexing.
2. Fill in the embedding model details:

| Field         | Example Value                                           |
| ------------- | ------------------------------------------------------- |
| Model Type    | `Embedding`                                             |
| Model Name    | `nvidia/llama-nemotron-embed-vl-1b-v2:free`              |
| Base URL      | `https://openrouter.ai/api/v1`                          |
| API Key       | *(your secret API key)*                                 |
| Max Token     | `32000`                                                 |
| Provider Name | `OpenRouter`                                            |

3. Click **Validate** to verify the API key is correct.
4. If validation passes, click **Save** to store the embedding model
   configuration.

### Set Default Models

After adding both models, set them as the defaults so they are automatically
used for new assistants and datasets:

1. In the **Model Provider** page, find the **Chat** model you added
   (`openai/gpt-oss-120b:free`) and set it as the **Default LLM**.
2. Find the **Embedding** model you added
   (`nvidia/llama-nemotron-embed-vl-1b-v2:free`) and set it as the
   **Default Embedding**.

These defaults ensure that every new assistant and dataset will use these
models without requiring manual selection.

### Create a Dataset

1. From the RAGFlow home page, click **Dataset** in the header tab. This is
   the knowledge base where your documents will be stored and indexed.
2. Click **Create Dataset**.
3. Enter a name for the dataset (e.g., `Sustainability`).
4. Select the **Embedding model**: `nvidia/llama-nemotron-embed-vl-1b-v2:free`.
5. Set **Parse Method** to **Built-in**.
6. Choose the **Built-in Template** based on your document type:

   | Template       | Use Case                                              |
   | -------------- | ----------------------------------------------------- |
   | `General`      | General-purpose documents (default)                   |
   | `Q&A`          | Question-and-answer formatted documents               |
   | `Resume`       | Resume or CV documents                                |
   | `Table`        | Tabular or spreadsheet data                           |
   | `Paper`        | Academic or research papers                           |
   | `Book`         | Book-length documents                                 |
   | `Laws`         | Legal documents                                       |
   | `Presentation` | Presentation slides                                   |
   | `Manual`       | Technical manuals or guides                           |
   | `Picture`      | Image-based documents                                 |

   > For this setup, we will use **General**.

7. Click **Confirm** to create the dataset.

### Upload Files and Start Chunking

1. Open the dataset you just created (e.g., `Sustainability`).
2. Click **Add File** and upload your documents (e.g., sustainability details).
3. In the upload screen, you have two options:

   - **Parse on create**: Enable this option to immediately chunk the file and
     store it in the vector database. The chunking starts automatically after
     upload.

   - **Parse manually**: Leave the option disabled to upload the file without
     chunking. You can run the chunking later when you are ready by clicking
     the **play icon** on the file row.

4. If you chose to parse manually, after uploading, click the **play icon**
   on the file row to start the chunking process.
5. The file will show a **progress bar** while chunking is in progress. You
   can **refresh the page** to see the current progress.
6. Once chunking is complete, the file status will show **Completed**.

### Chat with Your Knowledge Base

1. After parsing is complete, click **Chat** in the header tab.
2. Click **Create Chat** and enter a name (e.g., `Sustainability`).
3. Click **Save** or **Confirm** to create the chat.
4. Click the **settings/gear icon** on the right side of the chat.
5. In the settings panel, add the dataset you created (e.g., `Sustainability`)
   to this chat. This links the dataset so the chat will use it to answer
   questions.
6. Send a test query to verify that the chat retrieves relevant chunks from
   the dataset and generates a response using the LLM.

## Step 12: Post-Setup Recommendations

- **Update the system** after first login:

  ```bash
  # Ubuntu
  sudo apt update && sudo apt upgrade -y

  # Amazon Linux
  sudo dnf update -y
  ```

- **Restrict SSH access** in the security group to trusted IP addresses only.
- **Enable termination protection** in EC2 instance settings if this is a
  long-lived server.
- **Set up billing alerts** in AWS Budgets to monitor costs for the `ragFLow`
  `t3.xlarge` instance.

## Cost Notes

The `t3.xlarge` instance is billed per hour while running. Storage (30 GB EBS)
is billed separately. Stop the instance when not in use to reduce compute costs
(EBS storage charges still apply while the volume exists).

## Related Documentation

- [RAGFlow GitHub Repository](https://github.com/infiniflow/ragflow)
- [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
