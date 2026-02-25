# Copyright 2026 jalcim
# SPDX-License-Identifier: Apache-2.0
"""
LibreLane plugin -- HardMacro flow.

Builds N hard macros via LibreLane sub-runs, collects their artifacts
(GDS, LEF, LIB, blackbox Verilog) into ip/<macro>/, then runs the
Classic top-level PnR flow.

Discovery: LibreLane auto-imports packages named ``librelane_plugin_*``
via ``pkgutil.iter_modules()`` -- no modification to LibreLane needed.
"""

import os
import re
import glob
import shutil
from typing import ClassVar, Dict, List, Tuple

import yaml

from librelane.common import Path
from librelane.config import Variable
from librelane.flows.flow import Flow
from librelane.flows.sequential import SequentialFlow
from librelane.flows.classic import Classic
from librelane.logging import info, verbose
from librelane.state import State
from librelane.steps.step import Step, StepError, ViewsUpdate, MetricsUpdate


@Step.factory.register()
class BuildMacros(Step):
    """Build hard macros via LibreLane sub-runs before the top-level PnR."""

    id = "HardMacro.BuildMacros"
    name = "Build Hard Macros"
    long_name = "Build Hard Macros via LibreLane Sub-runs"

    inputs: ClassVar[List] = []
    outputs: ClassVar[List] = []

    config_vars: ClassVar[List[Variable]] = [
        Variable(
            "HARD_MACRO_CONFIGS",
            Dict[str, Path],
            "Mapping {macro_name: config_path} for each hard macro to build."
            " Use dir:: prefix for paths relative to the config file.",
            default={},
        ),
    ]

    def run(
        self, state_in: State, **kwargs
    ) -> Tuple[ViewsUpdate, MetricsUpdate]:
        macro_configs: Dict[str, str] = self.config["HARD_MACRO_CONFIGS"]

        if not macro_configs:
            self.warn("HARD_MACRO_CONFIGS is empty -- no macros to build")
            return {}, {}

        for macro_name, config_path in macro_configs.items():
            self._build_macro(macro_name, str(config_path))

        return {}, {}

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _build_macro(self, macro_name: str, config_path: str) -> None:
        """Build one hard macro and collect its artifacts."""
        config_path = self._resolve_path(config_path)
        if not os.path.isfile(config_path):
            raise StepError(
                f"Macro config not found: {config_path}"
            )

        info(f"[HardMacro] Building macro '{macro_name}' -- {config_path}")

        # --- Run librelane sub-process ---
        # --run-tag ensures the sub-run gets its own directory
        # (prevents reusing the parent's RUN_* directory)
        run_tag = f"MACRO_{macro_name}"
        log_file = os.path.join(self.step_dir, f"{macro_name}.log")
        self.run_subprocess(
            [
                "librelane",
                "--run-tag", run_tag,
                "--overwrite",
                config_path,
            ],
            log_to=log_file,
        )

        # --- Parse macro config for DESIGN_NAME ---
        with open(config_path, "r") as fh:
            macro_cfg = yaml.safe_load(fh)
        design_name = macro_cfg.get("DESIGN_NAME", macro_name)

        # --- Locate the macro's run directory ---
        config_dir = os.path.dirname(config_path)
        runs_dir = os.path.join(config_dir, "runs")
        last_run = os.path.join(runs_dir, run_tag)
        if not os.path.isdir(last_run):
            raise StepError(f"Run directory not found: {last_run}")
        info(f"[HardMacro] Using run: {os.path.basename(last_run)}")

        # --- Copy artifacts to ip/<macro_name>/ ---
        project_root = os.path.dirname(config_dir)
        ip_dir = os.path.join(project_root, "ip", macro_name)
        os.makedirs(ip_dir, exist_ok=True)

        self._copy_gds(last_run, design_name, ip_dir)
        self._copy_lef(last_run, design_name, ip_dir)
        self._copy_libs(last_run, design_name, ip_dir)
        self._generate_blackbox(macro_cfg, config_dir, design_name, ip_dir)

        info(f"[HardMacro] Macro '{macro_name}' artifacts in {ip_dir}")

    def _resolve_path(self, path: str) -> str:
        """Resolve dir:: prefix if the config system didn't already."""
        if path.startswith("dir::"):
            # Shouldn't happen (config system resolves dir::), but handle it
            design_dir = os.path.dirname(
                str(self.config.get("meta", {}).get("config_file", ""))
            )
            path = os.path.normpath(os.path.join(design_dir, path[5:]))
        return os.path.normpath(path)

    def _copy_gds(
        self, last_run: str, design_name: str, ip_dir: str
    ) -> None:
        src = os.path.join(last_run, "final", "gds", f"{design_name}.gds")
        if not os.path.isfile(src):
            raise StepError(f"GDS not found: {src}")
        shutil.copy2(src, ip_dir)
        verbose(f"  GDS: {os.path.basename(src)}")

    def _copy_lef(
        self, last_run: str, design_name: str, ip_dir: str
    ) -> None:
        src = os.path.join(last_run, "final", "lef", f"{design_name}.lef")
        if not os.path.isfile(src):
            raise StepError(f"LEF not found: {src}")
        shutil.copy2(src, ip_dir)
        verbose(f"  LEF: {os.path.basename(src)}")

    def _copy_libs(
        self, last_run: str, design_name: str, ip_dir: str
    ) -> None:
        lib_base = os.path.join(last_run, "final", "lib")
        lib_count = 0
        for corner_dir in sorted(glob.glob(os.path.join(lib_base, "*"))):
            if not os.path.isdir(corner_dir):
                continue
            for lib_file in glob.glob(
                os.path.join(corner_dir, f"{design_name}__*.lib")
            ):
                shutil.copy2(lib_file, ip_dir)
                verbose(f"  LIB: {os.path.basename(lib_file)}")
                lib_count += 1
        if lib_count == 0:
            self.warn(f"No .lib files found in {lib_base}/*/")

    def _generate_blackbox(
        self,
        macro_cfg: dict,
        config_dir: str,
        design_name: str,
        ip_dir: str,
    ) -> None:
        """Generate blackbox Verilog from the original source."""
        verilog_files = macro_cfg.get("VERILOG_FILES", [])
        if not verilog_files:
            self.warn("No VERILOG_FILES -- skipping blackbox generation")
            return

        # Find the source file containing the module
        src_path = None
        for vf in verilog_files:
            vf = str(vf)
            if vf.startswith("dir::"):
                vf = os.path.join(config_dir, vf[5:])
            elif not os.path.isabs(vf):
                vf = os.path.join(config_dir, vf)
            vf = os.path.normpath(vf)
            if os.path.isfile(vf):
                src_path = vf
                break

        if src_path is None:
            self.warn("Source Verilog not found -- skipping blackbox")
            return

        with open(src_path, "r") as fh:
            source = fh.read()

        # Extract: module <name> ( ... );
        pattern = re.compile(
            rf"module\s+{re.escape(design_name)}\s*\(.*?\)\s*;",
            re.DOTALL,
        )
        match = pattern.search(source)
        if not match:
            self.warn(f"Module '{design_name}' not found in {src_path}")
            return

        bb_path = os.path.join(ip_dir, f"{design_name}.bb.v")
        with open(bb_path, "w") as fh:
            fh.write(
                f"/*\n"
                f" * Boite noire -- hard macro {design_name}\n"
                f" * Genere par librelane_plugin_hardmacro\n"
                f" */\n\n"
                f"(* blackbox *)\n"
                f"{match.group(0)}\n"
                f"endmodule\n"
            )
        verbose(f"  Blackbox: {design_name}.bb.v")


@Flow.factory.register()
class HardMacroClassic(SequentialFlow):
    """
    Classic flow preceded by hard macro builds.

    Runs ``HardMacro.BuildMacros`` first (which builds each macro listed
    in ``HARD_MACRO_CONFIGS`` via a LibreLane sub-run and collects the
    artifacts), then executes the full Classic flow for the top-level.
    """

    Steps = [BuildMacros] + list(Classic.Steps)
    config_vars = list(Classic.config_vars)
    gating_config_vars = dict(Classic.gating_config_vars)
