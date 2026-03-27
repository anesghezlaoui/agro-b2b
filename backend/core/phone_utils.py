"""Normalisation téléphone client (app mobile / web)."""

import re

from rest_framework import serializers


def normalize_client_phone(value) -> str:
    """
    Retourne 10 chiffres au format local (ex. 0555123456).
    Accepte espaces, tirets, +213, 00213.
    """

    if value is None:
        raise serializers.ValidationError("Numéro requis.")

    raw = str(value).strip()
    digits = re.sub(r"\D", "", raw)

    if len(digits) == 10:
        return digits

    if len(digits) == 12 and digits.startswith("213"):
        rest = digits[3:]
        if len(rest) == 9:
            return "0" + rest

    if len(digits) == 13 and digits.startswith("0213"):
        rest = digits[4:]
        if len(rest) == 9:
            return "0" + rest

    if len(digits) == 9:
        return "0" + digits

    raise serializers.ValidationError(
        "Numéro invalide : 10 chiffres (ex. 0555123456) ou format international +213…"
    )

