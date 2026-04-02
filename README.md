# Terraform AWS Highly Available Web Application Lab

A hands-on infrastructure lab that provisions a production-like AWS environment using Terraform, then deliberately introduces failures so students can practice real-world incident investigation and recovery.

---

## What This Lab Does

The lab spins up a highly available web application stack on AWS and automatically triggers two realistic failure scenarios on one of the EC2 instances. You must use AWS monitoring tools to detect, investigate, and fix the issues — mirroring what an engineer would do during an on-call incident.

---

## Architecture Overview


<img width="928" height="627" alt="image" src="https://github.com/user-attachments/assets/31ad2318-d5d6-4b57-affb-711090a4e689" />


**Resources provisioned:**

- VPC with public subnets across two Availability Zones
- Two EC2 instances running Apache HTTP Server (Amazon Linux 2023)
- Application Load Balancer with health checks
- CloudWatch alarms for CPU utilisation
- SNS topic for email notifications
- Automated failure simulation scripts

---

## Failure Scenarios

Two failures are injected automatically on one EC2 instance:

### 1 — CPU Stress Event

A `stress-ng` process drives CPU utilisation to abnormal levels. CloudWatch detects the spike and fires an SNS alert to notify the student.

### 2 — Application Failure

The Apache service is stopped programmatically. The Load Balancer's health checks detect the unresponsive instance and remove it from rotation, directing all traffic to the healthy instance.

Students must investigate both failures, identify root causes, and restore the system to a healthy state.

---

## Prerequisites

- AWS account with sufficient IAM permissions (EC2, VPC, ALB, CloudWatch, SNS)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI configured (`aws configure`)
- An email address to receive SNS alerts

---

## Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd <repo-directory>

# Initialise Terraform
terraform init

# Preview the changes
terraform plan

# Deploy the infrastructure
terraform apply
```

After `apply` completes, Terraform outputs the Load Balancer DNS name. Open it in a browser to verify both servers are responding. The failure simulation starts automatically within a few minutes.

---

## Technologies Used

| Category | Tool / Service |
|---|---|
| Infrastructure as Code | Terraform |
| Compute | AWS EC2 (Amazon Linux 2023) |
| Load Balancing | AWS Application Load Balancer |
| Monitoring | AWS CloudWatch |
| Alerting | AWS SNS |
| Web Server | Apache HTTP Server |
| Stress Testing | stress-ng |

---

## Skills Demonstrated

- Infrastructure as Code with Terraform
- High availability architecture across multiple AZs
- Cloud monitoring and alarm configuration
- Incident detection, investigation, and response
- Root cause analysis
- Service recovery procedures
- Vertical scaling with Terraform

---

## Student Troubleshooting Worksheet

Work through each step in order. Record your findings as you go.

---

### Objective

Investigate CloudWatch alerts and restore full system health after simulated failures.

---

### Step 1 — Observe the System

Open the application using the Load Balancer DNS name.

- Are both servers responding?
- Which server names appear on the page?

---

### Step 2 — Check CPU Metrics

Navigate to: **CloudWatch → Metrics → EC2 → CPUUtilization**

- Which instance shows elevated CPU?
- What is the peak CPU percentage?
- How long does the spike last?

---

### Step 3 — Check CloudWatch Alarms

Navigate to: **CloudWatch → Alarms**

- Which alarms have triggered?
- What metric caused the alarm state?

---

### Step 4 — Check Load Balancer Health

Navigate to: **EC2 → Target Groups → Targets**

- Which instance is marked unhealthy?
- What is the health check status message?

---

### Step 5 — Investigate the Instance

SSH into the failing instance and check the Apache service:

```bash
sudo systemctl status httpd
```

- Is Apache running?
- If not, what error message is shown?

---

### Step 6 — Check Running Processes

```bash
top
# or
ps aux | grep stress
```

- Is the CPU stress process still running?
- Which process is consuming the most CPU?

---

### Step 7 — Fix the Problem

Restart Apache and confirm it is running:

```bash
sudo systemctl start httpd
sudo systemctl status httpd
```

---

### Step 8 — Verify Recovery

After restarting Apache, check the following:

- Load Balancer target health (both instances healthy?)
- CloudWatch alarm state (returned to OK?)
- Application availability via the Load Balancer DNS

---

### Step 9 — Scaling Exercise

Modify the instance type in your Terraform configuration:

```hcl
# Change from
instance_type = "t2.micro"

# To
instance_type = "t3.medium"
```

Then apply:

```bash
terraform apply
```

- How does the larger instance type affect CPU utilisation under the same load?
- In what situations would vertical scaling be the right choice versus horizontal scaling?

---

### Learning Reflection

After completing the lab, write a short summary covering:

1. What caused the initial failure on the unhealthy instance?
2. Why did the Load Balancer keep the application available despite the failure?
3. Which monitoring tools were most useful for diagnosing the issue?
4. What steps restored the system, and in what order did you perform them?

---

## Cleanup

To avoid ongoing AWS charges, destroy the infrastructure when finished:

```bash
terraform destroy
```

---

## License

MIT
