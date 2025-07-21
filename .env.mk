# /* vim: set ft=make noet : */
# Raspbian image URL & filename (derived from everything after last '/')
IMG_URL := https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64-lite.img.xz
#IMG_URL := https://downloads.raspberrypi.org/raspios_full_arm64/images/raspios_full_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64-full.img.xz
IMG := $(subst .xz,,$(notdir $(IMG_URL)))

# Default insecure pi user password: raspberrypiqemu
# Format: user:passwd-hash
# Escape any '$' chars as '$$'
USER_PASSWD := pi:$$y$$j9T$$2MdMxvUK1HOxHNKulVFf51$$GOVSJ4TrUwW5kyu.F7rxFbkDK23UbxUkysSsSW9jK08

