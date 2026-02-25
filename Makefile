# Flow hard macro → top-level TT (via plugin HardMacroClassic)
# Usage :
#   make          — build complet (macros + top, une seule commande)
#   make macro    — build macro seule (flow classique)
#   make top      — build top seul (flow classique, necessite macro)
#   make unified  — build via plugin HardMacroClassic
#   make clean    — supprime les runs

# Plugin discovery : PYTHONPATH inclut la racine du projet
# pour que pkgutil.iter_modules() trouve librelane_plugin_hardmacro/
PYTHONPATH := $(CURDIR):$(PYTHONPATH)
export PYTHONPATH

IP_DIR       := ip/adder_4b
MACRO_CFG    := librelane/config.yaml
TOP_CFG      := librelane/config_top.yaml
UNIFIED_CFG  := librelane/config_unified.yaml
RUN_DIR      := librelane/runs

# Sources
MACRO_SRC    := src/adder_4b.v src/adder_4b.sdc
TOP_SRC      := src/project.v $(IP_DIR)/adder_4b.bb.v

# Artefacts macro
MACRO_GDS    := $(IP_DIR)/adder_4b.gds
MACRO_LEF    := $(IP_DIR)/adder_4b.lef
MACRO_LIBS   := $(IP_DIR)/adder_4b__nom_typ_1p20V_25C.lib \
                $(IP_DIR)/adder_4b__nom_fast_1p32V_m40C.lib \
                $(IP_DIR)/adder_4b__nom_slow_1p08V_125C.lib
MACRO_ARTS   := $(MACRO_GDS) $(MACRO_LEF) $(MACRO_LIBS)

# Stamp files pour tracker les runs
MACRO_STAMP  := $(RUN_DIR)/.macro.done
TOP_STAMP    := $(RUN_DIR)/.top.done

.PHONY: all macro top unified clean

all: unified

# === Mode unifie (plugin HardMacroClassic) ===
unified:
	librelane $(UNIFIED_CFG)

# === Mode classique (deux etapes separees) ===
macro: $(MACRO_STAMP)

$(MACRO_STAMP): $(MACRO_SRC) $(MACRO_CFG)
	@echo "=== PnR hard macro adder_4b ==="
	librelane $(MACRO_CFG)
	$(eval LAST_RUN := $(shell ls -td $(RUN_DIR)/RUN_* | head -1))
	@mkdir -p $(IP_DIR)
	cp $(LAST_RUN)/final/gds/adder_4b.gds $(IP_DIR)/
	cp $(LAST_RUN)/final/lef/adder_4b.lef $(IP_DIR)/
	@for lib in $(LAST_RUN)/final/lib/*/adder_4b__*.lib; do \
		cp "$$lib" $(IP_DIR)/; \
	done
	@echo "=== Artefacts macro ==="
	@ls -lh $(IP_DIR)/*.gds $(IP_DIR)/*.lef $(IP_DIR)/*.lib
	@touch $@

top: $(TOP_STAMP)

$(TOP_STAMP): $(TOP_SRC) $(MACRO_ARTS) $(TOP_CFG) $(MACRO_STAMP)
	@echo "=== PnR top-level TT ==="
	librelane $(TOP_CFG)
	@touch $@

clean:
	rm -rf $(RUN_DIR)/RUN_*
	rm -f $(RUN_DIR)/.*.done
