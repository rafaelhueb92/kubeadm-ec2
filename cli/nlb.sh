aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?Type=='network'].{Name:LoadBalancerName,Arn:LoadBalancerArn}" \
    --output table

aws elbv2 modify-load-balancer-attributes \
    --load-balancer-arn "arn:aws:elasticloadbalancing:region:account-id:loadbalancer/net/nlb-name/id" \
    --attributes Key=deletion_protection.enabled,Value=false
