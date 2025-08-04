# Namecheap DNS Setup Guide

This guide walks through setting up DNS delegation from Namecheap to AWS Route53 for the TRM project.

## Prerequisites

1. Access to Namecheap account with `geoffmiller.cloud` domain
2. AWS account with Route53 access
3. Terraform deployed account-bootstrap infrastructure

## Step 1: Get Route53 Nameservers

After running the account-bootstrap Terraform:

```bash
cd iac/deploy/account-bootstrap
terraform output main_hosted_zone_nameservers
```

This will output 4 nameservers like:
```
[
  "ns-1234.awsdns-12.org",
  "ns-5678.awsdns-34.co.uk",
  "ns-910.awsdns-56.net",
  "ns-1112.awsdns-78.com"
]
```

## Step 2: Configure Namecheap

### Access DNS Management

1. Log in to [Namecheap](https://www.namecheap.com)
2. Go to **Domain List**
3. Find `geoffmiller.cloud` and click **Manage**
4. Click on **Advanced DNS** tab

### Add NS Records

For each nameserver from Step 1, add an NS record:

**Record 1:**
- Host: `trm`
- Type: `NS Record`
- Value: `ns-1234.awsdns-12.org`
- TTL: `30 min`

**Record 2:**
- Host: `trm`
- Type: `NS Record`
- Value: `ns-5678.awsdns-34.co.uk`
- TTL: `30 min`

**Record 3:**
- Host: `trm`
- Type: `NS Record`
- Value: `ns-910.awsdns-56.net`
- TTL: `30 min`

**Record 4:**
- Host: `trm`
- Type: `NS Record`
- Value: `ns-1112.awsdns-78.com`
- TTL: `30 min`

### Important Notes

- Use only the subdomain name `trm` in the Host field (not `trm.geoffmiller.cloud`)
- Add each nameserver as a separate NS record
- The trailing dot (.) is NOT needed in Namecheap
- TTL of 30 minutes allows for easier changes during setup

## Step 3: Save Changes

Click **Save All Changes** (green checkmark button)

## Step 4: Verify Setup

Wait 15-30 minutes for initial propagation, then verify:

```bash
# Check nameservers are set correctly
dig NS trm.geoffmiller.cloud

# Should return the 4 AWS nameservers you configured
```

Alternative verification:
```bash
# Query Google's DNS
dig NS trm.geoffmiller.cloud @8.8.8.8

# Query Cloudflare's DNS
dig NS trm.geoffmiller.cloud @1.1.1.1
```

## Step 5: Test Route53 Control

Once nameservers are confirmed, test by adding a record in Route53:

```bash
# In Route53, add a test TXT record
# Name: _test.trm.geoffmiller.cloud
# Value: "route53-control-verified"

# Then verify it resolves
dig TXT _test.trm.geoffmiller.cloud
```

## Troubleshooting

### NS Records Not Showing

If `dig NS` doesn't show your nameservers after 30 minutes:

1. **Check Namecheap Setup**
   - Verify Host field only contains `trm` (no domain)
   - Ensure all 4 NS records are saved
   - Check for any error messages in Namecheap

2. **Clear DNS Cache**
   ```bash
   # macOS
   sudo dscacheutil -flushcache
   
   # Linux
   sudo systemd-resolve --flush-caches
   ```

3. **Use DNS Propagation Checker**
   - Visit [whatsmydns.net](https://www.whatsmydns.net)
   - Enter `trm.geoffmiller.cloud`
   - Select NS record type
   - Check global propagation status

### Certificate Validation Issues

If SSL certificate validation fails:

1. Ensure NS records are fully propagated (24-48 hours)
2. Verify CAA records in Route53 allow AWS certificates
3. Check no conflicting CAA records exist in Namecheap

### Reverting Changes

To undo the delegation:

1. Delete the NS records in Namecheap
2. DNS will revert to Namecheap control
3. Any records in Route53 will stop resolving

## Best Practices

1. **Document Nameservers**: Keep a record of the AWS nameservers
2. **Monitor Propagation**: Use multiple DNS checkers during setup
3. **Test Incrementally**: Verify delegation before adding production records
4. **Backup Configuration**: Screenshot Namecheap DNS before changes

## Support Resources

- [Namecheap DNS Documentation](https://www.namecheap.com/support/knowledgebase/article.aspx/319/2237/how-to-manage-dns-records)
- [AWS Route53 Documentation](https://docs.aws.amazon.com/route53/)
- [DNS Propagation Checker](https://www.whatsmydns.net)

## Next Steps

After successful delegation:

1. Deploy application infrastructure
2. Configure CloudFront distributions
3. Set up SSL certificates via ACM
4. Add application-specific DNS records