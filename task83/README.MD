

## 🚀 Steps to Run

### 1. Save the Playbook



Ensure Ansible is installed

ansible --version

Install the required collection
ansible-galaxy collection install community.general



Validate the playbook:
ansible-playbook k8s_availability_report.yml --check

Execute the Playbook
ansible-playbook report-and-mail.yml


