"""(hookshot-rog-ally, issue 4) RX_VK_FALLBACK_BATCH: a run of mesh fallback draws held and recorded together, sharing
fallback_record's full barriers. Checks the source keeps what the batch relies on (off by default; every way in to the
command buffer records the held draws first; the batch's barriers full ones, none narrower), and compiles fb_config and
fb_header from gpu/vk/vk_draw.cpp to check the held draws' ranges of the records buffer (tests/fallback_batch_layout_test.cpp)."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

RUN_ALL_ARGS = ["--cxx", "{cxx}"]

ROOT = Path(__file__).resolve().parents[1]
DRAW = ROOT / "gpu" / "vk" / "vk_draw.cpp"

# (RX_VK_FALLBACK_BATCH, RX_VK_FALLBACK_BATCH_MB) -> (draws held, compact)
CONFIGS = [
    ((None, None), (0, 0)),
    (("1", None), (0, 0)),
    (("4", None), (4, 0)),
    (("2", "64"), (2, 0)),
    (("3", "21"), (3, 1)),
    (("4", "15"), (4, 1)),
    (("8", "7"), (8, 1)),
    (("8", "16"), (8, 0)),     # (8 x 16 MB do not fit below 64 MB: the full areas)
    (("32", "1"), (32, 1)),
    (("100", None), (32, 0)),  # (at most 32)
]


def block(source, signature, semicolon=False):
    start = source.index(signature)
    first = source.index("{", start)
    depth = 1
    at = first + 1
    while depth:
        if source[at] == "{":
            depth += 1
        elif source[at] == "}":
            depth -= 1
        at += 1
    if semicolon:
        assert source[at] == ";"
        at += 1
    return source[start:at]


def check_source(draw):
    config = block(draw, "const FbConfig& fb_config() {")
    if 'getenv("RX_VK_FALLBACK_BATCH")' not in config or "if (n < 2) return c;" not in config:
        raise SystemExit("RX_VK_FALLBACK_BATCH is not off by default")
    if "!par_active.load(std::memory_order_relaxed)" not in block(draw, "bool fb_on() {"):
        raise SystemExit("the batch is not off in a parallel replay")
    # (every way in to the command buffer records the held draws first: a pass begun or ended (every command that is not a
    # draw does one first), a clear's check of the open pass, another draw, the submit)
    first = "if (fb_held && !fb_recording) fb_record_held();"
    for sig in ("void begin_pass(VkCommandBuffer cmd, const Targets& at) {", "void end_pass(VkCommandBuffer cmd) {",
                "void clear_after_draws(VkCommandBuffer cmd) {"):
        body = block(draw, sig)
        if first not in body.split("\n", 2)[1]:
            raise SystemExit("%s does not record the held fallback draws first" % sig.split("(")[0])
    if "fb_record_held();" not in block(draw, "void draw_flush_recording(int slot) {"):
        raise SystemExit("a submit does not record the held fallback draws")
    body = block(draw, "void draw(VkCommandBuffer cmd, NvnState& s, const DrawArgs& d) {")
    if "if (fb_held) fb_record_held();   // (anything else: the held draws first)" not in body:
        raise SystemExit("a draw that is not held does not record the held draws first")
    if body.index("if (fb_held) fb_record_held();") > body.index("writes = draw_hazards(cmd, p, s, at);"):
        raise SystemExit("a draw checks its pass's hazards before the held draws are recorded")
    if "mesh_indirect_convert(cmd, d);" not in body or "mesh_indirect_record(cmd, mesh_conv);" not in body:
        raise SystemExit("an indirect mesh draw that is not held is not converted")
    for guard in ("!mask_guard.cmd", "!each_guard.cmd", "!dump_on()", "!stats_frame_now()", "!barrier_every"):
        if guard not in body:
            raise SystemExit("a fallback draw is held while %s says it must be recorded at once" % guard)
    # (the batch's barriers: full ones, as fallback_record's; none narrower (NotRexed/Hookshot#1636 broke RDNA1's picture))
    record = block(draw, "void fb_record_held() {")
    if "VkMemoryBarrier2" in record or "vkCmdPipelineBarrier2" in record:
        raise SystemExit("the fallback batch records a barrier that is not a full one")
    if record.count("full_barrier(cmd") < 5:
        raise SystemExit("the fallback batch lost one of its full barriers")
    order = [record.index(x) for x in ("end_pass(cmd);", "vkCmdUpdateBuffer(cmd, b.records", "vkCmdCopyBuffer(cmd, items[k].mc",
                                        "send(items[k], k, false)", "send(items[k], k, true)", "vkCmdDrawIndirect(cmd, b.records")]
    if order != sorted(order):
        raise SystemExit("the fallback batch's steps are out of order (headers, conversions, tasks, meshes, draws)")
    if "fallback_record(cmd, p, d)" not in body or "vkCmdDrawIndirect(cmd, fallback_draw_records, 0, 1, sizeof(VkDrawIndirectCommand));" not in body:
        raise SystemExit("the fallback without the batch is gone")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cxx", default=os.environ.get("CXX", "clang++"), help="GCC/Clang C++ compiler")
    parser.add_argument("--source", type=Path, default=DRAW, help="a vk_draw.cpp to check instead (a negative control)")
    args = parser.parse_args()
    draw = args.source.read_text(encoding="utf-8")
    check_source(draw)
    cxx = shutil.which(args.cxx)
    if not cxx:
        raise SystemExit("C++ compiler not found: " + args.cxx)
    actual = "\n\n".join((block(draw, "struct FbConfig {", True), block(draw, "const FbConfig& fb_config() {"),
                          next(line for line in draw.splitlines() if line.startswith("struct FbHeader {")),
                          block(draw, "FbHeader fb_header(const Program& p, int k) {")))
    flags = subprocess.CREATE_NO_WINDOW | subprocess.BELOW_NORMAL_PRIORITY_CLASS if os.name == "nt" else 0
    env = dict(os.environ)
    env["PATH"] = str(Path(cxx).parent) + os.pathsep + env.get("PATH", "")
    failed = 0
    with tempfile.TemporaryDirectory(prefix="hookshot-fallback-batch-") as folder:
        tmp = Path(folder)
        (tmp / "fallback_batch_actual.inc").write_text(actual + "\n", encoding="utf-8")
        exe = tmp / ("layout.exe" if os.name == "nt" else "layout")
        command = [cxx, "-std=c++20", "-O1", "-Wall", "-Wextra", "-Werror", "-Wno-unused-function", "-I" + str(tmp),
                   str(ROOT / "tests" / "fallback_batch_layout_test.cpp"), "-o", str(exe)]
        result = subprocess.run(command, cwd=tmp, env=env, capture_output=True, text=True, timeout=120, creationflags=flags)
        if result.returncode:
            print(result.stdout + result.stderr)
            return result.returncode
        for (draws, mb), (want, compact) in CONFIGS:
            run_env = dict(env)
            for name, value in (("RX_VK_FALLBACK_BATCH", draws), ("RX_VK_FALLBACK_BATCH_MB", mb)):
                run_env.pop(name, None)
                if value is not None:
                    run_env[name] = value
            result = subprocess.run([str(exe), str(want), str(compact)], cwd=tmp, env=run_env, capture_output=True, text=True,
                                    timeout=60, creationflags=flags)
            print("RX_VK_FALLBACK_BATCH=%s RX_VK_FALLBACK_BATCH_MB=%s: %s" % (draws, mb, (result.stdout + result.stderr).strip()))
            failed += result.returncode != 0
    print("fallback batch: source checks ok; %d layouts, %d failed" % (len(CONFIGS), failed))
    return int(failed != 0)


if __name__ == "__main__":
    raise SystemExit(main())
