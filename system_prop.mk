# Baylibre audio
ifeq ($(TARGET_AUDIO_HAL),baylibre)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.audio.primary.device=7
endif

# AV
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.media.avsync=true

# USB configfs
PRODUCT_PROPERTY_OVERRIDES += \
    vendor.sys.usb.udc=3550000.xudc \
    sys.usb.controller=3550000.xudc
