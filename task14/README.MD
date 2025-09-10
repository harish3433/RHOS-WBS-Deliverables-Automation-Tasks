

## 🚀 Steps to Run

Step1. Ensure Ansible is installed

ansible --version

Install the required collection
ansible-galaxy collection install community.general

Step2. provide namespace where you want to configure istio.

Validate the playbook:
ansible-playbook istio.yml --check

Execute the Playbook
ansible-playbook istio.yml
