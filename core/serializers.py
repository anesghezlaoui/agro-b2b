from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from rest_framework import serializers
from rest_framework.authtoken.models import Token

from .models import ClientProfile
from .phone_utils import normalize_client_phone


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150)
    phone = serializers.CharField(max_length=32)
    password = serializers.CharField(min_length=6, write_only=True)

    def validate_phone(self, value):
        phone = normalize_client_phone(value)
        if ClientProfile.objects.filter(phone=phone).exists():
            raise serializers.ValidationError("Ce numero existe deja.")
        return phone

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data["phone"],
            first_name=validated_data["name"],
            password=validated_data["password"],
        )
        profile = ClientProfile.objects.create(
            user=user,
            phone=validated_data["phone"],
            business_name=validated_data["name"],
            is_validated=False,
        )
        token, _ = Token.objects.get_or_create(user=user)
        return user, profile, token


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField(required=False, allow_blank=True)
    telephone = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        raw = (attrs.get("phone") or attrs.get("telephone") or "").strip()
        if not raw:
            raise serializers.ValidationError({"phone": "Numéro requis."})

        try:
            phone = normalize_client_phone(raw)
        except serializers.ValidationError as exc:
            raise serializers.ValidationError({"phone": exc.detail}) from exc

        attrs["phone"] = phone

        user = authenticate(username=phone, password=attrs["password"])
        if not user:
            raise serializers.ValidationError(
                {"non_field_errors": ["Identifiants invalides (téléphone ou mot de passe)."]}
            )

        try:
            profile = user.client_profile
        except ClientProfile.DoesNotExist as exc:
            raise serializers.ValidationError(
                {"non_field_errors": ["Profil client introuvable."]}
            ) from exc

        token, _ = Token.objects.get_or_create(user=user)

        attrs["user"] = user
        attrs["profile"] = profile
        attrs["token"] = token
        return attrs

