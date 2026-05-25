#!/usr/bin/env python3

import argparse
import subprocess
import sys
from pathlib import Path


def get_next_template_id(
    proxmox_user: str,
    proxmox_instance: str,
    template_id_min: int,
    template_id_max: int,
) -> int:
    ssh_target = f"{proxmox_user}@{proxmox_instance}"
    cmd = ["ssh", ssh_target, "qm list"]
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)

    ids = []
    for line in result.stdout.splitlines()[1:]:
        parts = line.split()
        if not parts:
            continue
        try:
            vmid = int(parts[0])
        except ValueError:
            continue
        if template_id_min <= vmid <= template_id_max:
            ids.append(vmid)

    next_id = (max(ids) + 1) if ids else template_id_min
    if next_id > template_id_max:
        raise ValueError(
            f"No free template IDs available in range {template_id_min}-{template_id_max}."
        )
    return next_id


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="scripts/proxmox.py",
        description="Proxmox helper commands",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    next_id_parser = subparsers.add_parser(
        "next-template-id",
        help="Find the next free template ID in a range",
    )
    next_id_parser.add_argument("--proxmox-user", default="root")
    next_id_parser.add_argument("--proxmox-instance", default="proxmox.lan")
    next_id_parser.add_argument("--template-id-min", type=int, default=900)
    next_id_parser.add_argument("--template-id-max", type=int, default=999)
    next_id_parser.add_argument("--out-file", default="")

    args = parser.parse_args()

    if args.command == "next-template-id":
        try:
            next_id = get_next_template_id(
                args.proxmox_user,
                args.proxmox_instance,
                args.template_id_min,
                args.template_id_max,
            )
        except subprocess.CalledProcessError as exc:
            sys.stderr.write(exc.stderr or str(exc) + "\n")
            return exc.returncode or 1
        except ValueError as exc:
            sys.stderr.write(str(exc) + "\n")
            return 1

        if args.out_file:
            Path(args.out_file).write_text(f"{next_id}\n", encoding="utf-8")
        print(next_id)
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
