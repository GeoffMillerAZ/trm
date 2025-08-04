# Deployment Write‑Up

## 1. Security Hardening

### Network and traffic protection

* Web Application Firewall (planned) - inspects inbound HTTP traffic and blocks known attack signatures before they hit the app
* Rate limiting - throttles excessive requests to prevent brute force and resource exhaustion
* AWS Shield Advanced - absorbs volumetric DDoS traffic so the service stays reachable
* Block known bad actor IPs and ASN ranges on ingress - shrinks the exposed surface by denying traffic from threat feeds
* HTTPS everywhere using public or private ACM certificates - encrypts traffic in transit and prevents tampering
* Data loss prevention controls on egress - scans outbound traffic to stop accidental or malicious leakage of sensitive data
* Restricted egress rules for applications and workloads - default deny outbound paths so workloads cannot call unknown endpoints
* Istio Ambient Mesh

  * mTLS enforced on every hop for east west traffic
  * Optional waypoint proxies add L7 routing, policy, and telemetry without sidecars
* Isolation with AWS VPCs - separates network boundaries and limits blast radius

### Vulnerability and code analysis

* AWS Inspector for software compositional analysis

  * Detects known CVEs in dependencies
  * Patch or follow remediation guidance
* CodeGuru for static code analysis (Java and Python focus)

  * Identifies code smells
  * Provides fix recommendations

### Identity, secrets, and keys

* Fine‑grained IAM roles and policies
* AWS Secrets Manager with automatic multi‑region replication and rotation
* SSM Parameter Store configuration replicated across regions (implemented)
* KMS multi‑Region keys replicated for encrypted data at rest (implemented)

### Policy as code and live resource compliance

* AWS Config rules and conformance packs - continuously evaluate running resources against baseline controls mapped to frameworks such as CSA Cloud Controls Matrix v4
* AWS Organizations Service Control Policies - enforce guardrails at the API layer and block destructive calls like DeleteDBInstance in production unless a break glass role is used
* OPA, CloudFormation Guard, or Terraform Sentinel checks in CI and CD - prevent non compliant changes from reaching production while allowing hundreds of safe deployments per day
* AI assisted reviews - run real time well architected and operations checks to surface context aware risks early

### Threat detection, logging, and reviews

* GuardDuty across CloudTrail, VPC Flow Logs, DNS, EKS runtime, Lambda, and RDS activity
* Centralized logging and metrics for fast detection and response
* Regular AWS Well Architected Reviews, security audits, and vulnerability assessments

---

## 2. High Availability and Disaster Recovery

* ECS services behind an internal and internet facing Application Load Balancer provide multi AZ availability within each region (implemented)
* No cross region active active yet; Route 53 serves a single primary region for now
* DynamoDB used in a single region (no global tables) with standard backups enabled
* Application layer caching implemented (in memory or local), but no shared cache tier yet
* KMS, Secrets Manager, Parameter Store, and backup vaults replicated to secondary regions for data protection
* Evaluate DynamoDB global tables to reduce latency and enable instant regional failover; worth adding once multi region traffic grows
* Add Route 53 health check geo or latency based records to shift traffic during a regional incident
* Introduce a managed cache tier such as ElastiCache or DAX to offload read pressure and speed up response times beyond the app process cache
* Protect control planes and state files (Terraform state, S3 buckets) from single region loss
* Host automation redundantly across regions for failure response
* Schedule DR failover drills and chaos engineering experiments
* Validate data layer suitability before expanding further active active patterns

---

## 3. Frequent Deployments (100+ per day)

* Current runtime is ECS; consider EKS if future Kubernetes workloads require richer pod level control
* Strengthen CI/CD caching to shrink build times
* Optimize container layers so frequently changed layers are small and last
* Blue green deployments with canary traffic shifting per cluster and per region
* Rules engine for data driven changes that should not trigger redeployments
* **Central CI/CD governance**

  * Provide reusable pipeline templates or shared GitHub Actions that embed security scanning, unit tests, and policy checks so every service inherits the same guardrails
  * Enforce schema compliance with a linter or JSON / YAML schema validator that fails the build if a team deviates from the approved workflow spec
  * Use CODEOWNERS on workflow directories so changes require review from the platform engineering or security team
  * Separation of concerns: developers own application code; a dedicated platform team owns the pipeline logic and security gates
  * Add approved security gateways (for example OPA based policy steps) that can require explicit sign off from a specialist when a sensitive resource is touched
* Enforce backward compatibility for data and API layers
* Follow strict semantic versioning and API contracts
* Pin package versions to avoid upstream breakage
* Bake in as many dependencies as practical to reduce external volatility

---

## 4. Scaling to Thousands of Customers per Minute

### Compute scaling

* EKS as primary runtime
* Auto‑scaling

  * Karpenter for vertical and horizontal scaling on CPU and memory
  * KEDA for event driven horizontal scaling on custom metrics
  * Tune head‑room for burst traffic
* Separate node groups by workload type (CPU, memory, network, GPU, noisy neighbor isolation)

### Automated policy and change validation

* Policy as code with automatic change plan analysis - CI gates every deployment against guardrails so dangerous actions are blocked without manual review
* AI assisted reviews - real time well architected, operations, and code reviews augment human oversight while keeping lead time low

### Data tier scaling

* Read replicas and multi AZ placement for relational engines - scale read throughput and add fault tolerance
* DynamoDB adaptive capacity and partition awareness - maintain single digit millisecond latency under heavy load
* Asynchronous processing with SQS and EventBridge - decouple heavyweight tasks from user flows so spikes do not back up the main path

### Caching and routing

* Application level caching in place
* AWS Global Accelerator, Route 53 latency routing, and CloudFront edge caching

### Resilience testing

* Controlled chaos experiments for latency, dependency loss, and replication delays
* Split into additional microservices as complexity grows

---

## 5. Monitoring and Incident Response

* PagerDuty for on‑call management

  * Primary paged for critical events
  * Secondary if primary does not acknowledge in five minutes
  * Leadership escalation if secondary does not acknowledge in five minutes
* Grafana or Datadog for real‑time dashboards
* AWS SSM Automation for runbooks and remediation
* All fixes flow through IaC to keep source of truth consistent
* Blameless post‑mortems with actionable follow‑ups
* Public service health page

  * CloudFront or Lambda returns a static status page when the service is down
  * Prevents timeouts and lowers support load
