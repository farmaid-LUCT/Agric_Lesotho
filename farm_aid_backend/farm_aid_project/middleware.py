import logging
from django.http import JsonResponse

logger = logging.getLogger('django.request')

# Patterns that identify a local / trusted dev origin
_DEV_ORIGINS = ('localhost', '127.0.0.1')
# Production origins that must also always get CORS headers
_PROD_ORIGINS = ('onrender.com',)
_ALLOWED_PATTERNS = _DEV_ORIGINS + _PROD_ORIGINS


class CorsExceptionMiddleware:
    """
    Placed ABOVE CorsMiddleware so it wraps the entire chain.

    Problem: django-cors-headers 4.x is a plain callable wrapper:
        response = self.get_response(request)          # raises on 500
        return self.add_response_headers(...)          # never reached

    When an unhandled exception bubbles up through the chain, CORS headers
    are never added, so the browser reports a CORS error instead of the real
    500 — making debugging very hard.

    This middleware catches that exception, converts it to a JSON 500 response,
    logs it the same way Django would, and then ensures CORS headers are present
    on ALL responses (success or error).
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        origin = request.META.get('HTTP_ORIGIN', '')

        try:
            response = self.get_response(request)
        except Exception:
            logger.exception(
                'Internal Server Error: %s', request.path,
                extra={'status_code': 500, 'request': request},
            )
            response = JsonResponse({'error': 'Internal server error'}, status=500)

        # Ensure CORS headers are present if origin is recognised
        if origin and any(p in origin for p in _ALLOWED_PATTERNS):
            if 'Access-Control-Allow-Origin' not in response:
                response['Access-Control-Allow-Origin'] = origin
            if 'Access-Control-Allow-Credentials' not in response:
                response['Access-Control-Allow-Credentials'] = 'true'

        return response
