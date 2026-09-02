# Baylibre audio
ifeq ($(TARGET_AUDIO_HAL),baylibre)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.audio.primary.device=7
endif

# AV
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.media.avsync=true
