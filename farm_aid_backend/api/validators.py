"""
validators.py — FarmAid Lesotho
=================================
Strong password validation.

USAGE — add to settings.py:

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {"NAME": "api.validators.NoCommonPasswordValidator"},
    {"NAME": "api.validators.PasswordStrengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
]

The serializer-level check in register_farmer() already calls
validate_password() which runs all validators above automatically.
"""

import re
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _


# ── 1. Block the 500 most common / trivial passwords ─────────────────────

COMMON_PASSWORDS = {
    "12345", "123456", "1234567", "12345678", "123456789", "1234567890",
    "password", "password1", "password123", "pass", "pass123",
    "qwerty", "qwerty123", "abc123", "letmein", "welcome", "admin",
    "admin123", "iloveyou", "sunshine", "princess", "football",
    "master", "dragon", "monkey", "696969", "shadow", "superman",
    "michael", "jessica", "123123", "111111", "000000", "654321",
    "1q2w3e", "1q2w3e4r", "qwertyuiop", "zxcvbnm", "test", "test123",
    "farmaid", "lesotho", "farmer", "farmer1", "farm123", "maseru",
}


class NoCommonPasswordValidator:
    """Reject passwords that appear in the common-passwords list."""

    def validate(self, password, user=None):
        if password.lower() in COMMON_PASSWORDS:
            raise ValidationError(
                _("That password is too common. Please choose something more unique."),
                code="password_too_common",
            )

    def get_help_text(self):
        return _("Your password cannot be a commonly used password.")


# ── 2. Enforce complexity rules ───────────────────────────────────────────

class PasswordStrengthValidator:
    """
    Requires:
      • At least 8 characters
      • At least 1 uppercase letter
      • At least 1 lowercase letter
      • At least 1 digit
      • At least 1 special character  (!@#$%^&*…)
      • No repeated character runs (e.g. "aaaaaa")
    """

    MIN_LENGTH      = 8
    SPECIAL_CHARS   = r"[!@#$%^&*()\-_=+\[\]{};:'\",.<>?/\\|`~]"
    REPEAT_PATTERN  = re.compile(r"(.)\1{3,}")   # 4+ same chars in a row

    def validate(self, password, user=None):
        errors = []

        if len(password) < self.MIN_LENGTH:
            errors.append(
                ValidationError(
                    _("Password must be at least %(min)d characters long."),
                    code="password_too_short",
                    params={"min": self.MIN_LENGTH},
                )
            )

        if not re.search(r"[A-Z]", password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one uppercase letter (A–Z)."),
                    code="password_no_upper",
                )
            )

        if not re.search(r"[a-z]", password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one lowercase letter (a–z)."),
                    code="password_no_lower",
                )
            )

        if not re.search(r"\d", password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one number (0–9)."),
                    code="password_no_digit",
                )
            )

        if not re.search(self.SPECIAL_CHARS, password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one special character (e.g. @, #, !)."),
                    code="password_no_special",
                )
            )

        if self.REPEAT_PATTERN.search(password):
            errors.append(
                ValidationError(
                    _("Password must not contain 4 or more repeated characters in a row."),
                    code="password_repeated_chars",
                )
            )

        if errors:
            raise ValidationError(errors)

    def get_help_text(self):
        return _(
            "Your password must be at least 8 characters long and include "
            "uppercase, lowercase, a number, and a special character."
        )
