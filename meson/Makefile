OUT ?= $(CURDIR)/meson_builddir
SRC ?= $(CURDIR)

$(OUT)/foo: $(OUT)/build.ninja .FORCE
	ninja -C $(OUT)

$(OUT)/build.ninja:
	mkdir -p $(OUT)
	cd $(OUT)/.. 
	meson setup $(OUT) $(SRC)

.FORCE:
