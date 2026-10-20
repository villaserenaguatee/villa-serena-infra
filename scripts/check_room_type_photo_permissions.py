"""Comprueba con IAM Simulator los permisos efectivos del rol del API, sin escribir objetos."""

import json
from pathlib import Path
import subprocess


def read_json(*command):
    return json.loads(subprocess.check_output(command, text=True))


def main():
    root = Path(__file__).resolve().parents[1]
    outputs = read_json("terraform", f"-chdir={root / 'aws/storage'}", "output", "-json")
    public = f"arn:aws:s3:::{outputs['public_bucket']['value']}"
    private = f"arn:aws:s3:::{outputs['private_bucket']['value']}"
    photo = f"{public}/{outputs['room_type_photos_prefix']['value']}permission-probe.jpg"
    role = read_json(
        "aws", "iam", "get-role", "--role-name", outputs["ec2_role_name"]["value"],
        "--query", "Role.Arn", "--output", "json",
    )
    cases = [
        ("s3:GetObject", photo, True),
        ("s3:PutObject", photo, True),
        ("s3:DeleteObject", photo, False),
        ("s3:PutObjectAcl", photo, False),
        ("s3:ListBucket", public, False),
        ("s3:GetObject", f"{public}/images/catalogo-aprobado/probe.jpg", False),
        ("s3:PutObject", f"{public}/images/catalogo-aprobado/probe.jpg", False),
        ("s3:PutObject", f"{public}/hotel/probe.jpg", False),
        ("s3:PutObject", f"{public}/tipos-otro/probe.jpg", False),
        ("s3:PutObject", "arn:aws:s3:::villa-serena-unrelated/tipos/probe.jpg", False),
        ("s3:GetObject", f"{private}/incidencias/probe.jpg", True),
        ("s3:PutObject", f"{private}/incidencias/probe.jpg", True),
        ("s3:DeleteObject", f"{private}/incidencias/probe.jpg", False),
        ("s3:DeleteObject", f"{private}/_checks/probe.jpg", True),
    ]
    for action, resource, allowed in cases:
        result = read_json(
            "aws", "iam", "simulate-principal-policy", "--policy-source-arn", role,
            "--action-names", action, "--resource-arns", resource, "--output", "json",
        )
        decision = result["EvaluationResults"][0]["EvalDecision"]
        if (decision == "allowed") != allowed:
            raise AssertionError(f"{action} {resource}: {decision}; allowed esperado={allowed}")
    print(f"OK: {len(cases)} comprobaciones IAM; no se escribieron objetos.")


if __name__ == "__main__":
    main()
