#!/usr/bin/env python
"""
Wrapper pour démarrer Django depuis le dossier `backend/`.

Le code Django réel se trouve au niveau racine du projet
(`../config`, `../core`, `../commerce`).
"""

import os
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Ajoute le dossier racine du projet à sys.path pour que `config.*`, `core.*`, etc. soient importables.
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

from django.core.management import execute_from_command_line  # noqa: E402


def main() -> None:
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()

