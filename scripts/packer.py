#!/usr/bin/env python3

import argparse
import shlex
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="scripts/packer.py",
        description="Run Packer build/validate for Proxmox templates",
    )
    parser.add_argument("mode", choices=["build", "validate"])
    parser.add_argument("--packer-dir", default="./packer")
    parser.add_argument("--credentials-file", default="credentials.pkr.hcl")
    parser.add_argument("--ubuntu-version", default="26.04")
    parser.add_argument("--template-name", default="")
    parser.add_argument("--template-description", default="")
    parser.add_argument("--iso-name", default="")
    parser.add_argument("--iso-storage", default="local")
    parser.add_argument("--vm-id", type=int, default=None)
    parser.add_argument("--proxmox-user", default="root")
    parser.add_argument("--proxmox-instance", default="proxmox.lan")
    parser.add_argument("--template-id-min", type=int, default=900)
    parser.add_argument("--template-id-max", type=int, default=999)
    parser.add_argument("--packer-extra-args", default="")
    args = parser.parse_args()

    template_name = args.template_name or f"ubuntu-{args.ubuntu_version}-template"
    template_description = (
        args.template_description or f"Ubuntu {args.ubuntu_version} Image"
    )
    iso_name = args.iso_name or f"ubuntu-{args.ubuntu_version}-live-server-amd64.iso"

    vm_id = args.vm_id
    if vm_id is None:
        proxmox_cmd = [
            sys.executable,
            "scripts/proxmox.py",
            "next-template-id",
            "--proxmox-user",
            args.proxmox_user,
            "--proxmox-instance",
            args.proxmox_instance,
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
            return exc.returncode or 1

        vm_id_text = result.stdout.strip().splitlines()
        if not vm_id_text:
            sys.stderr.write("Failed to resolve next template ID from proxmox.py\n")
            return 1
        try:
            vm_id = int(vm_id_text[-1])
        except ValueError:
            sys.stderr.write(f"Invalid template ID from proxmox.py: {vm_id_text[-1]}\n")
            return 1

    print(f"Using Packer VM ID: {vm_id}")

    cmd = [
        "packer",
        args.mode,
        f"-var-file={args.credentials_file}",
        f"-var=ubuntu_version={args.ubuntu_version}",
        f"-var=vm_id={vm_id}",
        f"-var=vm_name={template_name}",
        f"-var=template_description={template_description}",
        f"-var=iso_file={args.iso_storage}:iso/{iso_name}",
        "ubuntu.pkr.hcl",
    ]

    if args.packer_extra_args.strip():
        cmd.extend(shlex.split(args.packer_extra_args))

    try:
        subprocess.run(cmd, check=True, cwd=Path(args.packer_dir))
    except subprocess.CalledProcessError as exc:
        return exc.returncode or 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
