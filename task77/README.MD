

## 🚀 Steps to Run


Ensure Ansible is installed

ansible --version

Install the required collection
ansible-galaxy collection install community.general



Validate the playbook:
ansible-playbook odf-ansible-script.yaml --check

Execute the Playbook
ansible-playbook odf-ansible-script.yaml
