# 🎯 Scenario-Based Interview Questions - Secure AKS Public Exposure

## Table of Contents
1. [🚨 Incident Response Scenarios](#incident-response-scenarios)
2. [🔒 Security Breach Scenarios](#security-breach-scenarios)
3. [📈 Performance & Scaling Scenarios](#performance--scaling-scenarios)
4. [🌐 Network & Connectivity Scenarios](#network--connectivity-scenarios)
5. [🔐 SSL/TLS Certificate Scenarios](#ssltls-certificate-scenarios)
6. [☁️ Cloud Infrastructure Scenarios](#cloud-infrastructure-scenarios)
7. [🛠️ Troubleshooting Scenarios](#troubleshooting-scenarios)
8. [💰 Cost Optimization Scenarios](#cost-optimization-scenarios)
9. [🔄 Deployment & Updates Scenarios](#deployment--updates-scenarios)
10. [📊 Monitoring & Alerting Scenarios](#monitoring--alerting-scenarios)

---

## 🚨 Incident Response Scenarios

### Scenario 1: Application Suddenly Becomes Inaccessible
**Situation:** "Your production web application was working fine, but users are now reporting they can't access it. The domain returns a 503 Service Unavailable error. How do you troubleshoot and resolve this?"

**Expected Answer:**
```bash
# Step 1: Check ingress controller status
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=50

# Step 2: Verify LoadBalancer service
kubectl get svc -n ingress-nginx ingress-nginx-controller
kubectl describe svc -n ingress-nginx ingress-nginx-controller

# Step 3: Check application pods
kubectl get pods -n production -l app=secure-web-app
kubectl describe pods -n production -l app=secure-web-app

# Step 4: Verify ingress resource
kubectl get ingress -n production
kubectl describe ingress secure-web-app-ingress -n production

# Step 5: Test internal connectivity
kubectl port-forward -n production svc/secure-web-app-service 8080:80
curl http://localhost:8080/health

# Step 6: Check network policies
kubectl get networkpolicy -n production
kubectl describe networkpolicy allow-ingress-to-web-app -n production
```

**Follow-up:** "What if the pods are running but still returning 503?"
- Check readiness probes configuration
- Verify service endpoints: `kubectl get endpoints -n production`
- Check application health endpoints
- Review resource limits and constraints

### Scenario 2: DDoS Attack in Progress
**Situation:** "Your monitoring alerts show an unusual spike in traffic (10x normal), response times are degrading, and some legitimate users can't access the application. You suspect a DDoS attack. What's your response plan?"

**Expected Answer:**
1. **Immediate Response:**
```bash
# Check current traffic patterns
kubectl top pods -n production
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep -E "(429|503)"

# Review rate limiting effectiveness
kubectl describe configmap -n ingress-nginx ingress-nginx-controller
```

2. **Scaling Response:**
```bash
# Emergency scaling
kubectl scale deployment secure-web-app --replicas=10 -n production

# Check HPA status
kubectl get hpa -n production
kubectl describe hpa secure-web-app-hpa -n production
```

3. **Azure WAF Configuration:**
```bash
# Enable more restrictive WAF rules
az network application-gateway waf-config set \
  --gateway-name myAppGateway \
  --resource-group myResourceGroup \
  --enabled true \
  --firewall-mode Prevention \
  --rule-set-version 3.2
```

4. **Long-term Mitigation:**
- Implement geographic IP blocking
- Add more sophisticated rate limiting
- Enable Azure Front Door for global load balancing
- Configure custom WAF rules for attack patterns

### Scenario 3: SSL Certificate Expired
**Situation:** "Users are getting SSL certificate warnings, and your application is showing as 'Not Secure' in browsers. The Let's Encrypt certificate seems to have expired. How do you handle this?"

**Expected Answer:**
```bash
# Step 1: Check certificate status
kubectl get certificate -n production
kubectl describe certificate secure-web-app-tls -n production

# Step 2: Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
kubectl get certificaterequests -n production
kubectl describe certificaterequest -n production

# Step 3: Force certificate renewal
kubectl delete secret secure-web-app-tls-secret -n production
kubectl annotate certificate secure-web-app-tls cert-manager.io/issue-temporary-certificate="true" -n production

# Step 4: Check Let's Encrypt rate limits
# Verify DNS is resolving correctly
nslookup myapp.yourdomain.com

# Step 5: Manual certificate request if needed
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: secure-web-app-tls-manual
  namespace: production
spec:
  secretName: secure-web-app-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - myapp.yourdomain.com
EOF
```

**Prevention Strategy:**
- Set up monitoring for certificate expiration (30 days before)
- Configure backup certificate issuers
- Implement automated alerts for cert-manager failures

---

## 🔒 Security Breach Scenarios

### Scenario 4: Suspicious Network Traffic Detected
**Situation:** "Your network monitoring has detected unusual outbound traffic from your application pods to unknown external IPs on ports 443 and 80. How do you investigate and respond?"

**Expected Answer:**
```bash
# Step 1: Immediate containment
kubectl get pods -n production -o wide
kubectl logs -n production -l app=secure-web-app --since=1h

# Step 2: Check network policies
kubectl get networkpolicy -n production
kubectl describe networkpolicy allow-web-app-external-apis -n production

# Step 3: Analyze traffic patterns
# Enable network policy logging (if available)
kubectl annotate networkpolicy allow-web-app-external-apis -n production \
  networkpolicy.kubernetes.io/enable-logging=true

# Step 4: Isolate affected pods
kubectl patch deployment secure-web-app -n production -p \
'{"spec":{"template":{"metadata":{"labels":{"quarantine":"true"}}}}}'

# Create isolation network policy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: quarantine-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      quarantine: "true"
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF
```

**Investigation Steps:**
1. Check container images for vulnerabilities
2. Review application dependencies
3. Analyze DNS queries and HTTP requests
4. Check for cryptocurrency mining indicators
5. Scan for backdoors or unauthorized access

### Scenario 5: Unauthorized Access Attempt
**Situation:** "Your WAF logs show multiple failed login attempts and scanning activities targeting your application. Some requests are trying SQL injection and XSS attacks. How do you strengthen security?"

**Expected Answer:**
1. **Immediate Response:**
```yaml
# Update WAF rules to be more restrictive
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
data:
  # Block suspicious user agents
  block-user-agents: "sqlmap,nikto,nessus,openvas,nmap"
  
  # Implement strict rate limiting
  rate-limit: "10"
  rate-limit-window: "1m"
  
  # Enable ModSecurity
  enable-modsecurity: "true"
  modsecurity-snippet: |
    SecRuleEngine On
    SecRequestBodyAccess On
    SecRule REQUEST_METHOD "^POST$" "id:1001,phase:1,t:none,block,msg:'POST requests blocked'"
```

2. **Enhanced Monitoring:**
```bash
# Set up security event monitoring
kubectl create configmap security-alerts -n monitoring --from-literal=config.yaml="
alerts:
  - name: suspicious_requests
    condition: rate(nginx_ingress_controller_requests{status=~'4..'}) > 10
  - name: sql_injection_attempts
    condition: increase(waf_blocked_requests_total[5m]) > 5
"
```

3. **Application Hardening:**
- Implement input validation
- Add CSRF tokens
- Enable content security policy (CSP)
- Regular security scanning

### Scenario 6: Container Escape Attempt
**Situation:** "Security tools have detected that one of your application pods is trying to access the host filesystem and Docker socket. How do you prevent and respond to potential container escape attempts?"

**Expected Answer:**
```yaml
# Enhanced Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

---
# Strict Security Context
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-web-app
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: web-app
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
          runAsNonRoot: true
          runAsUser: 10001
```

**Additional Security Measures:**
- Implement Falco for runtime security monitoring
- Use admission controllers (OPA Gatekeeper)
- Regular vulnerability scanning with Trivy
- Enable audit logging for all API server requests

---

## 📈 Performance & Scaling Scenarios

### Scenario 7: Traffic Spike During Black Friday
**Situation:** "It's Black Friday, and your e-commerce application is experiencing 20x normal traffic. Response times are increasing, and some users are getting timeouts. How do you handle this surge?"

**Expected Answer:**
```bash
# Step 1: Emergency scaling
kubectl scale deployment secure-web-app --replicas=50 -n production

# Step 2: Check current resource usage
kubectl top pods -n production
kubectl top nodes

# Step 3: Verify HPA is working
kubectl get hpa -n production
kubectl describe hpa secure-web-app-hpa -n production

# Step 4: Scale ingress controller
kubectl scale deployment ingress-nginx-controller --replicas=5 -n ingress-nginx

# Step 5: Optimize resource limits temporarily
kubectl patch deployment secure-web-app -n production -p \
'{"spec":{"template":{"spec":{"containers":[{"name":"web-app","resources":{"limits":{"cpu":"1","memory":"1Gi"},"requests":{"cpu":"500m","memory":"512Mi"}}}]}}}}'

# Step 6: Enable cluster autoscaler if not already
az aks nodepool update \
  --resource-group myResourceGroup \
  --cluster-name myAKSCluster \
  --name nodepool1 \
  --enable-cluster-autoscaler \
  --min-count 3 \
  --max-count 50
```

**Advanced Optimizations:**
```yaml
# Implement Pod Disruption Budget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: secure-web-app-pdb
  namespace: production
spec:
  minAvailable: 70%
  selector:
    matchLabels:
      app: secure-web-app
```

### Scenario 8: Memory Leak Detection
**Situation:** "Your monitoring shows that one of your application pods is consuming increasing amounts of memory over time, eventually getting OOMKilled. How do you diagnose and fix this?"

**Expected Answer:**
```bash
# Step 1: Check resource usage trends
kubectl top pods -n production --sort-by=memory
kubectl describe pod <pod-name> -n production | grep -A 5 "Last State"

# Step 2: Enable memory profiling
kubectl exec -it <pod-name> -n production -- /bin/sh
# Inside pod: enable application profiling endpoints

# Step 3: Implement Vertical Pod Autoscaler for analysis
kubectl apply -f - <<EOF
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: secure-web-app-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: secure-web-app
  updatePolicy:
    updateMode: "Off"  # Recommendation only
EOF

# Step 4: Set up memory alerts
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: memory-alerts
  namespace: monitoring
data:
  rules.yaml: |
    groups:
    - name: memory-alerts
      rules:
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes{pod=~"secure-web-app.*"} / container_spec_memory_limit_bytes > 0.8
        for: 5m
        annotations:
          summary: Pod {{ $labels.pod }} is using high memory
EOF
```

**Fix Strategies:**
- Implement memory limits and requests properly
- Add readiness probes to prevent traffic to unhealthy pods
- Use rolling updates with proper health checks
- Application-level memory management improvements

---

## 🌐 Network & Connectivity Scenarios

### Scenario 9: DNS Resolution Issues
**Situation:** "Users from certain geographic regions report they can't access your application, while others can access it fine. DNS queries are timing out for some users. How do you diagnose and fix this?"

**Expected Answer:**
```bash
# Step 1: Test DNS resolution from different locations
dig myapp.yourdomain.com @8.8.8.8
dig myapp.yourdomain.com @1.1.1.1
nslookup myapp.yourdomain.com

# Step 2: Check Azure DNS configuration
az network dns record-set a show \
  --resource-group myResourceGroup \
  --zone-name yourdomain.com \
  --name myapp

# Step 3: Verify LoadBalancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller -o wide
az network lb show --name kubernetes --resource-group MC_myResourceGroup_myAKSCluster_eastus

# Step 4: Test connectivity directly to IP
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: myapp.yourdomain.com" http://$EXTERNAL_IP/health

# Step 5: Implement Azure Front Door for global DNS
az network front-door create \
  --resource-group myResourceGroup \
  --name myapp-frontdoor \
  --protocol Http \
  --backend-address $EXTERNAL_IP
```

**Long-term Solutions:**
- Implement CDN with multiple points of presence
- Set up health checks for DNS failover
- Use Azure Traffic Manager for geographic routing
- Monitor DNS response times globally

### Scenario 10: Network Policy Blocking Legitimate Traffic
**Situation:** "After implementing network policies, your application can't connect to the external payment gateway API, causing checkout failures. How do you fix this while maintaining security?"

**Expected Answer:**
```bash
# Step 1: Identify the issue
kubectl logs -n production -l app=secure-web-app | grep -i "connection refused\|timeout"

# Step 2: Check current network policies
kubectl get networkpolicy -n production
kubectl describe networkpolicy allow-web-app-external-apis -n production

# Step 3: Test connectivity without network policies
kubectl delete networkpolicy allow-web-app-external-apis -n production
# Test if connection works
kubectl exec -it <pod-name> -n production -- curl -v https://api.paymentgateway.com

# Step 4: Create specific policy for payment gateway
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-payment-gateway
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: secure-web-app
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow payment gateway (by IP or FQDN)
  - to: []  # This allows all destinations
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
EOF
```

**Refined Policy (More Secure):**
```yaml
# If you know the payment gateway IPs
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-payment-gateway-specific
spec:
  podSelector:
    matchLabels:
      app: secure-web-app
  egress:
  - to:
    - ipBlock:
        cidr: 203.0.113.0/24  # Payment gateway IP range
    ports:
    - protocol: TCP
      port: 443
```

---

## 🔐 SSL/TLS Certificate Scenarios

### Scenario 11: Certificate Chain Issues
**Situation:** "Your SSL certificate is installed, but some browsers and mobile devices show certificate errors or warnings about an incomplete certificate chain. How do you fix this?"

**Expected Answer:**
```bash
# Step 1: Check certificate chain
kubectl get secret secure-web-app-tls-secret -n production -o yaml
echo "<certificate-content>" | openssl x509 -text -noout

# Step 2: Verify certificate chain online
# Use online SSL checker tools or:
openssl s_client -connect myapp.yourdomain.com:443 -showcerts

# Step 3: Check cert-manager configuration
kubectl describe certificate secure-web-app-tls -n production
kubectl logs -n cert-manager deployment/cert-manager | grep -i chain

# Step 4: Fix ClusterIssuer configuration
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod-fixed
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
          podTemplate:
            spec:
              nodeSelector:
                "kubernetes.io/os": linux
EOF

# Step 5: Force certificate re-issuance
kubectl delete certificate secure-web-app-tls -n production
kubectl apply -f examples/ssl-tls-setup.yaml
```

### Scenario 12: Multiple Domain SSL Certificate
**Situation:** "Your application needs to support multiple domains (myapp.com, myapp.net, www.myapp.com) with a single SSL certificate. How do you configure this with cert-manager?"

**Expected Answer:**
```yaml
# Multi-domain certificate configuration
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: multi-domain-tls
  namespace: production
spec:
  secretName: multi-domain-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - myapp.com
  - www.myapp.com
  - myapp.net
  - www.myapp.net
  - api.myapp.com

---
# Updated Ingress for multiple domains
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-domain-ingress
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.com
    - www.myapp.com
    - myapp.net
    - www.myapp.net
    secretName: multi-domain-tls-secret
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-web-app-service
            port:
              number: 80
  - host: www.myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-web-app-service
            port:
              number: 80
  # Repeat for other domains...
```

---

## ☁️ Cloud Infrastructure Scenarios

### Scenario 13: Azure Region Outage
**Situation:** "The Azure region hosting your AKS cluster is experiencing an outage. Your application is completely down. How do you implement disaster recovery and ensure business continuity?"

**Expected Answer:**
1. **Immediate Response:**
```bash
# Check Azure service health
az rest --method get \
  --uri "https://management.azure.com/subscriptions/{subscription-id}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2018-07-01"

# Failover to secondary region (if available)
kubectl config use-context aks-cluster-west-us2
kubectl get nodes
```

2. **Long-term DR Strategy:**
```yaml
# Multi-region deployment configuration
# Primary cluster in East US
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-config
data:
  primary-region: "eastus"
  backup-region: "westus2"
  failover-threshold: "5m"

---
# Azure Traffic Manager for DNS failover
resource "azurerm_traffic_manager_profile" "main" {
  name                = "myapp-traffic-manager"
  resource_group_name = azurerm_resource_group.main.name

  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "myapp"
    ttl          = 30
  }

  monitor_config {
    protocol = "HTTPS"
    port     = 443
    path     = "/health"
  }
}

resource "azurerm_traffic_manager_endpoint" "primary" {
  name                = "primary-eastus"
  resource_group_name = azurerm_resource_group.main.name
  profile_name       = azurerm_traffic_manager_profile.main.name
  type               = "externalEndpoints"
  target             = "myapp-eastus.yourdomain.com"
  priority           = 1
}

resource "azurerm_traffic_manager_endpoint" "secondary" {
  name                = "secondary-westus2"
  resource_group_name = azurerm_resource_group.main.name
  profile_name       = azurerm_traffic_manager_profile.main.name
  type               = "externalEndpoints"
  target             = "myapp-westus2.yourdomain.com"
  priority           = 2
}
```

3. **Automated Failover:**
```bash
# Create automated failover script
#!/bin/bash
PRIMARY_HEALTH_CHECK="https://myapp-eastus.yourdomain.com/health"
SECONDARY_CLUSTER="aks-cluster-westus2"

while true; do
  if ! curl -f -s $PRIMARY_HEALTH_CHECK > /dev/null; then
    echo "Primary cluster unhealthy, failing over..."
    kubectl config use-context $SECONDARY_CLUSTER
    kubectl scale deployment secure-web-app --replicas=10 -n production
    # Update DNS or Traffic Manager
  fi
  sleep 30
done
```

### Scenario 14: Cost Explosion Alert
**Situation:** "Your Azure bill has increased by 300% this month, and finance is asking for immediate cost reduction. The increase seems to be related to your AKS cluster. How do you quickly identify and reduce costs?"

**Expected Answer:**
```bash
# Step 1: Analyze resource usage
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu
kubectl top pods --all-namespaces --sort-by=memory

# Step 2: Check for resource waste
kubectl get pods --all-namespaces -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,CPU_REQ:.spec.containers[*].resources.requests.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory,CPU_LIM:.spec.containers[*].resources.limits.cpu,MEM_LIM:.spec.containers[*].resources.limits.memory

# Step 3: Identify oversized node pools
az aks nodepool list --cluster-name myAKSCluster --resource-group myResourceGroup

# Step 4: Implement immediate cost reductions
# Scale down non-production environments
kubectl scale deployment --all --replicas=0 -n development
kubectl scale deployment --all --replicas=0 -n staging

# Right-size production workloads
kubectl patch deployment secure-web-app -n production -p \
'{"spec":{"replicas":3,"template":{"spec":{"containers":[{"name":"web-app","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"250m","memory":"256Mi"}}}]}}}}'

# Step 5: Enable spot instances for dev workloads
az aks nodepool add \
  --resource-group myResourceGroup \
  --cluster-name myAKSCluster \
  --name spotpool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 3 \
  --node-vm-size Standard_DS2_v2
```

**Cost Optimization Strategies:**
```yaml
# Implement resource quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "4"

---
# Limit ranges for pods
apiVersion: v1
kind: LimitRange
metadata:
  name: pod-limit-range
  namespace: production
spec:
  limits:
  - default:
      cpu: 100m
      memory: 128Mi
    defaultRequest:
      cpu: 50m
      memory: 64Mi
    type: Container
```

---

## 🛠️ Troubleshooting Scenarios

### Scenario 15: Ingress Controller Not Getting IP
**Situation:** "You've deployed the NGINX ingress controller, but the LoadBalancer service is stuck in 'Pending' state and never gets an external IP. How do you troubleshoot this?"

**Expected Answer:**
```bash
# Step 1: Check service status
kubectl get svc -n ingress-nginx ingress-nginx-controller -o yaml
kubectl describe svc -n ingress-nginx ingress-nginx-controller

# Step 2: Check events
kubectl get events -n ingress-nginx --sort-by=.lastTimestamp

# Step 3: Verify Azure LoadBalancer quota
az network lb list --resource-group MC_myResourceGroup_myAKSCluster_eastus
az vm list-usage --location eastus | grep -i "load balancer"

# Step 4: Check service principal permissions
az aks show --resource-group myResourceGroup --name myAKSCluster --query servicePrincipalProfile
az role assignment list --assignee <service-principal-id> --resource-group MC_myResourceGroup_myAKSCluster_eastus

# Step 5: Check subnet availability
az network vnet subnet show \
  --resource-group MC_myResourceGroup_myAKSCluster_eastus \
  --vnet-name aks-vnet-12345678 \
  --name aks-subnet

# Step 6: Force recreation with specific annotations
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p \
'{"metadata":{"annotations":{"service.beta.kubernetes.io/azure-load-balancer-internal":"false","service.beta.kubernetes.io/azure-load-balancer-resource-group":"MC_myResourceGroup_myAKSCluster_eastus"}}}'
```

**Common Fixes:**
- Verify AKS service principal has Network Contributor role
- Check Azure resource limits and quotas
- Ensure correct subnet configuration
- Verify Azure policy restrictions

### Scenario 16: Pod Stuck in CrashLoopBackOff
**Situation:** "Your application pods are stuck in CrashLoopBackOff state after a deployment update. The pods keep restarting every few seconds. How do you diagnose and fix this?"

**Expected Answer:**
```bash
# Step 1: Check pod status and events
kubectl get pods -n production -l app=secure-web-app
kubectl describe pod <pod-name> -n production

# Step 2: Check container logs
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production --previous

# Step 3: Check resource constraints
kubectl top pod <pod-name> -n production
kubectl describe node <node-name>

# Step 4: Test configuration
kubectl get configmap -n production
kubectl get secret -n production

# Step 5: Check health probes
kubectl get deployment secure-web-app -n production -o yaml | grep -A 10 -B 5 probe

# Step 6: Rollback if necessary
kubectl rollout history deployment/secure-web-app -n production
kubectl rollout undo deployment/secure-web-app -n production --to-revision=2

# Step 7: Debug with modified deployment
kubectl run debug-pod --image=secure-web-app:latest -n production --rm -it --restart=Never -- /bin/sh
```

**Common Causes and Solutions:**
- **Resource limits too low**: Increase CPU/memory limits
- **Failing health probes**: Adjust probe timing or endpoints
- **Configuration errors**: Verify ConfigMaps and Secrets
- **Image issues**: Check image availability and tags
- **Permission problems**: Verify security contexts and RBAC

---

## 📊 Monitoring & Alerting Scenarios

### Scenario 17: False Positive Alerts Overwhelming Team
**Situation:** "Your monitoring system is generating too many false positive alerts (CPU spikes during normal traffic, memory alerts during startup). The team is starting to ignore alerts. How do you optimize alerting?"

**Expected Answer:**
```yaml
# Refined alerting rules with proper thresholds
apiVersion: v1
kind: ConfigMap
metadata:
  name: optimized-alerts
  namespace: monitoring
data:
  alert-rules.yaml: |
    groups:
    - name: application-alerts
      rules:
      # CPU alert with sustained high usage
      - alert: HighCPUUsage
        expr: avg_over_time(rate(container_cpu_usage_seconds_total{pod=~"secure-web-app.*"}[5m])[15m:1m]) > 0.8
        for: 10m  # Must be high for 10 minutes
        labels:
          severity: warning
        annotations:
          summary: "Sustained high CPU usage on {{ $labels.pod }}"
          
      # Memory alert with growth trend
      - alert: MemoryGrowthTrend
        expr: predict_linear(container_memory_usage_bytes{pod=~"secure-web-app.*"}[1h], 4*3600) > 1073741824  # 1GB
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Memory usage trending towards limits on {{ $labels.pod }}"
          
      # Error rate alert with percentage threshold
      - alert: HighErrorRate
        expr: rate(nginx_ingress_controller_requests{status=~"5.."}[5m]) / rate(nginx_ingress_controller_requests[5m]) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Error rate above 5% for 2 minutes"
```

**Alert Optimization Strategies:**
1. **Use percentile-based alerts instead of absolute values**
2. **Implement alert grouping and routing**
3. **Add business context to technical alerts**
4. **Use composite alerts for complex scenarios**
5. **Implement alert fatigue detection**

### Scenario 18: Missing Critical Security Event
**Situation:** "A security audit revealed that a critical security event (privilege escalation attempt) occurred but wasn't detected by your monitoring system. How do you enhance security monitoring?"

**Expected Answer:**
```yaml
# Enhanced security monitoring with Falco
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-security-rules
  namespace: security
data:
  security_rules.yaml: |
    - rule: Privilege Escalation Attempt
      desc: Detect privilege escalation attempts
      condition: >
        spawned_process and proc.name in (sudo, su, setuid_binaries) and
        not user.name in (allowed_users)
      output: >
        Privilege escalation attempt detected (user=%user.name proc=%proc.name
        parent=%proc.pname cmdline=%proc.cmdline container=%container.name)
      priority: CRITICAL

    - rule: Sensitive File Access
      desc: Detect access to sensitive files
      condition: >
        open_read and fd.name in (/etc/passwd, /etc/shadow, /root/.ssh/id_rsa)
      output: >
        Sensitive file accessed (file=%fd.name proc=%proc.name container=%container.name)
      priority: WARNING

    - rule: Network Connection to Suspicious IP
      desc: Detect connections to known bad IPs
      condition: >
        outbound and fd.sip in (suspicious_ip_list)
      output: >
        Connection to suspicious IP (ip=%fd.sip proc=%proc.name container=%container.name)
      priority: CRITICAL

---
# Audit logging for API server
apiVersion: v1
kind: ConfigMap
metadata:
  name: audit-policy
  namespace: kube-system
data:
  audit-policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    - level: Metadata
      namespaces: ["production", "security"]
      verbs: ["create", "update", "delete"]
    - level: Request
      resources:
      - group: "rbac.authorization.k8s.io"
        resources: ["clusterroles", "clusterrolebindings"]
    - level: RequestResponse
      resources:
      - group: ""
        resources: ["secrets"]
```

**Security Monitoring Implementation:**
1. **Deploy Falco for runtime security**
2. **Enable Kubernetes audit logging**
3. **Implement network traffic analysis**
4. **Set up SIEM integration**
5. **Create security dashboards and alerts**

---

## 💰 Cost Optimization Scenarios

### Scenario 19: Unused Resources Discovery
**Situation:** "Management wants to optimize cloud costs. You need to identify and eliminate unused or underutilized resources in your AKS environment. How do you approach this systematically?"

**Expected Answer:**
```bash
# Step 1: Resource utilization analysis
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu
kubectl top pods --all-namespaces --sort-by=memory

# Step 2: Identify idle pods (low CPU/memory usage)
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CPU:.status.containerStatuses[0].resources.requests.cpu,MEMORY:.status.containerStatuses[0].resources.requests.memory

# Step 3: Find unused PVCs
kubectl get pvc --all-namespaces
kubectl get pods --all-namespaces -o yaml | grep -A 5 -B 5 persistentVolumeClaim

# Step 4: Analyze node utilization
kubectl describe nodes | grep -A 5 "Allocated resources"

# Step 5: Check for zombie deployments
kubectl get deployments --all-namespaces --show-labels
kubectl get deployments --all-namespaces -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,REPLICAS:.spec.replicas,AVAILABLE:.status.availableReplicas

# Step 6: Implement resource optimization
# Create VPA recommendations for all deployments
kubectl apply -f - <<EOF
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: vpa-recommender
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: secure-web-app
  updatePolicy:
    updateMode: "Off"  # Recommendations only
  resourcePolicy:
    containerPolicies:
    - containerName: web-app
      maxAllowed:
        cpu: 1
        memory: 2Gi
      minAllowed:
        cpu: 50m
        memory: 64Mi
EOF
```

**Automated Cost Optimization:**
```yaml
# Cost optimization CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cost-optimizer
  namespace: kube-system
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cost-optimizer
            image: cost-optimizer:latest
            command:
            - /bin/sh
            - -c
            - |
              # Scale down dev environments
              kubectl scale deployment --all --replicas=0 -n development
              
              # Clean up completed jobs older than 7 days
              kubectl delete jobs --field-selector status.successful=1 --all-namespaces
              
              # Remove unused PVCs
              kubectl get pvc --all-namespaces -o json | jq -r '.items[] | select(.status.phase == "Available") | "\(.metadata.namespace) \(.metadata.name)"' | while read ns pvc; do
                kubectl delete pvc $pvc -n $ns
              done
          restartPolicy: OnFailure
```

---

## 🔄 Deployment & Updates Scenarios

### Scenario 20: Zero-Downtime Update Failed
**Situation:** "You're performing a zero-downtime rolling update of your application, but some users are experiencing brief service interruptions. The update is taking much longer than expected. How do you ensure truly zero-downtime deployments?"

**Expected Answer:**
```yaml
# Optimized deployment strategy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-web-app
  namespace: production
spec:
  replicas: 6  # Higher replica count for smoother updates
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 50%      # Allow 3 extra pods during update
      maxUnavailable: 0  # Never reduce available pods
  template:
    spec:
      containers:
      - name: web-app
        image: myapp:v2.0.0
        
        # Optimized health probes
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5   # Quick initial check
          periodSeconds: 2         # Frequent checks during startup
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Graceful shutdown
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - "sleep 15; /app/graceful-shutdown.sh"
      
      terminationGracePeriodSeconds: 60

---
# Pod Disruption Budget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: secure-web-app-pdb
  namespace: production
spec:
  minAvailable: 80%  # Always keep 80% of pods available
  selector:
    matchLabels:
      app: secure-web-app
```

**Deployment Verification:**
```bash
# Monitor deployment progress
kubectl rollout status deployment/secure-web-app -n production --watch

# Check pod readiness during update
watch kubectl get pods -n production -l app=secure-web-app

# Monitor traffic during deployment
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f | grep -E "(200|404|500)"

# Automated rollback on failure
kubectl rollout undo deployment/secure-web-app -n production --to-revision=1
```

---

## 🎯 Advanced Scenario Questions

### Scenario 21: Multi-Cluster Service Mesh
**Situation:** "Your organization is expanding globally and needs to deploy applications across multiple AKS clusters in different regions. How do you implement secure communication between services across clusters?"

**Expected Answer:**
```yaml
# Istio multi-cluster configuration
apiVersion: v1
kind: Secret
metadata:
  name: cacerts
  namespace: istio-system
type: Opaque
data:
  root-cert.pem: <base64-encoded-root-cert>
  cert-chain.pem: <base64-encoded-cert-chain>
  ca-cert.pem: <base64-encoded-ca-cert>
  ca-key.pem: <base64-encoded-ca-key>

---
# Cross-cluster service discovery
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: remote-service
  namespace: production
spec:
  hosts:
  - secure-web-app.production.global
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  addresses:
  - 240.0.0.1  # VIP for remote service
  endpoints:
  - address: secure-web-app.eastus2.internal
  - address: secure-web-app.westeurope.internal
```

### Scenario 22: Compliance Audit Requirements
**Situation:** "Your application needs to pass SOC 2 Type II compliance audit. Auditors are asking for evidence of security controls, access logs, and data protection measures. How do you prepare your AKS environment for this audit?"

**Expected Answer:**
```yaml
# Comprehensive audit logging
apiVersion: v1
kind: ConfigMap
metadata:
  name: audit-policy
  namespace: kube-system
data:
  audit-policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    # Log all authentication and authorization events
    - level: RequestResponse
      namespaces: ["production", "security"]
      verbs: ["create", "update", "patch", "delete"]
      resources:
      - group: ""
        resources: ["secrets", "configmaps"]
      - group: "apps"
        resources: ["deployments", "replicasets"]
      - group: "rbac.authorization.k8s.io"
        resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    
    # Log access to sensitive resources
    - level: Metadata
      omitStages:
      - RequestReceived
      resources:
      - group: ""
        resources: ["secrets", "configmaps"]
      namespaces: ["production"]

---
# Data classification and protection
apiVersion: v1
kind: Secret
metadata:
  name: pii-database-credentials
  namespace: production
  labels:
    data-classification: "confidential"
    compliance: "soc2"
    retention: "7years"
type: Opaque
data:
  username: <encrypted-username>
  password: <encrypted-password>
```

**Compliance Checklist:**
- [ ] All access is logged and auditable
- [ ] Encryption in transit and at rest
- [ ] Regular security vulnerability scans
- [ ] Access control documentation (RBAC)
- [ ] Data backup and recovery procedures
- [ ] Incident response procedures
- [ ] Regular security training documentation

---

## 🚀 Rapid-Fire Troubleshooting Scenarios

### Scenario 23: "The Application Worked Yesterday"
**Q:** "The application was working fine yesterday, but today users can't access it. Where do you start?"
**A:** 
1. Check external dependencies (DNS, external APIs)
2. Verify certificate expiration
3. Check recent deployments/changes
4. Verify ingress and service status
5. Check node and pod health

### Scenario 24: "Only Some Users Can't Access"
**Q:** "Some users can access the application while others cannot. What could cause this?"
**A:**
1. Geographic DNS issues
2. CDN/cache problems
3. Load balancer health check failures
4. Network routing issues
5. Rate limiting affecting specific IPs

### Scenario 25: "Application is Slow After Deployment"
**Q:** "After the latest deployment, the application response time increased from 200ms to 2 seconds. How do you investigate?"
**A:**
1. Compare resource usage before/after deployment
2. Check database connection pooling
3. Verify external API response times
4. Check for memory leaks or CPU bottlenecks
5. Review application logs for errors or warnings

---

## 💡 Interview Tips for Scenario Questions

### How to Answer Scenario Questions:
1. **Stay Calm**: Take time to understand the scenario completely
2. **Ask Clarifying Questions**: Get more context if needed
3. **Follow a Systematic Approach**: 
   - Assess the situation
   - Gather information
   - Identify root cause
   - Implement solution
   - Verify fix
   - Document learnings
4. **Show Your Thought Process**: Explain why you're taking specific steps
5. **Discuss Prevention**: How would you prevent this in the future?
6. **Mention Monitoring**: How would you detect this earlier?

### Key Points to Demonstrate:
- **Systematic troubleshooting approach**
- **Understanding of Kubernetes networking and security**
- **Knowledge of cloud infrastructure**
- **Experience with production operations**
- **Proactive monitoring and alerting**
- **Security-first mindset**
- **Business impact awareness**

Remember: The goal is not just to solve the problem, but to demonstrate your expertise, thought process, and ability to handle complex production scenarios! 🚀