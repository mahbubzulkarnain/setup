# Reload the terminal theme and the starship prompt from this repo. Run from the repo folder in Git Bash:
#   make theme      Windows Terminal color scheme (dotfile/terminal/theme.json). Open a new window afterwards.
#   make starship   starship prompt config (dotfile/starship/starship.toml). Takes effect in the next prompt.
#
# A temporary .bak copy is made first. On success it is deleted. On failure the .bak is put back and the
# failed result is kept as .failed, so you can see what went wrong.

THEME := dotfile/terminal/theme.json
FONT_SIZE ?= 9
WT_SETTINGS := $(shell cygpath -u "$$LOCALAPPDATA")/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json
STARSHIP_SRC ?= dotfile/starship/starship.toml
STARSHIP_DST := $$HOME/.config/starship.toml

.PHONY: theme starship
theme:
	@test -f "$(WT_SETTINGS)" || { echo "Windows Terminal settings not found. Open Windows Terminal once, then run make theme again."; exit 1; }
	cp "$(WT_SETTINGS)" "$(WT_SETTINGS).bak"
	@if ! mise exec -- node dotfile/bash/windows-terminal.js "$$(cygpath -w "$(WT_SETTINGS)")" "$$(cygpath -w "$(THEME)")" "$(FONT_SIZE)"; then cp "$(WT_SETTINGS)" "$(WT_SETTINGS).failed"; cp "$(WT_SETTINGS).bak" "$(WT_SETTINGS)"; rm -f "$(WT_SETTINGS).bak"; echo "theme failed. Previous settings restored; the failed result is in $(WT_SETTINGS).failed"; exit 1; fi
	@rm -f "$(WT_SETTINGS).bak"

starship:
	@mkdir -p "$$(dirname "$(STARSHIP_DST)")"
	@if [ -f "$(STARSHIP_DST)" ]; then cp "$(STARSHIP_DST)" "$(STARSHIP_DST).bak"; fi
	cp "$(STARSHIP_SRC)" "$(STARSHIP_DST)"
	@if STARSHIP_CONFIG="$(STARSHIP_DST)" starship prompt 2>&1 | grep -q "ERROR"; then cp "$(STARSHIP_DST)" "$(STARSHIP_DST).failed"; if [ -f "$(STARSHIP_DST).bak" ]; then cp "$(STARSHIP_DST).bak" "$(STARSHIP_DST)"; rm -f "$(STARSHIP_DST).bak"; fi; echo "starship config has an error. Previous config restored; the failed one is in $(STARSHIP_DST).failed"; exit 1; fi
	@rm -f "$(STARSHIP_DST).bak"
	@echo "starship config reloaded from $(STARSHIP_SRC)"
