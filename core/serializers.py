from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from rest_framework import serializers
from rest_framework.authtoken.models import Token

from .models import ClientProfile


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150)
    phone = serializers.RegexField(regex=r'^\d{10}$')
    password = serializers.CharField(min_length=6, write_only=True)

    def validate_phone(self, value):
        if ClientProfile.objects.filter(phone=value).exists():
            raise serializers.ValidationError('Ce numero existe deja.')
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['phone'],
            first_name=validated_data['name'],
            password=validated_data['password'],
        )
        profile = ClientProfile.objects.create(
            user=user,
            phone=validated_data['phone'],
            business_name=validated_data['name'],
            is_validated=False,
        )
        token, _ = Token.objects.get_or_create(user=user)
        return user, profile, token


class LoginSerializer(serializers.Serializer):
    phone = serializers.RegexField(regex=r'^\d{10}$')
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(username=attrs['phone'], password=attrs['password'])
        if not user:
            raise serializers.ValidationError('Identifiants invalides.')
        try:
            profile = user.client_profile
        except ClientProfile.DoesNotExist as exc:
            raise serializers.ValidationError('Profil client introuvable.') from exc
        token, _ = Token.objects.get_or_create(user=user)
        attrs['user'] = user
        attrs['profile'] = profile
        attrs['token'] = token
        return attrs
