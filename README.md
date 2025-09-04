# Bootstrap a system
## First thing, edit the bootstrap file and add the IP of the target
### NOTE: This will allow bootstrapping without the remote user having sudoers NOPASSWD setup
ansible-playbook -i bootstrap playbooks/bootstrap.yml --ask-become-pass --ask-pass

# System setups will read the hosts from the hosts file in the Ansible directory due to the ansible.cfg in the current directory
## Setup a system as the baseline for all systems
ansible-playbook playbooks/baseline.yml

## Setup a system as the baseline for one system
ansible-playbook playbooks/baseline.yml -l buntu04 --ask-become-pass
