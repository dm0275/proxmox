#!/usr/bin/env python3

import argparse
import shlex
import subprocess
import sys
from pathlib import Path


def resolve_instance_id(args: argparse.Namespace) -> int:
    if args.mode == "destroy" and args.instance_id is None:
        sys.stderr.write(
            "--instance-id is required for destroy; auto-discovery is not supported.\n"
        )
        raise SystemExit(1)

    if args.instance_id is not None:
        return args.instance_id

    proxmox_cmd = [
        sys.executable,
        "scripts/proxmox.py",
        "next-instance-id",
        "--proxmox-user",
        args.proxmox_user,
        "--proxmox-instance",
        args.proxmox_instance,
        "--instance-id-min",
        str(args.instance_id_min),
        "--template-id-min",
        str(args.template_id_min),
        "--template-id-max",
        str(args.template_id_max),
    ]

    try:
        result = subprocess.run(
            proxmox_cmd,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        if exc.stderr:
            sys.stderr.write(exc.stderr)
        return_code = exc.returncode or 1
        raise SystemExit(return_code) from exc

    id_lines = result.stdout.strip().splitlines()
    if not id_lines:
        sys.stderr.write("Failed to resolve next instance ID from proxmox.py\n")
        raise SystemExit(1)

    try:
        return int(id_lines[-1])
    except ValueError as exc:
        sys.stderr.write(f"Invalid instance ID from proxmox.py: {id_lines[-1]}\n")
        raise SystemExit(1) from exc


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="scripts/terraform.py",
        description="Run Terraform lifecycle commands for Proxmox VMs",
    )
    parser.add_argument("mode", choices=["plan", "provision", "destroy", "clear-state"])
    parser.add_argument("--terraform-dir", default="./terraform")
    parser.add_argument("--ubuntu-version", default="26.04")
    parser.add_argument("--template-name", default="")
    parser.add_argument("--instance-id", type=int, default=None)
    parser.add_argument("--instance-id-min", type=int, default=100)
    parser.add_argument("--template-id-min", type=int, default=900)
    parser.add_argument("--template-id-max", type=int, default=999)
    parser.add_argument("--instance-name", default="ubuntu-instance-03")
    parser.add_argument("--script-revision", type=int, default=1)
    parser.add_argument("--proxmox-user", default="root")
    parser.add_argument("--proxmox-instance", default="proxmox.lan")
    parser.add_argument("--terraform-extra-args", default="")
    args = parser.parse_args()

    terraform_dir = Path(args.terraform_dir)

    if args.mode == "clear-state":
        for pattern in ("*.tfstate", "*.tfstate.backup"):
            for file_path in terraform_dir.glob(pattern):
                file_path.unlink(missing_ok=True)
        print("Cleared Terraform state files")
        return 0

    template_name = args.template_name or f"ubuntu-{args.ubuntu_version}-template"
    instance_id = resolve_instance_id(args)
    print(f"Using instance_id={instance_id}")

    mode_map = {
        "plan": ["terraform", "plan"],
        "provision": ["terraform", "apply", "-auto-approve"],
        "destroy": ["terraform", "destroy"],
    }

    cmd = [
        *mode_map[args.mode],
        f"--var=ubuntu_version={args.ubuntu_version}",
        f"--var=template_name={template_name}",
        f"--var=instance_id={instance_id}",
        f"--var=instance_name={args.instance_name}",
        f"--var=script_revision={args.script_revision}",
    ]

    if args.terraform_extra_args.strip():
        cmd.extend(shlex.split(args.terraform_extra_args))

    try:
        subprocess.run(cmd, check=True, cwd=terraform_dir)
    except subprocess.CalledProcessError as exc:
        return exc.returncode or 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
