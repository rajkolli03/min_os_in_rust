arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso
target ?= $(arch)-min_os_rust
rust_os := target/$(target)/debug/libmin_os_rust.a
linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
    build/arch/$(arch)/%.o, $(assembly_source_files))

.PHONY: all clean run iso cargo

all: $(kernel)

clean:
	@cargo clean
	@rm -r build

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso)

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): cargo $(rust_os) $(assembly_object_files) $(linker_script)
	@x86_64-pc-elf-ld -n --gc-sections -T $(linker_script) -o $(kernel) $(assembly_object_files) $(rust_os)

# compile assembly files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@

cargo:
	@RUST_TARGET_PATH="$(shell pwd)" xargo build --target $(target)

kernel:
	@xargo build --target $(target)

