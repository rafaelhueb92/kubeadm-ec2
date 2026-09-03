ansible-playbook -i production.aws_ec2.yml site.yml
ansible-playbook -i production.aws_ec2.yml site.kube.init.yml --ask-become-pass
ansible-playbook -i production.aws_ec2.yml site.kube.join.yml --ask-become-pass
ansible-inventory -i production.aws_ec2.yml --graph