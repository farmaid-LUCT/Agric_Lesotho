"""
SPICY MARIANMT TRANSLATION SERVICE - RENDER FREE TIER OPTIMIZED 🔥
- Lazy model loading (loads on first request, not at startup)
- Memory-efficient inference with torch.no_grad()
- Automatic cache clearing after 10 translations
- CPU-only optimized for Render's 512MB-1GB RAM
"""

import hashlib
import logging
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from django.core.cache import cache
from django.conf import settings

logger = logging.getLogger(__name__)

# Model configuration
MODEL_NAME = "Hellenics-NLP/opus-mt-en-ss"  # Note: corrected from "Helsinki"
_tokenizer = None
_model = None
_model_lock = threading.Lock()
_translation_counter = 0
_COUNTER_LOCK = threading.Lock()


def _increment_counter():
    """Increment translation counter and return new value"""
    global _translation_counter
    with _COUNTER_LOCK:
        _translation_counter += 1
        # Clear cache every 10 translations to prevent memory bloat on free tier
        if _translation_counter >= 10:
            _translation_counter = 0
            cache.clear()
            logger.warning("🧹 Cleared translation cache to free memory")
        return _translation_counter


def _get_model():
    """
    Thread-safe lazy model loader - loads ONCE at first translation request
    This prevents memory being used at Django startup on Render free tier
    """
    global _tokenizer, _model
    
    if _model is not None:
        return _tokenizer, _model
    
    with _model_lock:
        if _model is None:
            try:
                logger.warning("🔥 Loading MarianMT model (lazy load for Render free tier)...")
                from transformers import MarianMTModel, MarianTokenizer
                import torch
                
                # Memory-efficient loading for free tier
                _tokenizer = MarianTokenizer.from_pretrained(MODEL_NAME)
                _model = MarianMTModel.from_pretrained(
                    MODEL_NAME,
                    low_cpu_mem_usage=True,  # Critical for free tier
                    torch_dtype=torch.float32,  # Use float32 for stability
                )
                
                # Force CPU (no GPU on free tier)
                _model = _model.cpu()
                
                # Enable evaluation mode for memory efficiency
                _model.eval()
                
                logger.warning("✅ MarianMT model loaded successfully on Render free tier!")
                
            except Exception as e:
                logger.error(f"❌ Failed to load MarianMT model: {e}")
                raise
    
    return _tokenizer, _model


def _get_cache_key(text: str) -> str:
    """Generate cache key with SHA256 for consistent hashing"""
    normalized = text.lower().strip()
    return f"marianmt_{hashlib.sha256(normalized.encode()).hexdigest()}"


def _store_in_permanent_cache(english_text: str, sesotho_text: str, field_type: str = 'general'):
    """Store in TranslationCache for continuous learning"""
    if not english_text or not sesotho_text:
        return
    
    try:
        from .models import TranslationCache
        
        obj, created = TranslationCache.objects.get_or_create(
            disease_name_en=english_text,
            defaults={
                'pesticide_st': sesotho_text if field_type == 'pesticide' else '',
                'dosage_st': sesotho_text if field_type == 'dosage' else '',
                'steps_st': sesotho_text if field_type == 'steps' else '',
            }
        )
        
        if not created:
            updated = False
            if field_type == 'pesticide' and not obj.pesticide_st:
                obj.pesticide_st = sesotho_text
                updated = True
            elif field_type == 'dosage' and not obj.dosage_st:
                obj.dosage_st = sesotho_text
                updated = True
            elif field_type == 'steps' and not obj.steps_st:
                obj.steps_st = sesotho_text
                updated = True
            elif field_type == 'general' and not obj.pesticide_st:
                obj.pesticide_st = sesotho_text
                updated = True
            
            if updated:
                obj.save(update_fields=['pesticide_st', 'dosage_st', 'steps_st'])
        
        logger.debug(f"💾 Stored in TranslationCache: {english_text[:50]}...")
        
    except Exception as e:
        logger.warning(f"Failed to store in TranslationCache: {e}")


def _check_permanent_cache(english_text: str, field_type: str = 'general') -> str:
    """Check TranslationCache for existing translation"""
    try:
        from .models import TranslationCache
        
        cache_entry = TranslationCache.objects.filter(
            disease_name_en__iexact=english_text
        ).only('pesticide_st', 'dosage_st', 'steps_st').first()
        
        if cache_entry:
            if field_type == 'pesticide' and cache_entry.pesticide_st:
                return cache_entry.pesticide_st
            elif field_type == 'dosage' and cache_entry.dosage_st:
                return cache_entry.dosage_st
            elif field_type == 'steps' and cache_entry.steps_st:
                return cache_entry.steps_st
            elif cache_entry.pesticide_st:
                return cache_entry.pesticide_st
        
        return None
    except Exception:
        return None


def translate_text(english_text: str, field_type: str = 'general', store_for_learning: bool = True) -> str:
    """
    SPICY TRANSLATION with memory-efficient caching for Render free tier
    """
    if not english_text or not english_text.strip():
        return english_text
    
    english_text = english_text.strip()
    
    # Truncate very long texts (over 500 chars)
    if len(english_text) > 500:
        english_text = english_text[:500]
        logger.warning(f"✂️ Truncated text to 500 chars for memory efficiency")
    
    cache_key = _get_cache_key(english_text)
    
    # 🔥 TIER 1: Redis/Django Cache
    cached = cache.get(cache_key)
    if cached:
        logger.debug(f"⚡ Cache HIT: {english_text[:40]}...")
        return cached
    
    # 🔥 TIER 2: PostgreSQL TranslationCache
    permanent_cached = _check_permanent_cache(english_text, field_type)
    if permanent_cached:
        logger.debug(f"📚 Permanent cache HIT: {english_text[:40]}...")
        cache.set(cache_key, permanent_cached, timeout=60*60*24*7)  # 7 days only for free tier
        return permanent_cached
    
    # 🔥 TIER 3: MarianMT
    try:
        tokenizer, model = _get_model()
        if model is None:
            return english_text
        
        logger.info(f"🤖 MarianMT translating: {english_text[:60]}...")
        
        # Tokenize with memory-efficient settings
        inputs = tokenizer(
            english_text, 
            return_tensors="pt", 
            truncation=True, 
            max_length=256,  # Reduced from 512 for memory efficiency
            padding=False,    # No padding for memory efficiency
        )
        
        # Generate translation with memory-efficient settings
        import torch
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=300,        # Limit output length
                num_beams=1,           # Greedy decoding (faster, less memory)
                do_sample=False,       # Deterministic output
            )
        
        translated = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Store in cache (short expiry for free tier)
        cache.set(cache_key, translated, timeout=60*60*24*7)  # 7 days
        
        # Store permanently for learning (optional - can skip for free tier)
        if store_for_learning:
            _store_in_permanent_cache(english_text, translated, field_type)
        
        # Increment counter and maybe clear cache
        _increment_counter()
        
        logger.info(f"✅ Translated: {english_text[:40]}... → {translated[:40]}...")
        return translated
        
    except Exception as e:
        logger.error(f"Translation failed: {e}")
        return english_text


def translate_batch(texts: list, field_type: str = 'general', max_workers: int = 2) -> list:
    """
    Batch translation with limited concurrency for free tier
    """
    if not texts:
        return []
    
    # Limit batch size for free tier
    if len(texts) > 5:
        texts = texts[:5]
        logger.warning(f"⚠️ Batch limited to 5 items for free tier memory")
    
    results = [None] * len(texts)
    
    def translate_index(idx, text):
        return idx, translate_text(text, field_type)
    
    # Lower max_workers for free tier
    with ThreadPoolExecutor(max_workers=min(max_workers, 2)) as executor:
        futures = {
            executor.submit(translate_index, i, text): i 
            for i, text in enumerate(texts) if text
        }
        
        for future in as_completed(futures):
            idx, result = future.result()
            results[idx] = result
    
    # Fill in missing results
    for i, text in enumerate(texts):
        if results[i] is None:
            results[i] = text
    
    logger.info(f"Batch translated {len([r for r in results if r])} texts")
    return results


def translate_treatment_batch(pesticide: str, dosage: str, steps: str) -> dict:
    """
    Translate treatment fields with memory efficiency
    """
    # Single-threaded for free tier (prevents memory spikes)
    return {
        'pesticide_st': translate_text(pesticide, 'pesticide'),
        'dosage_st': translate_text(dosage, 'dosage'),
        'steps_st': translate_text(steps, 'steps'),
    }


def get_cache_stats() -> dict:
    """Get cache statistics"""
    try:
        from .models import TranslationCache
        return {
            'translation_cache_entries': TranslationCache.objects.count(),
            'model_loaded': _model is not None,
            'model_name': MODEL_NAME,
            'free_tier_mode': True,
        }
    except Exception as e:
        return {'error': str(e)}


def clear_cache():
    """Manual cache clearing for memory management"""
    cache.clear()
    logger.warning("🧹 Cache manually cleared")
    return {'status': 'cache_cleared'}


def warmup_cache(common_phrases: list):
    """
    Optional: Preload cache with common phrases
    Call this only during low-traffic times on free tier
    """
    logger.warning(f"🔥 Warming up cache with {len(common_phrases)} phrases...")
    for i, phrase in enumerate(common_phrases):
        if i >= 3:  # Only warm up first 3 on free tier
            logger.warning("⚠️ Limited warmup to 3 phrases for free tier")
            break
        translate_text(phrase, store_for_learning=False)
    logger.warning("✅ Cache warmup complete!")
