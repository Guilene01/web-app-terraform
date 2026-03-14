Terraform AWS Highly Available Web Application Lab
This project demonstrates how to design and troubleshoot a highly available web application infrastructure on AWS using Terraform.
The environment includes:
AWS VPC with public subnets across multiple Availability Zones
EC2 web servers running Apache
Application Load Balancer distributing traffic
CloudWatch monitoring and alerting

SNS email notifications

Automated incident simulation

The lab intentionally generates realistic infrastructure and application failures to allow students to practice troubleshooting production-like incidents.

Failure Scenarios

Two automated failures are triggered on one EC2 instance:

CPU Stress Event

High CPU utilization is generated using stress-ng

CloudWatch detects abnormal CPU usage

SNS sends alerts

Application Failure

Apache service is stopped automatically

Load Balancer marks the instance unhealthy

Traffic is routed to the healthy instance

Students must investigate monitoring tools and restore the system.

Technologies Used

AWS

Terraform

EC2

Application Load Balancer

CloudWatch

SNS

Linux (Amazon Linux 2023)

Apache HTTP Server

Skills Demonstrated

Infrastructure as Code

High Availability Architecture

Cloud Monitoring

Incident Response

Root Cause Analysis

Service Recovery

Vertical Scaling

3. Student Troubleshooting Worksheet

You can give this to students during the lab.

Troubleshooting Lab Worksheet
Objective

Investigate alerts and restore system health after simulated failures.

Step 1 — Observe the System

Open the application using the Load Balancer DNS.

Questions:

Are both servers responding?

Which server names appear in the page?

Step 2 — Monitor CPU Metrics

Go to:

CloudWatch → Metrics → EC2 → CPUUtilization

Questions:

Which instance shows high CPU?

What is the peak CPU percentage?

How long does the spike last?

Step 3 — Check CloudWatch Alarms

Go to:

CloudWatch → Alarms

Questions:

Which alarms triggered?

What metric caused the alarm?

Step 4 — Check Load Balancer Health

Navigate to:

EC2 → Target Groups → Targets

Questions:

Which instance is unhealthy?

What is the health check status?

Step 5 — Investigate the Instance

SSH into the failing instance.

Check Apache status:

sudo systemctl status httpd

Questions:

Is Apache running?

If not, what error message appears?

Step 6 — Check Running Processes
top

or

ps aux | grep stress

Questions:

Is the CPU stress process still running?

Which process is using the most CPU?

Step 7 — Fix the Problem

Restart Apache:

sudo systemctl start httpd

Verify:

sudo systemctl status httpd
Step 8 — Verify Recovery

After fixing the issue:

Check:

Load balancer target health

CloudWatch alarms

application availability

Questions:

Did the instance return to healthy?

Did the alarm state return to OK?

Step 9 — Scaling Exercise

Modify the instance size:

t2.micro → t3.medium

Run:

terraform apply

Questions:

How does instance size affect CPU utilization?

When should vertical scaling be used?

Learning Reflection

Students should explain:

What caused the initial failure?

Why did the load balancer keep the application online?

What monitoring tools helped detect the issue?

How was the system recovered?