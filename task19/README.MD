

## 🚀 Steps to Run



step 1. Ensure Ansible is installed

ansible --version

step2. Install the required collection
ansible-galaxy collection install community.general



step3. Validate the playbook:
ansible-playbook acs_install_integration.yml --check

Execute the Playbook
ansible-playbook acs_install_integration.yml
