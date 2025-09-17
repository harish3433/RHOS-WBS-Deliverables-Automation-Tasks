from flask import Flask, request, jsonify

import subprocess

app = Flask(__name__)

# ---------------- API ENDPOINTS ---------------- #
@app.route("/api/project/create", methods=["POST"])
def create_project():
    data = request.get_json()
    project_name = data.get("project_name", "myproject")
    quota_cpu = data.get("quota_cpu", "2")
    quota_mem = data.get("quota_mem", "4Gi")
    rbac_kind = data.get("rbac_kind", "User")        # User or Group
    rbac_user = data.get("rbac_user", "developer")  # Username or Group name
    rbac_role = data.get("rbac_role", "edit")       # admin/edit/view

    cmd = [
        "ansible-playbook", "ocp_project_rbac.yaml",
        "-e", f"project_name={project_name}",
        "-e", f"quota_cpu={quota_cpu}",
        "-e", f"quota_mem={quota_mem}",
        "-e", f"rbac_kind={rbac_kind}",
        "-e", f"rbac_user={rbac_user}",
        "-e", f"rbac_role={rbac_role}"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    return jsonify({
        "status": "success" if result.returncode == 0 else "failed",
        "stdout": result.stdout,
        "stderr": result.stderr
    })

@app.route("/api/project/delete", methods=["POST"])
def delete_project():
    data = request.get_json()
    project_name = data.get("project_name", "myproject")

    cmd = [
        "ansible-playbook", "ocp_project_delete.yaml",
        "-e", f"project_name={project_name}"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    return jsonify({
        "status": "success" if result.returncode == 0 else "failed",
        "stdout": result.stdout,
        "stderr": result.stderr
    })

# ---------------- SIMPLE WEB UI ---------------- #
@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        action = request.form.get("action")
        project_name = request.form.get("project_name")
        quota_cpu = request.form.get("quota_cpu")
        quota_mem = request.form.get("quota_mem")
        rbac_kind = request.form.get("rbac_kind")
        rbac_user = request.form.get("rbac_user")
        rbac_role = request.form.get("rbac_role")

        if action == "create":
            cmd = [
                "ansible-playbook", "ocp_project_rbac.yaml",
                "-e", f"project_name={project_name}",
                "-e", f"quota_cpu={quota_cpu}",
                "-e", f"quota_mem={quota_mem}",
                "-e", f"rbac_kind={rbac_kind}",
                "-e", f"rbac_user={rbac_user}",
                "-e", f"rbac_role={rbac_role}"
            ]
        else:
            cmd = [
                "ansible-playbook", "ocp_project_delete.yaml",
                "-e", f"project_name={project_name}"
            ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        return f"<pre>{result.stdout}\n{result.stderr}</pre>"

    return '''
        <h2>OpenShift Project Self-Service</h2>
        <form method="post">
            <label>Project Name:</label> <input type="text" name="project_name" required><br><br>
            <label>CPU Quota:</label> <input type="text" name="quota_cpu" value="2"><br><br>
            <label>Memory Quota:</label> <input type="text" name="quota_mem" value="4Gi"><br><br>

            <h3>RBAC Configuration</h3>
            <label>RBAC Kind:</label>
            <select name="rbac_kind">
                <option value="User">User</option>
                <option value="Group">Group</option>
            </select><br><br>

            <label>RBAC User/Group Name:</label>
            <input type="text" name="rbac_user" value="developer"><br><br>

            <label>RBAC Role:</label>
            <select name="rbac_role">
                <option value="admin">admin</option>
                <option value="edit">edit</option>
                <option value="view">view</option>
            </select><br><br>

            <button type="submit" name="action" value="create">Create Project</button>
            <button type="submit" name="action" value="delete">Delete Project</button>
        </form>
    '''

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
